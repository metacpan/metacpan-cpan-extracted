package t::lib::Prove::Plugin::StartArangoDB;
use strict;
use warnings;
use Test::More;
use Test::TCP;
use File::Temp;

our $ARANGODB;
our $TMP_DIR;

sub load {
    if ( my $arangodb_port = $ENV{TEST_ARANGODB_PORT} ) {
        diag 'TEST_ARANGODB_PORT explicitly set. Not starting ArangoDB.';
        return;
    }

    $TMP_DIR = File::Temp->newdir;

    eval {
        $ARANGODB = Test::TCP->new(
            code => sub {
                my $port = shift;
                diag "Starting arangod on 127.0.0.1:$port";
                my $dir = $TMP_DIR->dirname;
                exec "arangod --server.http-port $port $dir";
            }
        );

        $ENV{TEST_ARANGODB_PORT} = $ARANGODB->port;
    };
    if ($@) {
        diag $@;
    }
}

END {
    undef $ARANGODB;
    undef $TMP_DIR;
}

1;
__END__
