#
#===============================================================================
#
#         FILE:  basic.t
#
#  DESCRIPTION:  Test of the most basic functionality
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      CREATED:  13/05/14 21:36:53
#
#  Updates:
#    21/08/2014 Now tests set_platform, wrap_textarea and get_error_message.
#    25/08/2014 Now tests get_multiple values.
#===============================================================================

use strict;
use warnings;

use Test::More tests => 322;

use lib './lib';

# Test exits and outputs;
my $have_test_trap;
our $trap; # Imported
BEGIN {
	eval {
		require Test::Trap;
		Test::Trap->import (qw/trap $trap :flow
		:stderr(systemsafe)
		:stdout(systemsafe)
		:warn/);
		$have_test_trap = 1;
	};
	use_ok ('CGI::Lite');
}

is ($CGI::Lite::VERSION, '3.02', 'Version test');
is (CGI::Lite::Version (), $CGI::Lite::VERSION, 'Version subroutine test');

my $cgi = CGI::Lite->new ();

is (ref $cgi, 'CGI::Lite', 'New');

is ($cgi->browser_escape ('<&>'), '&#60;&#38;&#62;', 'browser_escape');

{
	my @from = split (/ /, q/! " # $ % ^ & * ( ) _ + - =/);
	my @to   = qw/%21 %22 %23 %24 %25 %5E %26 %2A %28 %29 _ %2B - %3D/;

	for my $i (0..$#from) {
		is ($cgi->url_encode($from[$i]), $to[$i], "url_encode $from[$i]");
		is ($cgi->url_decode($to[$i]), $from[$i], "url_decode $to[$i]");
	}
}

my $dangerous = ';<>*|`&$!#()[]{}:\'"';

for my $i(0..255) {
	my $chr = chr($i);
	if (index ($dangerous, $chr) eq -1) {
		# Not
		is ($cgi->is_dangerous ($chr), 0, "Dangerous $i (not)");
	} else {
		is ($cgi->is_dangerous ($chr), 1, "Dangerous $i");
	}
}

for my $platform (qw/WINdows WINdows95 dos nt pc/) {
	$cgi->set_platform ($platform);
	is ($cgi->{platform}, 'PC', "Set platform ($platform)");
}
for my $platform (qw/mac MacIntosh/) {
	$cgi->set_platform ($platform);
	is ($cgi->{platform}, 'Mac', "Set platform ($platform)");
}

is ($cgi->set_platform(), undef, 'Set platform (undef) returns undef');
is ($cgi->{platform}, 'Mac', "Set platform (undef) - platform unchanged");

# Unix is default
$cgi->set_platform ('foo');
is ($cgi->{platform}, 'Unix', "Set default platform");

is ($cgi->wrap_textarea (), undef, 'No text to wrap');
my $longstr = '123 456 789 0123456 7 89 0';
is ($cgi->wrap_textarea ($longstr, 5), "123\n456\n789\n0123456\n7 89\n0",
	"wrap_textarea Unix");
$cgi->set_platform ("DOS");
is ($cgi->wrap_textarea ($longstr, 5), "123\r\n456\r\n789\r\n0123456\r\n7 89\r\n0",
	"wrap_textarea DOS");
$cgi->set_platform ("Mac");
is ($cgi->wrap_textarea ($longstr, 5), "123\r456\r789\r0123456\r7 89\r0",
	"wrap_textarea Mac");

is ($cgi->is_error(), 0, 'No errors');
is ($cgi->get_error_message, undef, 'No error message');

is ($cgi->get_multiple_values (), undef,
	'get_multiple_values (no argument)');
is ($cgi->get_multiple_values ('foo'), 'foo',
	'get_multiple_values (scalar argument)');
is ($cgi->get_multiple_values ('foo', 'bar'), 'foo',
	'get_multiple_values (array argument)');
my $foobar = ['foo', 'bar'];
my @res = $cgi->get_multiple_values ($foobar);
is_deeply (\@res, $foobar, 'get_multiple_values (array ref argument)');

like ($cgi->_get_file_name ('Unix', '/tmp', ''), qr/^\d+__/,
	'Missing filename');

{
	no strict 'vars'; # Makes the whole thing pointless
	no warnings 'once';
	$cgi->create_variables ({foo => 'bar', boing => 'quux'});
	is ($foo, 'bar', 'Create variables 1');
	is ($boing, 'quux', 'Create variables 2');
}

# Use Test::Trap where available to test wanrings and terminating
# functions.
SKIP: {
	skip "Test::Trap not available", 10 unless $have_test_trap;
    my @r = trap { browser_escape ('a') };
    like ($trap->stderr,
        qr/Non-method use of browser_escape is deprecated/,
        'Warning calling browser_escape as non-method');
    @r = trap { url_encode ('a') };
    like ($trap->stderr,
        qr/Non-method use of url_encode is deprecated/,
        'Warning calling url_encode as non-method');
    @r = trap { url_decode ('a') };
    like ($trap->stderr,
        qr/Non-method use of url_decode is deprecated/,
        'Warning calling url_decode as non-method');
    @r = trap { is_dangerous ('a') };
    like ($trap->stderr,
        qr/Non-method use of is_dangerous is deprecated/,
        'Warning calling is_dangerous as non-method');
	@r = trap { $cgi->return_error ('Hello', 'World!') };
	is ($trap->exit, 1, 'return_error exits');
	is ($trap->stdout, "Hello World!\n", 'return_error prints');

	# Same, but use child class
	{
		package MyChild;
		use base 'CGI::Lite';
	}
	my $child = MyChild->new;

    @r = trap { $child->browser_escape ('a') };
    unlike ($trap->stderr,
        qr/Non-method use of browser_escape is deprecated/,
        'No warning calling browser_escape as child method');
    @r = trap { $child->url_encode ('a') };
    unlike ($trap->stderr,
        qr/Non-method use of url_encode is deprecated/,
        'No warning calling url_encode as child method');
    @r = trap { $child->url_decode ('a') };
    unlike ($trap->stderr,
        qr/Non-method use of url_decode is deprecated/,
        'No warning calling url_decode as child method');
    @r = trap { $child->is_dangerous ('a') };
    unlike ($trap->stderr,
        qr/Non-method use of is_dangerous is deprecated/,
        'No warning calling is_dangerous as child method');
}
