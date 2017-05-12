#!perl -w

use strict;
use Data::Util qw(:all);
use Benchmark qw(:all);

use FindBin qw($Bin);
use lib $Bin;
use Common;

signeture 'Data::Util' => \&modify_subroutine;

sub f  { 42 }

sub before  { 1 }
sub around  {
	my $f = shift;
	$f->(@_) + 1;
}
sub after   { 1 }

my @before = (\&before, \&before);
my @around = (\&around);
my @after  = (\&after, \&after);

my $modified = modify_subroutine(\&f, before => \@before, around => \@around, after => \@after);

sub modify{
	my $subr   = shift;
	my @before = @{(shift)};
	my @around = @{(shift)};
	my @after  = @{(shift)};

	$subr = curry($_, (my $tmp = $subr), *_) for @around;

	return sub{
		$_->(@_) for @before;
		my @ret = wantarray ? $subr->(@_) : scalar $subr->(@_);
		$_->(@_) for @after;
		return wantarray ? @ret : $ret[0];
	};
}
my $closure = modify(\&f, \@before, \@around, \@after);

$modified->(-1) == 43 or die $modified->(-10);
$closure->(-2) == 43 or die $closure->(-20);

print "Creation of modified subs:\n";
cmpthese timethese -1 => {
	modify => sub{
		my $w = modify_subroutine(\&f, before => \@before, around => \@around, after => \@after);
	},
	closure => sub{
		my $w = modify(\&f, \@before, \@around, \@after);
	},
};

sub combined{
	$_->(@_) for @before;
	around(\&f, @_);
	$_->(@_) for @after;
}

print "Calling modified subs:\n";
cmpthese timethese -1 => {
	modify => sub{
		$modified->(42);
	},
	closure => sub{
		$closure->(42);
	},
	combined => sub{
		combined(42);
	},

};

