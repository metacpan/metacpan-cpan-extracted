
use v5.10;
use feature q (state);

use strict;
use warnings;

package Context::Singleton::Frame::DB;
$Context::Singleton::Frame::DB::VERSION = '1.0.9';
use Moo;

use Class::Load;
use Module::Pluggable::Object;
use Ref::Util;

use Context::Singleton::Singleton;

use namespace::clean;

has cache
	=> is       => ro
	=> default  => sub { +{} }
	=> init_arg => undef
	;

has plugins
	=> is       => ro
	=> default  => sub { +{} }
	=> init_arg => undef
	;

sub BUILD {
	my ($db) = @_;

	$db->contrive (q (Class::Load), (
		value => q (Class::Load),
	));

	$db->contrive (q (class_loader), (
		dep => [ q (Class::Load) ],
		as  => sub { $_[0]->can (q (load_class)) },
	));
}

sub _ensure_singleton {
	my ($db, $name) = @_;
	my $lookup_key = $db->_lookup_key ($name);

	return $db->cache->{$lookup_key} //= Context::Singleton::Singleton::->new (singleton => $name);
}

sub _lookup_key {
	my ($db, $name) = @_;

	return $name;
}

sub _search_singleton {
	my ($db, $name) = @_;

	return $db->cache->{ $db->_lookup_key ($name) };
}

sub contrive {
	my ($db, $name, %def) = @_;

	if ($def{class}) {
		$db->contrive_class ($def{class});
		$def{builder} //= q (new);
	}

	if ($def{class} // $def{deduce}) {
		$def{this} = $def{class} // $def{deduce};
		delete $def{class};
		delete $def{deduce};
	}

	$db->_ensure_singleton ($name)->add_builder (\ %def);

	return;
}

sub contrive_class {
	my ($db, $name) = @_;

	return
		if $db->_search_singleton ($name)
		;

	$db->contrive ($name, (
		dep => [ q (class_loader) ],
		as => eval qq (sub { \$_[0]->(q[$name]) && q[$name] }),
	));

	return;
}

sub instance {
	state $instance = __PACKAGE__->new;
	return $instance;
}

sub load_rules {
	my ($db, @packages) = @_;

	for my $package (@packages) {
		$db->plugins->{ $package } //= do {
			Module::Pluggable::Object->new (
				require => 1,
				search_path => [ $package ],
			)->plugins;
			1;
		};
	}

	return;
}

sub search_builder_for {
	my ($db, $name) = @_;

	return
		unless my $singleton = $db->_search_singleton ($name)
		;

	return $singleton->builders;
}

sub search_trigger_for {
	my ($db, $name) = @_;

	return
		unless my $singleton = $db->_search_singleton ($name)
		;

	return $singleton->on_destroy;
}

sub trigger {
	my ($db, $name, $code) = @_;

	$db->_ensure_singleton ($name)->add_on_destroy ($code);

	return;
}

1;

=pod

=encoding utf-8

=head1 NAME

Context::Singleton::DB - Internal class storing singleton rules.

=head1 DESCRIPTION

This is internal package.

=head1 AUTHOR

Branislav Zahradník <barney.cpan@gmail.com>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut

