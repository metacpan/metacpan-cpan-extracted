
use strict;
use warnings;
use Contextual::Call qw(ccall);
use Data::Dumper;

# case 1, at proxy function.

print "# case 1, at proxy function.\n\n";
my $x = &func_1;

sub func_1
{
	print "here is func_1, calling func_2.\n";
	my $cc = ccall(\&func_2);
	print "func_2 returns: [[\n".Dumper($cc->result)."]].\n";
	$cc->result;
}
sub func_2
{
	print "here is func_2\n";
	"result";
}

# case 2, at proxy method.

print "\n# case 2, at proxy method.\n\n";
my @y = Derived->func();

package Base;
sub func
{
	print "here is Base::func.\n";
	qw(listed result values);
}
package Derived;
use base 'Base';
use Contextual::Call qw(ccall);
use Data::Dumper;
sub func
{
	my $pkg = shift;
	print "here is $pkg\::func, calling SUPER::func.\n";
	my $cc = ccall(sub{$pkg->SUPER::func()});
	print "SUPER returns: [[\n".Dumper($cc->result)."]].\n";
	$cc->result;
}

print "\n";
