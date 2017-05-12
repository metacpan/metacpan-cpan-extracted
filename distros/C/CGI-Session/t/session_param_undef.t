#/usr/bin/perl -w

package Container;
sub new {
	my $class = shift;
	my $self  = {
		items => [],
	};
	bless ($self, $class);
	return $self;
}
sub add_item {
	my ($self,$item) = @_;
	push @{$self->{items}}, $item;
	return;
}
sub get_items {
	my $self = shift;
	return @{$self->{items}};
}

package Item;
sub new {
	my $class = shift;
	my $name  = shift;
	my $self = {
		name => $name,
	};
	bless ($self, $class);
	return $self;
}

sub get_name {
	my $self = shift;
	return $self->{name};
}

package main;

use strict;

use File::Spec;

use Test::More tests => 21;
use_ok('CGI::Session');

my $dir_name = File::Spec->tmpdir();

STORE:{

my $session = CGI::Session->new('serializer:default;id:static','testname',{Directory=>$dir_name});
ok($session);

my $item1 = Item->new("test 123");
my $container = Container->new();
$container->add_item($item1);
my ($item2) = $container->get_items();

is ($item1, $item2, 'Items are still equal after storing');

$session->param('container', $container);

test_can($container,$item1,'Check in STORE of original item');
test_can($container,$item2,'Check in STORE of stored/retrieved item');

# If you remove the following line (and make sure there's not an already damaged session on disk), the problem is gone.
$session->param('somevar', undef);

$session->flush();

}

LOAD:{

my $session   = CGI::Session->load('serializer:default;id:static','testname',{Directory=>$dir_name});
my $container = $session->param('container');
my ($item) = $container->get_items();
test_can($container,$item, 'Check in LOAD after loading from session');

}

sub test_can {
	my ($container, $item, $descr) = @_;
	diag "$descr\n";
	can_ok('Container', 'add_item');
	isa_ok($container,  'Container');
	can_ok($container,  'add_item');

	can_ok('Item', 'get_name');
	isa_ok($item, 'Item');
	can_ok($item, 'get_name');
}
