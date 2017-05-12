use strict;
$^W++;
use Class::Prototyped qw(:REFLECT :EZACCESS :OVERLOAD);
use Data::Dumper;
use Test;

BEGIN {
	$|++;
	plan tests => 159,
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

sub Class::Prototyped::slotNames      { $_[0]->reflect->slotNames }
sub Class::Prototyped::allSlotNames   { $_[0]->reflect->allSlotNames }
sub Class::Prototyped::withAllParents { $_[0]->reflect->withAllParents }
sub Class::Prototyped::allParents     { $_[0]->reflect->allParents }
sub Class::Prototyped::parents        { $_[0]->reflect->parents }
sub Class::Prototyped::slotType       { (shift)->reflect->slotType(@_) }

# Create empty
{
	my $p1 = Class::Prototyped->new();
	ok( defined($p1) );
	ok( !$p1->can('f1') );
	ok( $p1->isa('Class::Prototyped') );
	ok( ref($p1) ne 'Class::Prototyped' );
	ok( join ( ' ', $p1->slotNames ),    '' );
	ok( join ( ' ', $p1->allSlotNames ), '' );
}

# Create non-empty
{
	my $p2 = Class::Prototyped->new(
		f1 => 'p2.f1',
		f2 => 'p2.f2',
		s1 => sub {'p2.s1'},
		s2 => sub {'p2.s2'},
		s3 => sub {'p2.s3'},
	);
	ok( defined($p2) );
	ok( join ( ' ', $p2->slotNames ),    'f1 f2 s1 s2 s3' );
	ok( join ( ' ', $p2->allSlotNames ), 'f1 f2 s1 s2 s3' );
	ok( $p2->isa('Class::Prototyped') );
	ok( ref($p2) ne 'Class::Prototyped' );
	ok( defined( $p2->can('f1') ) );

	ok( $p2->f1, 'p2.f1' );
	ok( join('|', $p2->reflect->findImplementation('f1')), 'self*' );
	ok( scalar($p2->reflect->findImplementation('f1')), $p2 );

	ok( defined( $p2->can('f2') ) );
	ok( $p2->f2, 'p2.f2' );
	ok( defined( $p2->can('s1') ) );

	ok( $p2->s1, 'p2.s1' );
	ok( join('|', $p2->reflect->findImplementation('s1')), 'self*' );
	ok( scalar($p2->reflect->findImplementation('s1')), $p2 );

	ok( defined( $p2->can('s2') ) );
	ok( $p2->s2, 'p2.s2' );
	ok( defined( $p2->can('s3') ) );
	ok( $p2->s3, 'p2.s3' );
	ok( !$p2->can('s4') );
	ok( $p2->slotType('f1') eq 'FIELD' );
	ok( defined( $p2->slotType('s1') ) );
	ok( $p2->slotType('s1') eq 'METHOD' );
	my @parents = $p2->parents;
	ok( @parents, 0 );
	@parents = $p2->allParents;
	ok( @parents, 0 );
	@parents = $p2->withAllParents;
	ok( @parents, 1 );
	ok( $parents[0] == $p2 );
}

# Inherit empty
{
	my $p1 = Class::Prototyped->new;
	my $p3 = Class::Prototyped->new( 'parent*' => $p1 );
	ok( defined($p3) );
	ok( !defined( $p3->can('f1') ), 1,
		'make sure there are no lingering f pointers' );
	ok( !defined( $p3->can('s1') ), 1,
		'make sure there are no lingering s pointers' );
	ok( $p3->isa('Class::Prototyped') );
	ok( $p3->isa( ref($p1) ) );
	ok( ref($p3) ne 'Class::Prototyped' );
	ok( $p3->isa( ref($p1) ) );
	ok( ref($p3) ne ref($p1) );
	ok( join ( ' ', $p3->slotNames ), 'parent*' );
	ok( join ( ' ', $p3->allSlotNames ), 'parent*' );
	my @parents = $p3->parents;
	ok( @parents, 1 );
	ok( $parents[0] == $p1 );
	@parents = $p3->allParents;
	ok( @parents, 1 );
	ok( $parents[0] == $p1 );
	@parents = $p3->withAllParents;
	ok( @parents, 2 );
	ok( $parents[0] == $p3 );
	ok( $parents[1] == $p1 );
}

# Inherit empty and add slots
{
	my $p1 = Class::Prototyped->new;
	my $p3 = Class::Prototyped->new(
		'parent*' => $p1,
		f1        => 'p3.f1',
		f2        => 'p3.f2',
		s1        => sub {'p3.s1'},
	);
	ok( defined($p3) );
	ok( $p3->isa('Class::Prototyped') );
	ok( $p3->isa( ref($p1) ) );
	ok( ref($p3) ne 'Class::Prototyped' );
	ok( $p3->isa( ref($p1) ) );
	ok( ref($p3) ne ref($p1) );
	ok( defined( $p3->can('f1') ) );
	ok( defined( $p3->can('f2') ) );
	ok( defined( $p3->can('s1') ) );
	ok( $p3->f1, 'p3.f1' );
	ok( $p3->f2, 'p3.f2' );
	ok( $p3->s1, 'p3.s1' );
	ok( join ( ' ', $p3->slotNames ),    'parent* f1 f2 s1' );
	ok( join ( ' ', $p3->allSlotNames ), 'parent* f1 f2 s1' );
}

# Clone non-empty
{
	my $p2 = Class::Prototyped->new(
		f1 => 'p2.f1',
		f2 => 'p2.f2',
		s1 => sub {'p2.s1'},
		s2 => sub {'p2.s2'},
		s3 => sub {'p2.s3'},
	);
	my $p3 = $p2->clone();
	ok( defined($p3) );
	ok( $p3->isa('Class::Prototyped') );
	ok( ref($p3) ne 'Class::Prototyped' );
	ok( !( $p3->isa( ref($p2) ) ) );
	ok( defined( $p3->can('f1') ) );
	ok( $p3->f1, 'p2.f1' );
	ok( defined( $p3->can('s1') ) );
	ok( $p3->s1, 'p2.s1' );
	ok( !defined( $p3->can('s4') ) );

	# Verify data copied not aliased
	ok( $p3->f1('p3.f1'), 'p3.f1' );
	ok( $p3->f1, 'p3.f1' );
	ok( $p2->f1, 'p2.f1' );
	ok( $p3->f2, 'p2.f2' );
}

# Clone non-empty and add slots at same time
{
	my $p2 = Class::Prototyped->new(
		f1 => 'p2.f1',
		f2 => 'p2.f2',
		s1 => sub {'p2.s1'},
		s2 => sub {'p2.s2'},
		s3 => sub {'p2.s3'},
	);
	my $p3 = $p2->clone(
		f1 => 'p3.f1',
		s1 => sub {'p3.s1'},
	);
	ok( $p3->f1, 'p3.f1' );
	ok( $p3->s1, 'p3.s1' );
	ok( $p2->f1, 'p2.f1' );
	ok( $p2->s1, 'p2.s1' );
	ok( $p3->f2, 'p2.f2' );
	ok( $p3->f1('p3.f1 too'), 'p3.f1 too' );
	ok( $p3->f1, 'p3.f1 too' );
	ok( $p2->f1, 'p2.f1' );
}

# Inherit non-empty twice and add slots at same time
{
	my $p1 = Class::Prototyped->new(
		f1 => 'p1.f1',
		f2 => 'p1.f2',
		f3 => 'p1.f2',
		s1 => sub {'p1.s1'},
		s2 => sub {'p1.s2'},
		s3 => sub {'p1.s3'},
	);
	my $p2 = $p1->new(
		f1        => 'p2.f1',
		s1        => sub {'p2.s1'},
	);
	my $p3 = $p2->new(
		f3        => 'p3.f3',
		s3        => sub {'p3.s3'},
	);
	ok( $p1->f1, 'p1.f1' );

	ok( $p2->f1, 'p2.f1' );
	ok( join('|', $p2->reflect->findImplementation('f1')), 'self*' );
	ok( scalar($p2->reflect->findImplementation('f1')), $p2 );

	ok( $p3->f1, 'p2.f1' );
	ok( join('|', $p3->reflect->findImplementation('f1')), 'class*|self*' );
	ok( scalar($p3->reflect->findImplementation('f1')), $p2 );

	ok( $p1->s1, 'p1.s1' );

	ok( $p2->s1, 'p2.s1' );
	ok( join('|', $p2->reflect->findImplementation('s1')), 'self*' );
	ok( scalar($p2->reflect->findImplementation('s1')), $p2 );

	ok( $p3->s1, 'p2.s1' );
	ok( join('|', $p3->reflect->findImplementation('s1')), 'class*|self*' );
	ok( scalar($p3->reflect->findImplementation('s1')), $p2 );

	ok( $p2->f1('p2.f1 too'), 'p2.f1 too' );
	ok( $p2->f1, 'p2.f1 too' );
	ok( $p3->f1, 'p2.f1 too' );
	ok( $p3->f1('p3.f1 too'), 'p3.f1 too' );
	ok( $p3->f1, 'p3.f1 too' );
	ok( $p2->f1, 'p3.f1 too' );
	my @parents = $p3->parents;
	ok( @parents, 1 );
	@parents = $p3->allParents;
	ok( @parents, 2 );
	@parents = $p3->withAllParents;
	ok( @parents, 3 );
	ok( $parents[0] == $p3 );
	ok( $parents[1] == $p2 );
	ok( $parents[2] == $p1 );

	ok( join('|', $p3->reflect->findImplementation('f2')), 'class*|class*|self*' );
	ok( scalar($p3->reflect->findImplementation('f2')), $p1 );
}

# Add a second parent
{
	my $p1 = Class::Prototyped->new(
		f2 => 'p1.f2',
		s2 => sub {'p1.s2'},
	);
	my $p2 = Class::Prototyped->new(
		'*' => $p1,
		f1 => 'p2.f1',
		s1 => sub {'p2.s1'},
	);
	my $p3 = Class::Prototyped->new(
		f3 => 'p3.f3',
		s3 => sub {'p3.s3'},
	);
	$p2->addSlot('*' => $p3);
	ok( $p2->isa( ref($p1) ) );
	ok( $p2->isa( ref($p3) ) );
	ok( $p2->f1, 'p2.f1' );
	ok( $p2->f3, 'p3.f3' );    # XXX should this be copied?
	ok( !defined( $p3->can('f1') ) );
	ok( $p2->s1, 'p2.s1' );
	ok( $p2->s3, 'p3.s3' );
	ok( !defined( $p3->can('s1') ) );

	ok( $p1->f2('p1.f2 too'), 'p1.f2 too' );
	ok( $p1->f2, 'p1.f2 too' );
	ok( $p2->f2, 'p1.f2 too' );

	my @parents = $p2->parents;
	ok( @parents, 2 );
	@parents = $p2->allParents;
	ok( @parents, 2 );
	@parents = $p2->withAllParents;
	ok( @parents, 3 );
	ok( $parents[0] == $p2 );
	ok( $parents[1] == $p1 );
	ok( $parents[2] == $p3 );
}

# Clone non-empty and add slots later
{
	my $p2 = Class::Prototyped->new(
		f1 => 'p2.f1',
		f2 => 'p2.f2',
		s1 => sub {'p2.s1'},
		s2 => sub {'p2.s2'},
		s3 => sub {'p2.s3'},
	);
	my $p3 = $p2->clone;
	$p3->addSlots(
		f1 => 'p3.f1',
		s1 => sub {'p3.s1'},
	);
	ok( $p3->f1, 'p3.f1' );
	ok( $p3->s1, 'p3.s1' );
	ok( $p2->f1, 'p2.f1' );
	ok( $p2->s1, 'p2.s1' );
	ok( $p3->f2, 'p2.f2' );
	ok( $p3->f1('p3.f1 too'), 'p3.f1 too' );
	ok( $p3->f1, 'p3.f1 too' );
}

# Add slots to parent and verify inheritance
{
	my $p1 = Class::Prototyped->new;
	my $p2 = Class::Prototyped->new(
		'*' => $p1,
		f1 => 'p2.f1',
		s1 => sub {'p2.s1'},
		f2 => 'p2.f2',
		s2 => sub {'p2.s2'}
	);
	$p1->addSlots(
		f3 => 'p1.f3',
		s3 => sub {'p1.s3'},
		f2 => 'p1.f2',
		s2 => sub {'p1.s2'}
	);
	ok( $p2->f1, 'p2.f1' );
	ok( $p2->f2, 'p2.f2' );
	ok( $p2->f3, 'p1.f3' );
	ok( $p2->s1, 'p2.s1' );
	ok( $p2->s2, 'p2.s2' );
	ok( $p2->s3, 'p1.s3' );    # defined in parent; get it through inheritance
}

# Delete slots from child and verify inheritance
{
	my $p1 = Class::Prototyped->new(
		f3 => 'p1.f3',
		s3 => sub {'p1.s3'},
		f2 => 'p1.f2',
		s2 => sub {'p1.s2'}
	);
	my $p2 = Class::Prototyped->new(
		'*' => $p1,
		f1 => 'p2.f1',
		s1 => sub {'p2.s1'},
		f2 => 'p2.f2',
		s2 => sub {'p2.s2'}
	);
	$p2->deleteSlots(qw(f2 s2));
	ok( $p2->f1, 'p2.f1' );
	ok( $p2->f2, 'p1.f2' );
	ok( $p2->s1, 'p2.s1' );
	ok( $p2->s2, 'p1.s2' );
}

# Delete slots in parent without disturbing child
{
	my $p1 = Class::Prototyped->new(
		f3 => 'p1.f3',
		s3 => sub {'p1.s3'},
		f2 => 'p1.f2',
		s2 => sub {'p1.s2'}
	);
	my $p2 = Class::Prototyped->new(
		f1 => 'p2.f1',
		s1 => sub {'p2.s1'},
		f2 => 'p2.f2',
		s2 => sub {'p2.s2'}
	);
	$p1->deleteSlots(qw(f2 s2));
	ok( $p2->f1, 'p2.f1' );
	ok( $p2->f2, 'p2.f2' );
	ok( $p2->s1, 'p2.s1' );
	ok( $p2->s2, 'p2.s2' );
}

# Delete slots in child and make sub undef
# Delete slots in child and make field undef
{
	my $p1 = Class::Prototyped->new(
		f3 => 'p1.f3',
		s3 => sub {'p1.s3'},
		f2 => 'p1.f2',
		s2 => sub {'p1.s2'}
	);
	my $p2 = $p1->clone(
		f1 => 'p2.f1',
		s1 => sub {'p2.s1'},
		f2 => 'p2.f2',
		s2 => sub {'p2.s2'}
	);
	$p2->deleteSlots(qw(f1 s1));
	ok( !defined( $p2->can('f1') ) );
	ok( !defined( $p2->can('s1') ) );
}

# Delete slots in parent and make sub undef
# Delete slots in parent and make field undef
{
	my $p1 = Class::Prototyped->new(
		f3 => 'p1.f3',
		s3 => sub {'p1.s3'},
		f2 => 'p1.f2',
		s2 => sub {'p1.s2'}
	);
	my $p2 = Class::Prototyped->new(
		'*' => $p1,
		f1 => 'p2.f1',
		s1 => sub {'p2.s1'},
		f2 => 'p2.f2',
		s2 => sub {'p2.s2'}
	);
	$p1->deleteSlots(qw(f3 s3));
	ok( !defined( $p2->can('f3') ) );
	ok( !defined( $p2->can('s3') ) );
}

# Verify slot inheritance works after parent add slots
{
	my $p1 = Class::Prototyped->new;
	my $p2 = Class::Prototyped->new( '*' => $p1 );
	$p1->addSlots(
		f1 => 'p1.f1',
		s1 => sub {'p1.s1'},
	);
	ok( $p2->f1, 'p1.f1' );    # XXX should this copy?
	ok( $p2->s1, 'p1.s1' );
}

# Add slots to child & verify child gets new behavior
{
	my $p1 = Class::Prototyped->new;
	my $p2 = Class::Prototyped->new;
	$p2->addSlots(
		'*' => $p1,
		f1 => 'p2.f1',
		s1 => sub {'p2.s1'},
	);
	ok( $p2->f1, 'p2.f1' );
	ok( $p2->s1, 'p2.s1' );
}

# Override a data slot with a sub slot
# Override a sub slot with a data slot
# Replace a data slot with a sub slot
# Replace a sub slot with a data slot
# Test data dumper behavior

# vim: ft=perl
