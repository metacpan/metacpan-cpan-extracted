use strict;
use File::Spec;
use Probe::Perl;
use Test::More;

plan tests => 5;

my $perl = Probe::Perl->find_perl_interpreter;
my $script = File::Spec->catfile(qw/bin checkdigits.pl/); 

# first check whether script with option -help or -man runs
#
is(system($perl, $script, '-help'),0, "run with -help");
is(system($perl, $script, '-man'),0, "run with -man");

my ($pipe,$out,@args);

@args = qw(-algorithm isbn check 1-55860-701-3);
#
# On MSWin32: List form of pipe open not implemented
#
open($pipe, join(' ', $perl, $script, @args, '|'));
$out = <$pipe>;
close $pipe;
like($out,qr/^valid$/,"checked with ISBN algorithm");

@args = qw(-algorithm isbn checkdigit 1-55860-701-3);
#
# On MSWin32: List form of pipe open not implemented
#
open($pipe, join(' ', $perl, $script, @args, '|'));
$out = <$pipe>;
close $pipe;
like($out,qr/^3$/,"checked and separated checkdigit with ISBN algorithm");

@args = qw(-algorithm isbn complete 1-55860-701-);
#
# On MSWin32: List form of pipe open not implemented
#
open($pipe, join(' ', $perl, $script, @args, '|'));
$out = <$pipe>;
close $pipe;
like($out,qr/^1-55860-701-3$/,"completed checkdigit with ISBN algorithm");
