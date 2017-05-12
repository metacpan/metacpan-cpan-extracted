package main;
use Test::More tests => 43;
use strict;

package TestClass;
use Class::Std::Fast::Storable;
{
    my %name_of :ATTR( :get<name> :set<name> );
    my %flavor_of :ATTR( :get<flavor> :set<flavor> );
}

package LinkedList;
use Class::Std::Fast::Storable;
{
    my %info_of :ATTR( :get<info> :set<info> );
    my %next_node_for :ATTR( :get<next_node> :set<next_node> );
}

package TestMISubClass;
use Class::Std::Fast::Storable;
use base qw( TestClass LinkedList );
{
    my %ref_copy_for :ATTR( :get<ref_copy> );
    my %unknown1 :ATTR; #for testing with no attr name given
    my %unknown2 :ATTR; #for testing with no attr name given
    sub set_next_node {
        my $self = shift;
        my $id = ident $self;
        die "no param provided" unless @_;
        my $next_node = shift;
        $ref_copy_for{$id} = $next_node;
        $self->SUPER::set_next_node($next_node);
        return;
    }
    sub set_unknown1 {
        my $id = ident shift;
        $unknown1{$id} = shift;
    }
    sub get_unknown1 {
        return $unknown1{ident shift};
    }
    sub set_unknown2 {
        my $id = ident shift;
        $unknown2{$id} = shift;
    }
    sub get_unknown2 {
        return $unknown2{ident shift};
    }
}

package main;
use Class::Std::Fast::Storable;
use Storable;
use Carp;
use Data::Dumper;

##########################################################
# very basic testing of a single object
my $object = TestClass->new;
$object->set_name("Vanilla Bean");
$object->set_flavor("vanilla");

my $clone = Storable::dclone($object);
is( $clone->get_name, "Vanilla Bean", "properties successfully cloned");
is( $clone->get_flavor, "vanilla", "properties successfully cloned");

##########################################################
# testing a nested structure
my $first_node = LinkedList->new;
$first_node->set_info(1);
for my $i (2..10) {
    my $next_node = LinkedList->new;
    $next_node->set_info($i);
    $next_node->set_next_node($first_node);
    $first_node = $next_node;
}

my $id = ident($first_node);
$first_node = Storable::dclone($first_node);

isnt($id, ident($first_node), "should in fact be a different object");
for my $i (reverse 1..10) {
    is($first_node->get_info, $i, "values in the nodes all match");
    $first_node = $first_node->get_next_node;
}

##########################################################
# testing MI and structural integrity

my @flavors = qw( vanilla chocolate strawberry mango peach grape );
my $obj;
for my $flavor ( @flavors ) {
    my $next = TestMISubClass->new;
    $next->set_flavor($flavor);
    $next->set_info($flavor);
    $next->set_unknown1("1_$flavor");
    $next->set_unknown2("2_$flavor");
    $next->set_next_node($obj);
    $obj = $next;
}
$clone = Storable::freeze($obj);
undef $obj; #should destroy the whole list
$clone = Storable::thaw($clone);

for my $flavor ( reverse @flavors ) {
    is($flavor, $clone->get_flavor, "flavor cloned the same");
    is("1_$flavor", $clone->get_unknown1, "unknown1 cloned the same");
    is("2_$flavor", $clone->get_unknown2, "unknown2 cloned the same");
    my $next = $clone->get_next_node;
    my $copy = $clone->get_ref_copy;
    last unless $next;
    is(ident($next), ident($copy), "clones of same object should be the same");
    $clone = $next;
}

##########################################################
# generating diagnostics
$object = TestClass->new;
$object->set_name("Vanilla Bean");
$object->set_flavor("vanilla");

eval { $object->STORABLE_thaw(0, 0, {TestClass => { name => "foo" } } ) };
like($@, qr{trying to modify existing attributes}, "block attempted manipulation");

eval { $object->STORABLE_thaw(0, 0, {TestClass => { unknown => "foo" } } ) };
like($@, qr{unknown attribute}, "error on unknown attribute");

eval { $object->STORABLE_thaw(0, 0, {unknown => {} } ) };
like($@, qr{unknown base class}, "error on unknown base class");

##########################################################
# calling hooks

my($freeze_pre, $freeze_post, $thaw_pre, $thaw_post);

{ no warnings; #ignore spurious "only used once" warnings
*TestClass::STORABLE_freeze_pre = sub { $freeze_pre = 1 };
*TestClass::STORABLE_freeze_post = sub { $freeze_post = 1 };
*TestClass::STORABLE_thaw_pre = sub { $thaw_pre = 1 };
*TestClass::STORABLE_thaw_post = sub { $thaw_post = 1 };
}

Storable::dclone($object);
ok( $freeze_pre, "STORABLE_freeze_pre called");
ok( $freeze_post, "STORABLE_freeze_post called");
ok( $thaw_pre, "STORABLE_thaw_pre called");
ok( $thaw_post, "STORABLE_thaw_post called");

