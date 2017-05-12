#!perl -w
use strict;
use AnyEvent;
use AnyEvent::HTTP;
use Search::Elasticsearch::Async;
use Promises backend => ['AE'], qw[collect deferred];
#use Promises::RateLimiter;

use Getopt::Long;

use MIME::Base64;
use Text::CleanFragment 'clean_fragment';
use HTML::TreeBuilder::XPath;

use Data::Dumper;
use YAML 'LoadFile';

use Path::Class;
use URI::file;
use URI::URL;
use POSIX 'strftime';

use Dancer::SearchApp::IndexSchema qw(create_mapping find_or_create_index %indices %analyzers );
use Dancer::SearchApp::Utils qw(await);

use lib 'C:/Users/Corion/Projekte/Apache-Tika-Async/lib';
use Apache::Tika::Server;

use JSON::MaybeXS;
my $true = JSON->true;
my $false = JSON->false;

=head1 USAGE

  # index a directory and its subdirectories
  index-url.pl url1 url2 ...

=cut

GetOptions(
    'force|f' => \my $force_rebuild,
    'config|c:s' => \my $config_file,
    'url-file|I:s' => \my $url_file,
);
#$config_file ||= 'url-import.yml';

my $config = {};
#my $config = LoadFile($config_file)->{fs};

my $index_name = 'dancer-searchapp';

my $e = Search::Elasticsearch::Async->new(
    nodes => [
        'localhost:9200',
        #'search2:9200'
    ],
    plugins => ['Langdetect'],
    #trace_to => 'Stderr',
);

my $tika_glob = 'jar/tika-server-*.jar';
my $tika_path = (sort { my $ad; $a =~ /server-1.(\d+)/ and $ad=$1;
                my $bd; $b =~ /server-1.(\d+)/ and $bd=$1;
                $bd <=> $ad
              } glob $tika_glob)[0];
die "Tika not found in '$tika_glob'" unless -f $tika_path; 
#warn "Using '$tika_path'";
my $tika= Apache::Tika::Server->new(
    jarfile => $tika_path,
);
$tika->launch;

my $ok = AnyEvent->condvar;
my $info = await $e->cat->plugins;

# Koennen wir ElasticSearch langdetect als Fallback nehmen?
my $have_langdetect = $info =~ /langdetect/i;
if( ! $have_langdetect ) {
    warn "Language detection disabled";
};

# https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-lang-analyzer.html

use vars qw(%analyzers);

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

# Connect to cluster at search1:9200, sniff all nodes and round-robin between them:

# Lame-ass config cascade
# Read from %ENV, $config, hard defaults, with different names,
# write to yet more different names
# Should merge with other config cascade
sub get_defaults {
    my( %options ) = @_;
    $options{ defaults } ||= {}; # premade defaults
    
    my @names = @{ $options{ names } };
    if( ! exists $options{ env }) {
        $options{ env } = \%ENV;
    };
    my $env = $options{ env };
    my $config = $options{ config };
    
    for my $entry (@{ $options{ names }}) {
        my ($result_name, $config_name, $env_name, $hard_default) = @$entry;
        if( defined $env_name and exists $env->{ $env_name } ) {
            #print "Using $env_name from environment\n";
            $options{ defaults }->{ $result_name } //= $env->{ $env_name };
        };
        if( defined $config_name and exists $config->{ $config_name } ) {
            #print "Using $config_name from config\n";
            $options{ defaults }->{ $result_name } //= $config->{ $config_name };
        };
        if( ! exists $options{ defaults }->{$result_name} ) {
            print "No $config_name from config, using hardcoded default\n";
            print "Using $env_name from hard defaults ($hard_default)\n";
            $options{ defaults }->{ $result_name } = $hard_default;
        };
    };
    $options{ defaults };
};

sub in_exclude_list {
    my( $item, $list ) = @_;
    scalar grep { $item =~ /$_/ } @$list
};

# This should go into crawler::imap
# make folders a parameter
# This needs far more work for HTTP: duplicate detection
# HTML is not a directed graph
sub http_recurse {
    my( $x, $config ) = @_;
};

sub get_entries_from_folder {
    my( $folder )= @_;
    # Add rate-limiting counter here, so we don't flood
    
    return $folder;
};

sub get_selector {
    my($tree,$sel) = @_;
    if( my @nodes = $tree->findnodes($sel)) {
        return $nodes[0]->text
    }
}

sub abs_url {
    my( $new, $base ) = @_;
    "" . URI::URL->new( $new, $base )->abs
}

