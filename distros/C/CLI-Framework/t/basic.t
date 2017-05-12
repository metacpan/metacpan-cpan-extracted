use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use File::Spec;

use Test::More;
# These tests require DBI and DBD::SQLite (My::Journal dependencies)...
my $prereqs_installed = eval 'use DBI; use DBD::SQLite';
if( $@ ) { plan skip_all => 'DBI and DBD::SQLite are required for tests that use demo app My::Journal' }
else { plan 'no_plan' }
use_ok( 'My::Journal' );

#~~~~~~
# Send STDOUT, STDERR to null device...
close STDOUT;
open( STDOUT, '>', File::Spec->devnull() );
close STDERR;
open( STDERR, '>', File::Spec->devnull() );
#~~~~~~

@ARGV = qw( list );
ok( My::Journal->run(),
    'call run() directly on CLIF-derived application class (without first '.
    'constructing an object)' );

ok( my $app = My::Journal->new(), 'constructor' );

# These tests depend on 'help' being the default command...
$app->set_default_command( 'help' );

# Test series of command requests...
my $valid_command_requests = [
    # <command request>  [ =>  <command name implied by request> ]
    [ 'list'                                    => 'list' ],
    [ 'menu'                                    => 'menu' ],
    [ 'dump'                                    => 'dump' ],
    [ 'tree'                                    => 'tree' ],
    [ 'entry --date=20090530 list foo'          => 'entry' ],
    [ '--verbose entry'                         => 'entry' ],
    [ ''                                        => $app->get_default_command() ]
];
my $invalid_command_requests = [
    [ '--foo entry'                             => 'entry' ],
    [ 'entry --foo'                             => 'entry' ],
    [ 'bogus' ],
    [ 'bogus --x' ],
    [ '--x bogus' ],
    [ 'foo1 entry list foo2'                    => 'entry' ],
    [ 'foo1 entry --date=20090530 list foo2'    => 'entry' ],
    [ 'entry add one two' ],
];

test_command_requests( $valid_command_requests );
test_command_requests( $invalid_command_requests,   invalid => 1 );

#-------

sub test_command_requests {
    my ($requests, %param) = @_;

    my $invalid = $param{invalid};

    for my $command_request ( @$requests ) {
        my ($request_string, $command_name) = @$command_request;
        @ARGV = split / /, $request_string;
        my $rv;
        if( $invalid ) {
            # run() with invalid command in @ARGV (expect false return value)...
            eval{ $rv = $app->run( initialize => 1 ) };
            ok(! $rv, "invalid command '$request_string'" );
        }
        else {
            # run() with valid command in @ARGV (expect true return value)...
            eval { $rv = $app->run( initialize => 1 ) };
            ok( $rv, "valid command '$request_string'" );
        }
        # (only check the last-run command if the expected value was passed)
        if( defined $command_name ) {
            is( $app->get_current_command(), $command_name,
                "last-run command was '$command_name'" );
        }
    }
}

__END__

=pod

=head1 PURPOSE

To verify basic CLIF features.

=cut
