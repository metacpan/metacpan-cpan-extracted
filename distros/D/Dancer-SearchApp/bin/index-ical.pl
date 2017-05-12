#!perl -w
use strict;
use AnyEvent;
use Search::Elasticsearch::Async;
use Promises qw[collect deferred];
#use Promises::RateLimiter;

# In the long run, this should become an ::Extractor
# instead of being a separate crawler

use Dancer::SearchApp::Defaults 'get_defaults';
use Getopt::Long;
use Cal::DAV;

use MIME::Base64;

use Data::Dumper;
use YAML 'LoadFile';

use Dancer::SearchApp::IndexSchema qw(create_mapping find_or_create_index %indices %analyzers );
use Dancer::SearchApp::Utils qw(await);

use JSON::MaybeXS;
my $true = JSON->true;
my $false = JSON->false;

GetOptions(
    'force|f' => \my $force_rebuild,
    'config|c:s' => \my $config_file,
);
$config_file ||= 'ical-import.yml';

my $config = get_defaults(
    env      => \%ENV,
    config   => LoadFile($config_file),
    names => [
        ['elastic_search/index' => 'elastic_search/index' => 'SEARCHAPP_ES_INDEX', 'dancer-searchapp'],
        ['elastic_search/nodes' => 'elastic_search/nodes' => 'SEARCHAPP_ES_NODES', 'localhost:9200'],
        ['calendars' => 'calendars' => undef, []],
    ],
);
my $index_name = $config->{elastic_search}->{index};
my $node = $config->{elastic_search}->{nodes};

my $e = Search::Elasticsearch::Async->new(
    nodes => [
        $node
    ],
    #plugins => ['Langdetect'],
);

%analyzers = (
    'de' => 'german',
    'en' => 'english',
    'no' => 'norwegian',
    'it' => 'italian',
    'lt' => 'lithuanian',
    'ro' => 'english', # I don't speak "romanian"
    'sk' => 'english', # I don't speak "serbo-croatian"
);

if( $force_rebuild ) {
    print "Dropping indices\n";
    my @list;
    await $e->indices->get({index => ['*']})->then(sub{
        @list = grep { /^\Q$index_name/ } sort keys %{ $_[0]};
    });

    await collect( map { my $n=$_; $e->indices->delete( index => $n )->then(sub{warn "$n dropped" }) } @list )->then(sub{
        warn "Index cleanup complete";
        %indices = ();
    });
};

print "Reading ES indices\n";
await $e->indices->get({index => ['*']})->then(sub{
    %indices = %{ $_[0]};
});

warn "Index: $_\n" for grep { /^\Q$index_name/ } keys %indices;

use vars qw(%indices);

print "Reading ES indices\n";
my $indices_done = AnyEvent->condvar;
$e->indices->get({index => ['*']})->then(sub{
    %indices = %{ $_[0]};
    $indices_done->send;
});
$indices_done->recv;

warn "Index: $_\n" for keys %indices;

sub in_exclude_list {
    my( $item, $list ) = @_;
    scalar grep { $item =~ /$_/ } @$list
};

sub get_messages_from_calendar {
    my( $calendar )= @_;
    # Add rate-limiting counter here, so we don't flood the IMAP server
    #     with reconnect attempts
    my $c = $calendar->cal;
    my $en  = $c->entries;
    return
        grep {
            $_->ical_entry_type =~ /^VEVENT$/
        }    
        @{ $en };
};

sub ical_property {
    join ' ', map{$_->value } @{$_[0]->property($_[1])||[]}
};

sub ical_to_msg {
    my( $event ) = @_;
    # Here we might want to use a template while importing?!
    my $body = ical_property($event,'description') . ical_property($event,'attendee');
    my $html_content = sprintf <<'HTML',ical_property($event,'dtstart'),ical_property($event,'dtend'),ical_property($event,'summary'),ical_property($event,'attendee'),ical_property($event,'url'),ical_property($event,'description');
    %s - %s<br>
    <b>%s</b><br>
    <i>%s</i><br>
    <a href="%s">Link</a>
    <p>%s</p>
    <br>
HTML
    return {
        summary => ical_property($event,'summary'),
        organizer => ical_property($event,'organizer'),
        body => $body,
        html_content => $html_content,
        uid => ical_property($event,'uid'),
        url => ical_property($event,'url'),
        # better open the event in the calendar app!
        # But iCal doesn't support that
    }
}

my @calendars = @{ $config->{calendars} || [] };
if( @ARGV ) {
    @calendars = map { +{ calendar => $_, name => $_, exclude => [], } } @ARGV;
};

for my $calendar_def (@calendars) {
    my @messages;
    my $calendar_file = $calendar_def->{calendar};
    print "Reading $calendar_def->{name}\n";
    
    # Also support network access here?!
    my $caldav = Cal::DAV->new(
        user => $calendar_def->{user} || 'none',
        pass => $calendar_def->{pass} || 'none',
        url  => "file://$calendar_file",
        calname => $calendar_def->{name},
    );
    if( $calendar_file !~ m!://! ) {
        my $res = $caldav->parse(
            filename => $calendar_file,
        );
        if(! $res or ! $caldav->cal) {
            # Yes, parse errors result in ->cal being a Class::ReturnValue
            # object that is false but has the ->error_message method
            die "Couldn't parse calendar '$calendar_file': "
                . $caldav->cal->error_message;
        };
    };
    
    push @messages, map {
        # This doesn't handle attachments yet :-/
        ical_to_msg($_)
    } get_messages_from_calendar( $caldav );

    my $done = AnyEvent->condvar;

    print sprintf "Importing %d items\n", 0+@messages;
    collect(
        map {
            my $msg = $_;
            my $body = $msg->{body};
            my $lang = 'en';
            find_or_create_index($e, $index_name,$lang, 'file')
            ->then( sub {
                my( $full_name ) = @_;
                
                # munge the title so we get magic completion for document titles:
                # This should be mostly done in an Elasticsearch filter+analyzer combo
                # Except for bands/song titles, which we want to manually munge
                my @parts = map {lc $_} (split /\s+/, $msg->{summary});
                $msg->{title_suggest} = {
                    input => \@parts,
                    #output => $msg->{summary},
                    # Maybe some payload to directly link to the document. Later
                };
                
                # https://www.elastic.co/guide/en/elasticsearch/guide/current/one-lang-docs.html
                #warn "Storing document";
                $e->index({
                        index   => $full_name,
                        type    => 'file', # or 'attachment' ?!
                        #id      => $msg->messageid,
                        id      => $msg->{uid},
                        # index bcc, cc, to, from
                        # content-type, ...
                        body    => { # "body" for non-bulk, "source" for bulk ...
                        #source    => {
                            url       => $msg->{url},
                            title     => $msg->{summary} . "($calendar_def->{name})",
                            title_suggest => $msg->{title_suggest}, # ugh
                            folder    => $calendar_def->{name},
                            from      => $msg->{organizer},
                            #to      => [ $msg->recipients ],
                            content => $msg->{html_content},
                            language => $lang,
                            #date    => $msg->date->strftime('%Y-%m-%d %H:%M:%S'),
                        }
                 });
               })->then(sub{ $|=1; print "."; }, sub {warn Dumper \@_});
       } @messages
    )->then(sub {
        print "$calendar_file done\n";
        $done->send;
    });
    
    $done->recv;
};
