#!/usr/bin/perl

package Config::PackageGlobal::OO;

use strict;
use warnings;

use Carp ();

use Context::Handle ();

our $VERSION = "0.02";

sub new {
	my ( $class, $pkg, @methods ) = @_;

	my %methods;
	foreach my $method ( @methods ) {
		no strict 'refs';
		$methods{$method} = \&{ $pkg . "::" . "$method" };
		defined &{$methods{$method}}
			|| Carp::croak("The function '$method' does not exist in $pkg");
	}

	bless {
		pkg => $pkg,
		methods => \%methods,
		conf => { },
		conf_subs => { },
	}, $class;
}

my %sub_cache;
sub AUTOLOAD {
	my ( $self, @args ) = @_;
	my ( $method ) = ( our $AUTOLOAD =~ /([^:]+)$/ );

	if ( my $sub = $self->{methods}{$method} ) {
		my $prev = $self->_set_conf( $self->{conf} );

		local $@;
		my $rv = Context::Handle->new(sub {
			eval { $sub->( @args ) };
		});

		$self->_set_conf( $prev );
		die $@ if $@;

		# $rv->return barfs here, either because of the goto or because of the AUTOLOAD
		# bus error in autoload, illegal instruction in goto
		return $rv->value;
	} else {
		unless ( exists $self->{conf}{$method} ) {
			# initial value is copied from package
			$self->{conf}{$method} = $self->_conf_accessor( $method );
		}

		$self->{conf}{$method} = \@args if @args;

		return scalar @{ $self->{conf}{$method} } != 1 ? @{ $self->{conf}{$method} } : $self->{conf}{$method}[0];
	}
}

sub _set_conf {
	my ( $self, $conf ) = @_;

	my %prev;

	foreach my $key ( keys %$conf ) {
		$prev{$key} = $self->_set_conf_key( $key, $conf->{$key} );
	}

	\%prev;
}

sub _conf_accessor {
	my ( $self, $key ) = ( shift, shift );

	my $accessor = $sub_cache{$self->{pkg}}{$key} ||= do {
		no strict 'refs';
		my $sub;
		my $sym = $self->{pkg} . '::' . $key;
		my $symtable = \%{ $self->{pkg} . '::' };

		if ( exists $symtable->{$key} ) {
			if ( *$sym{CODE} ) {
				my $orig = \&{$sym};
				$sub = sub { [ $orig->(@_) ] }
			} elsif ( *$sym{ARRAY} ) {
				my $var = \@{$sym};
				$sub = sub {
					@$var = @_ if @_;
					[ @$var ];
				}
			} else {
				my $var = \${$sym};
				$sub = sub {
					$$var = shift if @_;
					[ $$var ];
				};
			}
		} elsif ( exists $symtable->{"get_$key"} ) {
			my ( $get, $set ) = map { \&{ $self->{pkg} . '::' . $_ . '_' . $key } } qw/get set/;
			$sub = sub {
				$set->( @_ ) if @_;
				[ $get->() ];
			};
		} else {
			Carp::croak("The field '$key' does not exist in $self->{pkg}");
		}

		$sub_cache{$self->{pkg}}{$key} = $sub;
	};

	$accessor->( @_ );
}

sub _set_conf_key {
	my ( $self, $key, $new ) = @_;

	my $prev = $self->_conf_accessor( $key );
	$self->_conf_accessor( $key, @$new );
	return $prev;
}

sub DESTROY { } # shush autoload

__PACKAGE__;

__END__

=pod

=head1 NAME

Config::PackageGlobal::OO - A generic configuration object for modules with package global configuration

=head1 SYNOPSIS

	use Hash::Merge;
	use Config::PackageGlobal::OO;

	my $o = Config::PackageGlobal::OO->new( "Hash::Merge", qw/merge/ );

	$o->behavior( RIGHT_PRECEDENT );

	my $rv = $o->merge( $hash, $other );

	Hash::Merge::set_behavior(); # this is returned to it's previous value

=head1 DESCRIPTION

Modules with a package-global configuration tend to be tricky to use uninvasively.

Typically you see code like:

	sub mydump {
		my ( $self, @values ) = @_;

		local $Data::Dumper::SomeVar = $my_setting;
		Data::Dumper::Dumper( @values );
	}

Now, L<Data::Dumper> specifically has an OO interface precisely to solve this
problem, but some modules, like L<Hash::Merge> do not.

This module provides a generic wrapper object for modules that need this kind
of fudging in a safe an easy way.

=head1 METHODS

=over 4

=item new $package, @functions

This method returns an object that wraps around $package, and provides action
methods that wrap around every element in @functions.

=item AUTOLOAD

Calls to the wrapper methods will invoke the action.

Calls to any other method will set a value that will be set before every
action, and rolled back after every action.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2006 the aforementioned authors. All rights
	reserved. This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut

