use strict;
$^W++;
use Class::Prototyped qw(:REFLECT);
use Data::Dumper;
use Test;
use IO::File;

BEGIN {
	$|++;
	plan tests => 18;
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

my $fileName = 't/xxxtest.pl';
my $file = IO::File->new( ">$fileName" )
	or die "Can't open $fileName: $!\n";
$file->print($_) while <DATA>;
close($file);

package A;
sub Aa { 'Aaa' }

package main;

my $p  = Class::Prototyped->new();
my $pm = $p->reflect;

ok( !defined( $p->can('b') ) );
ok( !defined( $p->can('c') ) );
ok( !defined( $p->can('d') ) );
ok( !defined( $p->can('e') ) );
ok( !defined( $p->can('thisObject') ) );
ok( ! $p->isa( 'A' ) );
ok( scalar( () = $pm->slotNames ), 0 );

$pm->include( $fileName, 'thisObject' );

ok( defined( $p->can('b') ) );
ok( defined( $p->can('c') ) );
ok( defined( $p->can('d') ) );
ok( defined( $p->can('e') ) );
ok( !defined( $p->can('thisObject') ) );
ok( $p->b, 'xxx.b' );
ok( $p->isa( 'A' ) );
ok( $p->Aa, 'Aaa' );
ok( scalar( ( ) = $pm->slotNames ) == 5 );
ok( !defined( eval { $p->c }  ) );
ok( $@ =~ /Undefined subroutine/ );

unlink $fileName;

# File to include below:
__END__

sub b { 'xxx.b' }

sub c { return thisObject(); }

thisObject()->reflect->addSlots(
	'parent*' => 'A',
	d => 'added.d',
	e => sub { 'xxx.e' },
);

1;
