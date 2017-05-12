
package Local::NoWeak;

use Scalar::Util qw(isweak reftype blessed refaddr);
use strict;
use warnings;
require Exporter;

our $weak = "<WEAK>";
our @EXPORT = qw(strong_clone);
our @ISA = qw(Exporter);

my %clone_actions = (
	HASH	=> sub {
		my $o = shift;
		my $n = {};
		for my $k (keys %$o) {
			my $v = $o->{$k};
			if (ref($v) && isweak($o->{$k})) {
				$n->{$k} = $weak;
			} else {
				$n->{$k} = clone($v);
			}
		}
		return $n;
	},
	ARRAY	=> sub {
		my $o = shift;
		my $n = [];
		for my $i (0..$#$o) {
			my $e = $o->[$i];
			if (ref($e) && isweak($o->[$i])) {
				push(@$n, $weak);
			} else {
				push(@$n, clone($e));
			}
		}
		return $n;
	},
	SCALAR	=> sub {
		my $o = shift;
		return $weak if ref($o) && isweak($o);
		return clone($o);
	},
	REGEX	=> sub { return $_[0]; },
	GLOB	=> sub { return $_[0]; },
	DIRHANDLE => sub { return $_[0]; },
	FILEHANDLE => sub { return $_[0]; },
	FORMAT	=> sub { return $_[0]; },
);
$clone_actions{REF} = $clone_actions{SCALAR};

my %seen;

# returns a clone of an object with all weak references removed
sub clone
{
	my ($o) = @_;
	return $o unless ref($o);
	return "<DUPLICATE>" if $seen{refaddr($o)}++;
	my $t = reftype($o);
	my $b = blessed($o);
	die unless $clone_actions{$t};
	my $n = $clone_actions{$t}->($o);
	bless $n, $b if $b;
	return $n;
}

sub strong_clone
{
	my ($o) = @_;
	undef %seen;
	return clone($o);
}

1;

