use strict;
use warnings FATAL => 'all';

package Data::Couplet::Extension;
BEGIN {
  $Data::Couplet::Extension::AUTHORITY = 'cpan:KENTNL';
}
{
  $Data::Couplet::Extension::VERSION = '0.02004314';
}

# ABSTRACT: A convenient way for sub classing Data::Couplet with minimal effort

use MooseX::Types::Moose qw( :all );
use Carp;


sub _dump {
  my (@args) = @_;
  require Data::Dumper;
  local $Data::Dumper::Terse     = 1;
  local $Data::Dumper::Indent    = 0;
  local $Data::Dumper::Maxdepth  = 1;
  local $Data::Dumper::Quotekeys = 0;
  return Data::Dumper::Dumper(@args);
}

sub _carp_key {
  my ( $key, $config, $message ) = @_;
  carp( sprintf '%s => %s %s', $key, _dump( $config->{$key} ), $message );
  return;
}

sub _croak_key {
  my ( $key, $config, $message ) = @_;
  croak( sprintf '%s => %s %s', $key, _dump( $config->{$key} ), $message );
}


sub import {
  my ( $class, @args ) = @_;
  my (%config) = (@args);
  my $caller = caller;

  require Moose;
  require Data::Couplet::Private;
  require Data::Couplet::Role::Plugin;

  $config{-into} = $caller unless exists $config{-into};

  #_croak_key( -into => \%config, 'target is not a valid ClassName' ) unless is_ClassName( $config{-into} );

  if ( $config{-into} eq 'main' ) {
    _carp_key( -into => \%config, '<-- is main, not injecting' );
    return;
  }

  $config{-base} = q{} unless exists $config{-base};

  _croak_key( -base => \%config, 'is not a Str' ) unless is_Str( $config{-base} );

  $config{-base_package} = 'Data::Couplet';
  if ( $config{-base} ne q{} ) {
    $config{-base_package} = 'Data::Couplet::' . $config{-base};
  }

  if ( $config{-base_package} eq 'Data::Couplet' ) {
    require Data::Couplet;
  }

  _croak_key( -base_package => \%config, 'is not a valid ClassName' )
    unless is_ClassName( $config{-base_package} );

  $config{-with} = [] unless exists $config{-with};
  $config{-with_expanded} = [];

  _croak_key( -with => \%config, 'is not an ArrayRef' ) unless is_ArrayRef( $config{-with} );
  for ( @{ $config{-with} } ) {
    my $plugin = 'Data::Couplet::Plugin::' . $_;
    eval "require $plugin; 1" or croak("Could not load Data::Couplet plugin $plugin");
    croak("plugin $plugin loaded, but still seems not to be a valid ClassName") unless is_ClassName($plugin);
    croak("plugin $plugin cant meta")                                           unless $plugin->can('meta');
    croak("plugin $plugin meta cant does_role")                                 unless $plugin->meta->can('does_role');
    croak("plugin $plugin doesn't do DC::R:P") unless $plugin->meta->does_role('Data::Couplet::Role::Plugin');
    push @{ $config{-with_expanded} }, $plugin;
  }

  # Input validation and expansion et-all complete.
  # Inject warnings/strict for caller.
  strict->import();
  warnings->import();
  Moose->import( { into => $config{-into}, } );
  $config{-into}->can('extends')->( $config{-base_package} );
  $config{-into}->can('with')->( @{ $config{-with_expanded} } );
  return;
}


sub unimport {

  # Sub Optimal, but cant be avoided atm because Moose lacks
  # A 3rd-Party friendly unimport
  goto \&Moose::unimport;
}

1;


__END__
=pod

=head1 NAME

Data::Couplet::Extension - A convenient way for sub classing Data::Couplet with minimal effort

=head1 VERSION

version 0.02004314

=head1 SYNOPSIS

  package My::DC;
  use Data::Couplet::Extension -with [qw( Plugin )];
  __PACKAGE__->meta->make_immutable;
  1;

This provides a handy way to subclass L<Data::Couplet>, glue a bunch of DC plug-ins into it, and just use it.

The alternative ways, while working, are likely largely suboptimal ( applying roles to instances, yuck );

This gives you an easy way to create a sub class of L<Data::Couplet>, and possibly tack on some of your own
methods directly.

=head1 METHODS

=head2 import

Makes the calling package a Data::Couplet subclass.

  Data::Couplet::Extension->import(
    -into => ( $target || caller ),
    -base => ( $name   || ''     ),
    -with => ( [qw( PluginA PluginB )] || [] ),
  );

=head3 -into => $target

This is a convenience parameter, to make it easier to do via a 3rd party.

If not set, its automatically set to C<scalar caller()>;

=head3 -base => $name

This is also mostly a convenience parameter, at this time, the only reason you'd want to set
this to something, would be if you wanted to extend the L<Data::Couplet::Private> core, and that's
recommended only for experts who don't like our interface.

Incidentally, we use this to make Data::Couplet.

=head3 -base_package => $name

You can't set this yourself, we overwrite it, but this documentation is here to clarify how it works.

This is the expansion of C<-base>. '' becomes 'Data::Couplet' ( which is the default ) and all other values
become  'Data::Couplet::' . $value;

This is then used via L<Moose> C<extends> to define your packages base class.

=head3 -with => [qw( name )]

This one you probably want the most. Its semantically the same as Moose's C<with>, except that for convenience, all values of C<name> are expanded to C<Data::Couplet::name> and various tests are done on them to make sure they are compatible.

You can leave this empty, but you're not maximising the point of this utility unless you fill it.

=head3 -with_expanded => [qw( name )]

You can't set this, we overwrite it. It gets  populated from C<-with> by simple expansion, C<Data::Couplet::Plugin::$value>.

These are fed to Moose's C<with> method on your package

=head2 unimport

Seeing the only things we import come from Moose anyway, this is just

  goto \&Moose::unimport;

=head1 AUTHOR

Kent Fredric <kentnl at cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