sub get_document_info {
    my( $url, $html ) = @_;
    my %res;
    $res{ url } = $url;
    
    my $parsed = HTML::TreeBuilder::XPath->new_from_content($html);
    # First, extract the "real" content from the page using FTR
    # I left FTR at home, so I'll redo a low-spec version here
    my $title = get_selector($parsed,'title');
    
    # If the content type is not text/html use Tika to
    # extract the Real Content.
    #eval {
    #    $info = $tika->get_all( $html );
    #};
    
    if( $@ ) {
        # Einfach so indizieren
        $res{ title } = $title;
        $res{ author } = undef;
        $res{ language } = undef;
        $res{ content } = undef;
    } else {
    
        #my $meta = $info->meta;
        
        #$res{ mime_type } = $meta->{"Content-Type"};
        
        if( 0 and $res{ mime_type } =~ m!^audio/mpeg$! ) {
            require MP3::Tag;
            my $mp3 = MP3::Tag->new($url);
            my ($title, $track, $artist, $album, $comment, $year, $genre) = $mp3->autoinfo();
            $res{ title } = $title;
            $res{ author } = $artist;
            $res{ language } = 'en'; # ...
            $res{ content } = join "-", $artist, $album, $track, $comment, $genre;
            # We should also calculate the duration here, and some more information
            # to generate an "HTML" page for the file
            
        } else {
            
            # Just use what FTR found

            use HTML::Restricted;            
            my $p = HTML::Restricted->new(tree_class => 'HTML::TreeBuilder::XPath');
            my $r = $p->filter( $html );

            $res{ references } = [map { abs_url( $_->attr('href'), $url ) } $r->findnodes('//a[@href]')];
            $res{ title } = $title || $url;
            $res{ author } = "online"; # as HTML
            $res{ language } = ''; ## $meta->{"meta:language"};
            $res{ content } = $r->as_HTML; # as HTML
        }
    }
    
    #my $ctime = (stat $file)[10];
    #$res{ creation_date } = strftime('%Y-%m-%d %H:%M:%S', localtime($ctime));
    \%res
}

my $ld = $e->langdetect;
sub detect_language {
    my( $content, $meta ) = @_;
    my $res;
    $have_langdetect = 0;
    if($have_langdetect and ! $meta->{language}) {
        $res = $ld->detect_languages({ body => $content })
        ->then( sub {
            my $l = $_[0]->{languages}->[0]->{language};
            warn "Language detected: $l";
            return $l
        }, sub {
            my $default = $config->{default_language} || 'en';
            warn "Error while detecting language: $_[0], defaulting to '$default'";
            return $default
        });
    } else {
        $res = deferred;
        $res->resolve( $meta->{language} || $config->{default_language} || 'en');
        $res = $res->promise
    }
    $res
}

sub http_fetch {
    my ($uri) = @_;
    my $d = deferred;
    http_get $uri => sub {
        my ($body, $headers) = @_;
        print "[$headers->{Status}] $uri\n";
        $headers->{Status} == 200
            ? $d->resolve( $body )
            : $d->reject( $body )
    };
    $d->promise;
}

# Our store for URLs we've already added to be fetched
my %url_seen;

sub enqueue_url {
    my( $queue, @urls ) = @_;
    for my $url (@urls) {
        push @$queue, $url
            unless $url_seen{ $url }++;
    }
}

sub dequeue_url {
    my( $queue ) = @_;
    shift @$queue;
}

my @url_list;
if( $url_file ) {
    open my $fh, '<', $url_file
        or die "Couldn't read URLs from '$url_file'";
    @url_list = <$fh>;
    s!\s+$!! for @url_list;
} else {
    @url_list = @ARGV;
}

# Simply restrict to the one host:
sub should_follow {
    my( $url, $new ) = @_;
    URI->new( $new )->host eq URI->new( $url )->host
}

my $concurrent_http_requests = Promises::RateLimiter->new(
    maximum => 4,
    rate => 2, # 2/s
);

while( @url_list) {
    # How do we prevent more than 20 promises in flight?!
    if( @url_list ) {
        my $url = dequeue_url(\@url_list);

        my $p = deferred;
        $p->resolve($url);
        $p->promise->limit( $concurrent_http_requests )
          ->then(sub {
            my( $url ) = @_;
            http_fetch($url)
          })->then(sub {
            my( $content ) = @_;
            my $info = get_document_info($url,$content);
            
            # Extract and enqueue links if wanted
            # ...
            if( my $more = delete $info->{references}) {
            
                my @follow = grep {should_follow( $url, $_)} @{ $more };
            
                # We should check whether we are in the list of allowed hosts
                enqueue_url(\@url_list, @follow );
            };
            
            return $info
        })->then(sub {
            my $msg = $_[0];
            my $body = $msg->{content};
            
            my $lang = detect_language($body, $msg);
            
            $lang->then(sub{
                my $found_lang = $_[0]; #'en';
                return find_or_create_index($e, $index_name,$found_lang)
            })
            ->then( sub {
                my( $full_name ) = @_;
                #warn $msg->{mime_type};
                # https://www.elastic.co/guide/en/elasticsearch/guide/current/one-lang-docs.html
                #warn "Storing document into $full_name";
                $e->index({
                        index   => $full_name,
                        type    => 'http', # or 'attachment' ?!
                        id      => $msg->{url}, # we want to overwrite
                        # index bcc, cc, to, from
                        body    => $msg # "body" for non-bulk, "source" for bulk ...
                        #source    => $msg
                 });
               })->then(sub{
                   #warn "Done."
               }, sub {warn $_ for @_ });
        })->then(sub {
            print "$url done\n";
        })->catch(sub {
            print "$url: Error: @_"; 
        });
        #$importer->flush;
    };
};
#$importer->flush;
