# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

my $final = 0;

# Automatically generates an ok/nok msg, incrementing the test number.
BEGIN {
   my($next, @msgs);
   sub printok {
      push @msgs, ($_[0] ? '' : 'not ') . "ok @{[++$next]}\n";
      return !$_[0];
   }
   END {
      print "\n1..", scalar @msgs, "\n", @msgs;
   }
}

use Argv;
$final += printok(1);

# Make sure output arrives synchronously.
select(STDERR); $| = 1; select(STDOUT); $| = 1;

print "+ Testing basic construction and execution ...\n";
my $pl = Argv->new($^X, '-v');
$pl->stdout(0);
$pl->system;
$final += printok($? == 0);

print "+ Testing instance cloning ...\n";
$pl->clone->system;
$final += printok($? == 0);

print "+ Testing construction using references ...\n";
$final += printok(Argv->new($^X, [qw(-v)])->stdout(0)->system('') == 0);

print "+ Testing 'noexec' instance-method form ...\n";
$pl->noexec(1)->system;
$final += printok($? == 0);

print "+ Testing 'autofail' exception-handling ...\n";
$pl->argv($^X, ['-BADFLAG']);
$pl->autofail([\&printok, 1]);
$pl->stderr(0)->system;

print "+ Testing 'glob' method ...\n";
my $echo = Argv->new(qw(echo *));
$echo->glob;
print "'echo *' globs to: ";
$echo->system;
$final += printok($? == 0);

print "+ Testing 'dbglevel' instance-method form ...\n";
Argv->dbglevel(1);
my $ld = Argv->new($^X, qw(-bogus flag -V:ld));
$ld->dbglevel(0);
$ld->parse(qw(bogus=s));
$ld->system('-');
$final += printok($? == 0);
$ld->dbglevel(0);

$ld->dfltsets({'-' => 1});
print $ld->qx;
$final += printok($? == 0);

# Expected to return nonzero status and error (suppressed).
$final += printok(Argv->new('no-such-cmd')->stderr(0)->system);

my $e2 = Argv->new(qw(foo -y -x foo -r Next-to-last-test ...));
$e2->optset(qw(ONE TWO THREE));
$e2->parseONE(qw(x=s));
$e2->parseTWO(qw(y z));
$e2->parseTHREE('r');
$e2->prog('echo');
$e2->system;
$final += printok(!$? && ($e2->optsONE + $e2->optsTWO + $e2->optsTHREE) == 4);

exit $final if $final;

my $id2 = Argv->new(qw(id -y -x foo -a -r));
$id2->optset(qw(REMOVED));
my @removed = $id2->parseREMOVED(qw(r y x=s));
local $, = ' ';
print "Removed '@removed', left '@{[$id2->prog, $id2->opts, $id2->args]}'\n";
print "NOTE: this test sets the 'noexec' class attr so no exec will occur\n";
Argv->noexec(1);
$id2->exec(qw(-));
