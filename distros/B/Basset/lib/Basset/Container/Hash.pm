package Basset::Container::Hash;

#Basset::Container::Hash, copyright and (c) 2005, 2006 James A Thomason III
#Basset::Container::Hash is distributed under the terms of the Perl Artistic License.

our $VERSION = '1.00';

=pod

=head1 Basset::Container::Hash

Basset::Container::Hash implements a layered hash. The easiest way to explain is with an example:

 my %x = ('a' => 'b');
 
 tie my %y, 'Basset::Container::Hash', \%x;	#<- %x is the parent of 'y'.
 
 print $x{'a'};	#prints b
 print $y{'a'}; #prints b (inherited from x)
 $y{'a'} = 'foo';
 $y{'z'} = 'bar';
 print $x{'a'};	#prints b
 print $y{'a'}; #prints foo (overriden in y)
 print $x{'z'};	#prints undef (not defined in x
 print $y{'z'}; #prints bar (overridden from x)
 delete $y{'a'};
 print $x{'a'};	#prints b
 print $y{'a'}; #prints b (inherited from x)
 $x{'b'} = 'c';
 print $x{'b'};	#prints c
 print $y{'b'}; #prints c (inherited from x)

=cut

use strict;
use warnings;

# we're going to use an array underneath and bypass Basset::Object & accessor, for speed reasons.
# since we only talk to it via the tie interface, we can get away with it.
our $internal_hash	= 0;
our $parent			= 1;
our $gotoparent		= 2;

sub TIEHASH {

	my $class	= shift;
	my $parent	= shift;
	
	return bless [
		{},
		$parent,
		0
	], $class;
}

sub STORE {
	my $self = shift;
	my $key = shift;
	my $value = shift;
	
	$self->[$internal_hash]->{$key} = $value;
}

sub FETCH {
	my $self	= shift;
	my $key		= shift;
	
	my $internal = $self->[$internal_hash];
	
	if (exists $internal->{$key}) {
		return $internal->{$key};
	}
	elsif (my $parent = $self->[$parent]) {
		return $parent->{$key};
	}
	else {
		return;
	}
}

sub EXISTS {
	my $self	= shift;
	my $key 	= shift;
	
	my $internal = $self->[$internal_hash];
	
	if (exists $internal->{$key}) {
		return exists $internal->{$key};
	}
	elsif (my $parent = $self->[$parent]) {
		return exists $parent->{$key};
	}
	else {
		return;
	}
}

sub DELETE {
	my $self = shift;
	my $key = shift;
	
	delete $self->[$internal_hash]->{$key};
}

sub CLEAR {
	shift->[$internal_hash] = {};
}

sub FIRSTKEY {
	my $self = shift;
	
	$self->[$gotoparent] = 0;
	
	my $internal = $self->[$internal_hash];
	my $c = keys %$internal;
	
	my ($k, $v) = each %$internal;

	unless (defined $k) {
		if (my $parent = $self->[$parent]) {
			$self->[$gotoparent] = 1;
			($k, $v) = each %$parent;
		}
	}

	return $k;
		
}

sub NEXTKEY {
	my $self = shift;
	
	my $internal = $self->[$internal_hash];
	
	unless ($self->[$gotoparent]) {
		my ($k, $v) = each %$internal;
		if (defined $k) {
			return $k;
		}
	}
	
	if (my $parent = $self->[$parent]) {
		$self->[$gotoparent] = 1;
		while (my ($k, $v) = each %$parent) {
			return $k unless exists $internal->{$k};
		}
		$self->[$gotoparent] = 0;
	}
	
	return;
}

sub SCALAR {
	my $self = shift;
	
	my $internal = $self->[$internal_hash];
	
	my %flat = ();
	@flat{keys %$internal} = values %$internal;
	
	return scalar %flat;
	
}

1;

=pod

=begin btest(Basset::Container::Hash)

my %x = ('a' => 'b');

tie my %y, 'Basset::Container::Hash', \%x;	#<- %x is the parent of 'y'.

$y{'a'} = 'c';
$y{'b'} = 'd';

$test->is($x{'a'}, 'b', '$x{a} = b');
$test->is($y{'a'}, 'c', '$y{a} = c');
$test->is($y{'b'}, 'd', '$y{b} = d');
$test->is($x{'b'}, undef, '$x{b} is undef');
$test->is(scalar(%y), '2/8', 'scalar %y works');
delete $y{'a'};
$test->is($y{'a'}, 'b', '$y{a} is now b');
$test->ok(exists $y{'a'} != 0, '$y{a} exists');
$test->ok(exists $y{'b'} != 0, '$y{b} exists');
$test->ok(exists $y{'c'} == 0, '$y{c} does not exist');
delete $y{'b'};

my ($key, $value) = each %y;

$test->is($key, 'a', 'only key left is a');

$y{'new'} = 'value';

my ($key2, $value2) = (keys %y)[0];

$test->is($key2, 'new', 'first set key is new');

my @keys = sort keys %y;
$test->is($keys[0], 'a', 'first key is a');
$test->is($keys[1], 'new', 'second key is new');

%y = ();
my @keys2 = sort keys %y;
$test->is(scalar @keys2, 1, 'only one key remains');

=end btest(Basset::Container::Hash)

=cut
