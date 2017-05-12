package Basset::Test::More;

#Basset::Test::More, copyright and (c) 2004 James A Thomason III

$VERSION = '1.00';

use Basset::Test;
@ISA = qw(Basset::Test);

use Test::Builder;

use strict;
use warnings;

=pod

=head1 Basset::Test::More

Basset::Test::More is a drop-in replacement for Basset::Test. Change the test type in your conf
file for a global change.

Basset::Test will actually test all of your functions and spit out the output. Basset::Test::More
will generate (to STDOUT) a .t file suitable using Test::More suitable for running through Test::Harness.

=cut

sub test {
	my $self = shift;
	my $class = shift;
	my $superclasses = shift;
	
	$self->singleton(Test::Builder->new);

	$self->_output([]);

	$self->singleton->no_header(1);
	$self->singleton->no_ending(1);
	
	my @t = $self->get_all_tests($class, $superclasses) or return;

	my $plan = $self->plan();
	
	print "use Test::More tests => $plan;\n";
	print "use $class;\n";
	print "package $class;\n";

	$self->generate_t($class, @t);
}

sub generate_t {
	my $self = shift;
	my $class = shift;
	my @t = @_;
	
	my $tfile = 1;

	#open (T, ">$tfile") || return $self->error("Could not open t file : $!", "BTM-01");
	open(T, ">-");
	
	while (@t) {
		my $n = shift @t;
		my $test = shift (@t);
		if (defined $test && $test =~ /\S/) {
			next if $test =~ /^\s*#line \d+\s+\w+\s*$/s;
			my $t = '{' . $test . '};';
			$t =~ s/__PACKAGE__/$class/g;
			$t =~ s/\$test->plan\(.+$//gm;
			$t =~ s/\$test->/Test::More::/g;
			print T "$t\n";
		}
	}
	
	#close (T) || return $self->error("Could not close t file : $!", "BTM-02");
	
	return $tfile;
}

1;
