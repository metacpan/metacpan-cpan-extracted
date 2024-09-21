use strict;
$^W++;
use Class::Prototyped qw(:NEW_MAIN);
use Data::Dumper;
use Test;

BEGIN {
	$|++;
	plan tests => 57;
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

my $p1 = new( a => 2, b => sub {'b'} );

ok( $p1->a, 2 );
ok( $p1->{a}, 2 );

ok( $p1->a(3), 3 );
ok( $p1->{a}, 3 );
ok( $p1->a, 3 );

ok( $p1->{a} = 4, 4 );
ok( $p1->a, 4 );
ok( $p1->{a}, 4 );

ok( $p1->b, 'b' );
ok( !(defined(eval { $p1->{b} })));
ok( $@ =~ /^attempt to access METHOD slot through tied hash object interface/ );

ok( !(defined(eval { $p1->{b} = 'c' })));
ok( $@ =~ /^attempt to access METHOD slot through tied hash object interface/ );

ok( !(defined(eval { $p1->{c} })));
ok( $@ =~ /^attempt to access non-existent slot through tied hash object interface/ );

ok( !(defined(eval { $p1->{c} = 'c' })));
ok( $@ =~ /^attempt to access non-existent slot through tied hash object interface/ );

ok( !(defined(eval { %{$p1} = (a => 2) })));
ok( $@ =~ /^attempt to call CLEAR on the hash interface of a Class::Prototyped object/ );

ok( join('|', keys %{$p1}), 'a');

$p1->reflect->addSlot('parent*' => new( d => 5, e => sub {'e'}));
ok( join('|', keys %{$p1}), 'parent*|a');

ok( $p1->d, 5);
ok( !(defined(eval { $p1->{d} })));
ok( $@ =~ /^attempt to access non-existent slot through tied hash object interface/ );

ok( $p1->reflect->getSlot('parent*')->{d} = 7, 7);
ok( $p1->d, 7);

my $p3 = $p1->clone;
ok( $p1->reflect->tiedInterfacePackage(), 'Class::Prototyped::Tied::Default');
ok( $p3->reflect->tiedInterfacePackage(), 'Class::Prototyped::Tied::Default');
$p3->reflect->tiedInterfacePackage('autovivify');
ok( $p3->reflect->tiedInterfacePackage(), 'Class::Prototyped::Tied::AutoVivify');
ok( $p1->reflect->getSlot('parent*')->{d} = 7, 7);
ok( $p1->d, 7);
ok( !(defined($p3->{d})));
ok( $p3->{d} = 4, 4 );
ok( $p3->d, 4 );
ok( $p3->b, 'b' );
ok( !(defined(eval { $p3->{b} })));
ok( $@ =~ /^attempt to access METHOD slot through tied hash object interface/ );

my $p4 = $p1->clone;
ok( $p4->reflect->tiedInterfacePackage(), 'Class::Prototyped::Tied::Default');
ok( !(defined(eval { $p4->{d} })));
ok( $@ =~ /^attempt to access non-existent slot through tied hash object interface/ );

my $p5 = $p3->clone;
ok( Class::Prototyped->reflect->tiedInterfacePackage(), 'Class::Prototyped::Tied::Default');
ok( $p5->reflect->tiedInterfacePackage(), 'Class::Prototyped::Tied::AutoVivify');
ok( (defined(eval { $p3->{d} })));

@Test::Default_A1::ISA = qw(Class::Prototyped);
@Test::Default_A2::ISA = qw(Test::Default_A1);
my $p6 = Test::Default_A2->new(c => 5);
ok( $p6->c, 5 );
ok( $p6->{c}, 5);
ok( $p6->{c} = 7, 7);
ok( $p6->{c}, 7);
ok( !(defined(eval { $p6->{d} })));
ok( $@ =~ /^attempt to access non-existent slot through tied hash object interface/ );

@Test::Autovivify_A1::ISA = qw(Class::Prototyped);
@Test::Autovivify_A2::ISA = qw(Test::Autovivify_A1);
@Test::Autovivify_A3::ISA = qw(Test::Autovivify_A2);
Test::Autovivify_A1->reflect->tiedInterfacePackage('autovivify');
my $p7 = Test::Autovivify_A3->new(c => 5);
ok( $p7->c, 5 );
ok( $p7->{c}, 5);
ok( $p7->{c} = 7, 7);
ok( $p7->{c}, 7);
ok( $p7->{d} = 4, 4 );
ok( (defined(eval { $p7->{d} })));

@Test::Default_B1::ISA = qw(Test::Default_A2 Test::Autovivify_A3);
my $p8 = Test::Default_B1->new();
ok( !(defined(eval { $p8->{d} })));
ok( $@ =~ /^attempt to access non-existent slot through tied hash object interface/ );
