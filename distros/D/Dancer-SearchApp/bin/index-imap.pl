#!perl -w
use strict;
use AnyEvent;
use Search::Elasticsearch::Async;
use Promises qw[collect deferred];
#use Promises::RateLimiter;

use Dancer::SearchApp::Defaults 'get_defaults';
use Getopt::Long;
use Mail::IMAPClient;

# Consider using Email::Folder::*
# so that we can read things other than IMAP
# Also move away from App::ImapBlog :-)
use Mail::Email::IMAP;
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
$config_file ||= 'imap-import.yml';

my $config = get_defaults(
    env      => \%ENV,
    config   => LoadFile($config_file),
    names => [
        ['elastic_search/index' => 'elastic_search/index' => 'SEARCHAPP_ES_INDEX', 'dancer-searchapp'],
        ['elastic_search/nodes' => 'elastic_search/nodes' => 'SEARCHAPP_ES_NODES', 'localhost:9200'],
        ['imap/server'          => 'imap/server'          => IMAP_SERVER => 'localhost' ],
        ['imap/port'            => 'imap/port'            => IMAP_PORT => '993' ],
        ['imap/username'        => 'imap/username'        => IMAP_USER  => ],
        ['imap/password'        => 'imap/password'        => IMAP_PASSWORD => ],
        ['imap/debug'           => 'imap/debug'           => IMAP_DEBUG => ],
        ['imap/folders'         => 'imap/folders'         => undef => []],
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


# Erstellt einen Mail-Index mit der passenden Sprache
# https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-lang-analyzer.html

use vars qw(%indices);

print "Reading ES indices\n";
my $indices_done = AnyEvent->condvar;
$e->indices->get({index => ['*']})->then(sub{
    %indices = %{ $_[0]};
    $indices_done->send;
});
$indices_done->recv;

warn "Index: $_\n" for keys %indices;

# Connect to cluster at search1:9200, sniff all nodes and round-robin between them:

use vars qw($imap);
sub imap() {
    return $imap if $imap and $imap->IsConnected;
    
    my %imap_config = (
        Server => $config->{imap}->{server},
        Port => $config->{imap}->{port},
        User => $config->{imap}->{username},
        Password => $config->{imap}->{password},
        Debug => $config->{imap}->{debug},
    );
    
    use IO::Socket::SSL;
    #$IO::Socket::SSL::DEBUG = 3; # all
    my $socket = IO::Socket::SSL->new
      (  Proto    => 'tcp',
         PeerAddr => $imap_config{ Server },
         PeerPort => $imap_config{ Port },
         SSL_verify_mode => SSL_VERIFY_NONE, # Yes, I know ...
      ) or die "No socket to $imap_config{ Server }:$imap_config{ Port }";

CONNECT:
    my $retry = 0;
    $imap = Mail::IMAPClient->new(
        #%imap_config,
        User => $imap_config{ User },
        Password => $imap_config{ Password },
        Socket   =>  $socket,
        #Ssl      => 1,
        Uid      => 1,
    ) or die sprintf "Can't connect to server '%s': %s",
        $config->{'server'}, "$@";
        
    if( !$imap->IsConnected and $retry++ < 5 ) {
        sleep 1;
        warn "Retrying";
        goto CONNECT;
    };
    
    if( $retry == 5 ) {
        exit 1;
    };
    $imap
};

sub in_exclude_list {
    my( $item, $list ) = @_;
    scalar grep { $item =~ /$_/ } @$list
};

# This should go into crawler::imap
sub imap_recurse {
    my( $imap, $config ) = @_;
    
    my @folders;
    for my $folderspec (@{$config->{folders}}) {
        if( ! ref $folderspec ) {
            # plain name, use this folder
            push @folders, $folderspec
        } else {
            if( $folderspec->{recurse}) {
                # Recurse through this tree
                $folderspec = $folderspec->{recurse};
                warn "Recursing into '$folderspec->{prefix}'";
                $folderspec->{exclude} ||= [];
                my @imap_folders;
                if( $folderspec->{prefix} ne '' ) {
                    @imap_folders = imap->folders_hash( $folderspec->{prefix} );
                } else {
                    @imap_folders = imap->folders_hash();
                };
                @imap_folders = grep { ! in_exclude_list( $_->{name}, $folderspec->{exclude} ) }
                    @imap_folders;
                push @folders, map { $_->{name} } @imap_folders;
            };
        };
    };
    
    @folders
};

sub get_messages_from_folder {
    my( $folder, @message_uids )= @_;
    # Add rate-limiting counter here, so we don't flood the IMAP server
    #     with reconnect attempts
    my $ok = eval {
        imap->select( $folder )
            or die "Select '$folder' error: ", $imap->LastError, "\n";
        1;
    };
    if( ! $ok and $@ =~ /Write failed/) {
        # Try a reconnect
        undef $imap;
        imap->select( $folder )
            or die "Select '$folder' error: ", $imap->LastError, "\n";
    };

    if( ! @message_uids ) {
        # Read folder
        if( imap->has_capability('thread')) {
            @message_uids = imap->thread();
        } elsif( imap->has_capability('sort')) {
            @message_uids = imap->sort("REVERSE DATE", 'UTF-8', "ALL");
            if(! defined $message_uids[0]) {
                warn "Got an empty UID, don't know why?! " . imap->LastError;
            };
        } else {
            # read messages
            @message_uids = imap->messages();
        };
    };
    return @message_uids;
};

#use Search::Elasticsearch::Plugin::Langdetect;
#my $ld = Search::Elasticsearch::Plugin::Langdetect->new( elasticsearch => $e );

my @folders = imap_recurse(imap, $config->{imap});
#my $importer = $e->bulk_helper();
for my $folder (@folders) {
    my @messages;
    print "Reading $folder\n";
    push @messages, map {
        # This doesn't handle attachments yet :-/
        Mail::Email::IMAP->from_imap_client(imap(), $_,
            folder => $folder
        );
    } get_messages_from_folder( $folder );

    my $done = AnyEvent->condvar;

    #my $ld = $e->langdetect;
    # Importieren
    print sprintf "Importing %d messages\n", 0+@messages;
    collect(
        map {
            my $msg = $_;
            my $body = $msg->body;
            #my $lang = $ld->detect_languages( body => $body );
            #warn "Language promise";
            #$lang->then( sub {
            #    my $l = $_[0]->[0]->{language};
            #    warn "Language detected: $l";
            
            #}, sub { die "ERR:" . Dumper \@_; })
                my $lang = 'de';
                find_or_create_index($e, $index_name,$lang, 'mail')
            ->then( sub {
                my( $full_name ) = @_;
                
                # munge the title so we get magic completion for document titles:
                # This should be mostly done in an Elasticsearch filter+analyzer combo
                # Except for bands/song titles, which we want to manually munge
                my @parts = map {lc $_} (split /\s+/, $msg->subject);
                $msg->{title_suggest} = {
                    input => \@parts,
                    #output => $msg->subject,
                    # Maybe some payload to directly link to the document. Later
                };

                
                # https://www.elastic.co/guide/en/elasticsearch/guide/current/one-lang-docs.html
                #warn "Storing document";
                $e->index({
                        index   => $full_name,
                        type    => 'mail', # or 'attachment' ?!
                        #id      => $msg->messageid,
                        id      => $msg->uid,
                        # index bcc, cc, to, from
                        # content-type, ...
                        body    => { # "body" for non-bulk, "source" for bulk ...
                        #source    => {
                            url       => $msg->messageid,
                            title     => $msg->subject,
                            title_suggest => $msg->{title_suggest}, # ugh
                            folder    => $msg->{folder},
                            #from    => $msg->from,
                            #to      => [ $msg->recipients ],
                            content => "From: " . join( ",", $msg->from ) .  "<br/>\n To: " . join( ",", $msg->recipients ) . "<br/>\n" . $body,
                            language => $lang,
                            date    => $msg->date->strftime('%Y-%m-%d %H:%M:%S'),
                        }
                 });
               })->then(sub{ $|=1; print "."; }, sub {warn Dumper \@_});
       } @messages
    )->then(sub {
        print "$folder done\n";
        $done->send;
    });
    
    $done->recv;
    #$importer->flush;
};
#$importer->flush;
