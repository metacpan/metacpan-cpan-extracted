use strict;
$^W++;
use Class::Prototyped qw(:EZACCESS);
use Data::Dumper;
use Test;

BEGIN {
	$|++;
	plan tests => 11
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

package main;

my $record = '';
my ( $p1_name, $wrapped1_name, $wrapped2_name );
{

	# Make an object with functionality:
	my $p1 = Class::Prototyped->new(
		s1         => sub {'p1.s1'},
		s2         => sub {'p1.s2'},
		'destroy!' => sub {
			$record .= "About to call super->('destroy') on $_[0].\n";
			$_[0]->super('destroy');
			$record .= "Finished super->('destroy') on $_[0].\n";
		},
	);

	$p1_name = '' . ($p1);

	ok( $p1->s1, 'p1.s1' );
	ok( $p1->s2, 'p1.s2' );

	$p1->reflect->wrap(
		's1!' => sub {
			my $self = shift;
			'before.' . $self->super('s1') . '.after';
		}
	);
	$wrapped1_name = '' . ( $p1->reflect->getSlot('wrapped*') );

	ok( $p1->s1, 'before.p1.s1.after' );

	$p1->reflect->wrap(
		's1!' => sub {
			my $self = shift;
			'xx.' . $self->super('s1') . '.xx';
		}
	);
	$wrapped2_name = '' . ( $p1->reflect->getSlot('wrapped*') );

	ok( $p1->s1, 'xx.before.p1.s1.after.xx' );

	ok( $record, '' );
	$p1->reflect->unwrap;
	ok( $record, <<END );
About to call super->('destroy') on $wrapped2_name.
Finished super->('destroy') on $wrapped2_name.
END

	ok( $p1->s1, 'before.p1.s1.after' );

	$record = '';
	$p1->reflect->unwrap;
	ok( $record, <<END );
About to call super->('destroy') on $wrapped1_name.
Finished super->('destroy') on $wrapped1_name.
END

	ok( $p1->s1, 'p1.s1' );

	$p1->reflect->wrap(
		's1!' => sub {
			my $self = shift;
			'before.' . $self->super('s1') . '.after';
		}
	);

	$wrapped1_name = '' . ( $p1->reflect->getSlot('wrapped*') );

	$record = '';
	ok( $p1->s1, 'before.p1.s1.after' );
}

ok( $record, <<END);
About to call super->('destroy') on $p1_name.
Finished super->('destroy') on $p1_name.
About to call super->('destroy') on $wrapped1_name.
Finished super->('destroy') on $wrapped1_name.
END

# vim: ft=perl
