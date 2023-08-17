# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 04-setup-rt.t".
#
# Without "Build" file it could be called with "perl -I../lib 04-setup-rt.t"
# or "perl -Ilib t/04-setup-rt.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Cwd;

use Test::More;
use Test::Output;

#####################################
# prepare fixed environment:
BEGIN {
    unless (defined $DB::{single})
    {
        # This check confuses the Perl debugger, so we wont run it while
        # debugging:
        eval { require Term::ReadLine::Gnu; };
        $@ =~ m/^It is invalid to load Term::ReadLine::Gnu directly/
            or  plan skip_all => 'Term::ReadLine::Gnu not found';
    }
    my $tty = `tty`;
    chomp $tty;
    -c $tty  and  -w $tty
        or  plan skip_all => 'required TTY (' . $tty . ') not available';
    plan tests => 1;

    delete $ENV{DISPLAY};
    $ENV{UI} = 'RichTerm';
}
use App::LXC::Container;

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;
my $re_error_to_small = '^screen [0-9x]+ to small for window, ' .
    'need >= [0-9x]+ for all UI variants' . $re_msg_tail;

#########################################################################
# just run _create_main_window with another (non-PoorTerm) UI:

my %dummy_obj = (MAIN_UI => UI::Various::Main->new(),
		 name => 'x', packages => [], mounts => [], filter => [],
		 network => 0, x11 => 0, audio => 0, users => []);
my $dummy_obj = bless \%dummy_obj, 'App::LXC::Container::Setup';
output_like
{   App::LXC::Container::Setup::_create_main_window($dummy_obj);   }
    qr{^$},
    qr{^(?:$re_error_to_small)?$},
    'RichTerm printed expected output';
