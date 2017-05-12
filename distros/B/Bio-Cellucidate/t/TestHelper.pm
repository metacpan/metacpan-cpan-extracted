use Test::More;
use strict;
use warnings;
use Data::Dumper;

require HTTP::Server::Simple;

BEGIN { unshift @INC, "../lib"; }


# -------------
package TestHelper;
use Data::Dumper;

our($PID, $PORT, $RECEIVED_METHOD);

sub setup {
    
    $PORT = 7657;
    $PID  = REST::Client::TestServer->new($PORT)->background();
    $Bio::Cellucidate::CONFIG = { host => "http://localhost:$PORT" };
}

sub teardown {
    kill 15, $PID;
    exit;
}

sub last_request {
  my $client = REST::Client->new( { host => "http://localhost:$PORT" } );
  eval $client->request('GET', "/test")->responseContent;
}


# -------------
package REST::Client::TestServer;

use base qw(HTTP::Server::Simple::CGI);
use File::Basename;
use Data::Dumper;

our ($LAST_METHOD, $LAST_PATH, $LAST_QUERY, @LAST_KEYWORDS);

sub handle_request {
    my ( $self, $cgi ) = @_;

    my $path = $cgi->path_info;
    my $fixture_filename = dirname(__FILE__) . "/fixtures$path";
    $fixture_filename =~ s/\/$//;
    $fixture_filename .= '.http';
    
    if ($path eq '/test') {
        my $info = { 
            method => $LAST_METHOD,
            path => $LAST_PATH,
            query => $LAST_QUERY,
            keywords => join "", @LAST_KEYWORDS
        };
        $Data::Dumper::Purity = 1;
        $Data::Dumper::Terse = 1;
        print "HTTP/1.1 200 OK\r\n";
        print "\n";
        print Dumper $info;
    } else {
        $LAST_METHOD = $ENV{'REQUEST_METHOD'};
        $LAST_PATH = $path;
        $LAST_QUERY = $cgi->Vars;
        if ($LAST_QUERY->{PUTDATA}) {
            $LAST_QUERY = $LAST_QUERY->{PUTDATA};
        } elsif ($LAST_QUERY->{'XForms:Model'}) {
            $LAST_QUERY = $LAST_QUERY->{'XForms:Model'};
        }
        @LAST_KEYWORDS = $cgi->keywords;
    }

    if ($ENV{'REQUEST_METHOD'} eq 'DELETE') {
        print "HTTP/1.1 200 OK\r\n";
    } elsif ($path ne '/test') {
        if (-e $fixture_filename) {
            open FH, $fixture_filename;
            print <FH>;
            close FH;
        } else {
            print "HTTP/1.1 500\r\n";
            die "Can't open $fixture_filename";
        }
    }
}


sub valid_http_method {
    my $self = shift;
    my $method = shift or return 0;
    return $method =~ /^(?:GET|POST|HEAD|PUT|DELETE|OPTIONS)$/;
}

1;
