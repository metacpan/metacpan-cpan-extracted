use strict;
use warnings;

use FindBin::libs;
use Data::Dump qw/pp/;
use Test::More;
use Test::Framework;
use Path::Class::File;


note "Type stuff..";
#my $target = Test::Meta::Framework->find_ilike_node('Node A2 ');
my $run = Test::Framework->create_run();
is(ref($run),'DBIx::Patcher::Schema::Result::Patcher::Run',
    'created a run');
my $file = Test::Framework->uniq_name('file');
my $patch = $run->add_patch(
    $file, 'MD5'
#    Path::Class::File->new('t/data/file_1.sql'), 'MD5'
);
is(ref($patch),'DBIx::Patcher::Schema::Result::Patcher::Patch',
    "added patch to run - $file");

my $patch = Test::Framework->search_file($file);

is(ref($patch), 'DBIx::Patcher::Schema::Result::Patcher::Patch',
    "found file - $file");

#my $got_rs = Test::Meta::Framework->get_type({ name => $type->name });
#is($got_rs->count, 1,
#    'only one type found');
#
#my $got = $got_rs->first;
#is($got->id, $got->id,
#    'retrieved a type');
#
#my $types_rs = Test::Meta::Framework->get_types();
#is(ref($types_rs),'Meta::Schema::ResultSet::Meta::Type',
#    'resultset of types');
#is($types_rs->count >= 1,1,
#    'one or more of types');

#my $found = 0;
#my $poss = undef;
#do {
#    $poss = $root_rs->next;
#    is(ref($poss),'Meta::Schema::Result::Meta::Node',
#        'it is a node');
#    $found++ if ($poss->id == $node->id);
#} while (not $found && defined $poss);
#
#is($found, 1,
#    'found node in set');
#
#my $name = Test::Meta::Framework->uniq_name('Child');
#$node->add_node({
#    name => $name,
#});
#my $children_rs = $node->children;
#is($children_rs->count >= 1, 1,
#    'has one of more children');
#$found = 0;
#$poss = undef;
#do {
#    $poss = $children_rs->next;
#    is(ref($poss),'Meta::Schema::Result::Meta::Node',
#        'it is a node');
#    $found++ if ($poss->name eq $name);
#} while (not $found && defined $poss);
#
#is($found, 1,
#    'found child node in set');


#my $target = Test::Meta::Framework->find_ilike_node('Node A2 ');
#my $new_parent = Test::Meta::Framework->find_ilike_node('Node B ');
#
#$target->move_node($new_parent->id);
#
#my $new_path = $new_parent->path;
#note "$new_path == ". $target->path;
#is(($target->path =~ /^${new_path},/), 1,
#    'moved node has correct path');

done_testing;

#sub build_tree {
#    my($args) = @_;
#    my $fields = \%{$args};
#    my $kids = delete $fields->{children};
#    
#    my $root = Test::Meta::Framework->add_node( $fields );
#    
#    is(ref($root), 'Meta::Schema::Result::Meta::Node',
#        'parent node created - '. $root->name);
#
#    is($root->path,$root->id,
#        'path correct - '. $root->path);
#
#    if ($kids) {
#        foreach my $kid (@{$kids}) {
#            build_child($root,$kid);
#        }
#    }
#
#    return $root;
#}
#
#sub build_child {
#    my($root,$args) = @_;
#    my $kids = delete $args->{children};
#    my $child = Test::Meta::Framework->add_node( $root, $args );
#
#    is(ref($child),'Meta::Schema::Result::Meta::Node','created child');
#    is($child->path, $root->path.','.$child->id, 'child path correct');
#
#    if ($kids) {
#        foreach my $kid (@{$kids}) {
#            build_child($child,$kid);
#        }
#    }
#
#    return $child;
#}
