use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.051

use Test::More;

plan tests => 13 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

my @module_files = (
    'Business/eWAY/RapidAPI.pm',
    'Business/eWAY/RapidAPI/CardCustomer.pm',
    'Business/eWAY/RapidAPI/CardDetails.pm',
    'Business/eWAY/RapidAPI/CreateAccessCodeRequest.pm',
    'Business/eWAY/RapidAPI/Customer.pm',
    'Business/eWAY/RapidAPI/GetAccessCodeResultRequest.pm',
    'Business/eWAY/RapidAPI/Items.pm',
    'Business/eWAY/RapidAPI/Options.pm',
    'Business/eWAY/RapidAPI/Payment.pm',
    'Business/eWAY/RapidAPI/Role/ErrorCodeMap.pm',
    'Business/eWAY/RapidAPI/Role/Parser.pm',
    'Business/eWAY/RapidAPI/ShippingAddress.pm',
    'Business/eWAY/RapidAPI/TransactionRequest.pm'
);

# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files) {

    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3( $stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e',
        "require q[$lib]" );
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid( $pid, 0 );
    is( $?, 0, "$lib loaded ok" );

    if (@_warnings) {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}

is( scalar(@warnings), 0, 'no warnings found' )
  or diag 'got warnings: ',
  ( Test::More->can('explain')
    ? Test::More::explain( \@warnings )
    : join( "\n", '', @warnings ) )
  if $ENV{AUTHOR_TESTING};

