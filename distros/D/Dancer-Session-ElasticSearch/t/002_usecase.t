use Test::More;

use strict;
use warnings;

use Dancer qw(:syntax :tests);
use Dancer::Session::ElasticSearch;
use ElasticSearch::TestServer;

BAIL_OUT 'Requires perl 5.10.0 or higher' if $] < 5.010;

our $es;

{
    unless ( $ENV{ES_HOME} ) {
        diag "Trying to guess the location of your ElasticSearch binary.\nYou can skip this by setting the ES_HOME environment variable.";
        my @suspects = qw( /opt/elasticsearch/
                           /etc/elasticsearch/
                           /usr/sbin/elasticsearch/
                           /usr/local/bin/elasticsearch/
                           /usr/share/elasticsearch/
                       );
        for my $path (@suspects) {
            diag "Is it in '$path'?";
            if ( -f "${path}bin/elasticsearch" ) {
                diag "Looks like it is!";
                $ENV{ES_HOME} = $path;
                last;
            }
        }
    }

    unless ( $ENV{ES_HOME} ) {
        plan skip_all => '$ENV{ES_HOME} not set - Need to know where your ElasticSearch binary is';
    }

    $ENV{ES_PORT}      ||= '9400';
    $ENV{ES_INSTANCES} ||= 1;
    $ENV{ES_IP}        ||= '127.0.0.1';
    eval { $es = ElasticSearch::TestServer->new(
                        ip        => $ENV{ES_IP},
                        home      => $ENV{ES_HOME},
                        port      => $ENV{ES_PORT},
                        instances => $ENV{ES_INSTANCES},
                 )
    };

    if ( $es ) {
        $es->use_index('session');
        $es->use_type('session');
        $Dancer::Session::ElasticSearch::es = $es;
    }
    else {
        BAIL_OUT 'No ElasticSearch test server available ' . $@;
    }
}

set 'session_options' => {
    signing => {
        secret => "lkjadslaj!ljasxmHasjaojsxm!!'",
        length => 12
    }
};

set 'session_fast' => 1;

# create a session
my $session = Dancer::Session::ElasticSearch->create;

isa_ok $session, "Dancer::Session::ElasticSearch";

my $id = $session->id;

# create a new session
$session->create;

$session->flush;

is $session->id, $id, "Session ID remains the same after flushing";

$session->retrieve($id);

is $session->id, $id, "Session ID remains the same after retrieval";

my $session2 = $session->retrieve("NOTASESSIONID");

isnt $session2, "Dancer::Session::ElasticSearch", "Retrieving with an invalid session ID errors";

$session->destroy;

done_testing();