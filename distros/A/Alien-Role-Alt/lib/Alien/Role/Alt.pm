package Alien::Role::Alt;

use strict;
use warnings;
use 5.008001;
use Role::Tiny;
use Storable ();
use Carp ();

# ABSTRACT: Alien::Base role that supports alternates
our $VERSION = '0.03'; # VERSION


sub alt
{
  my($old, $name) = @_;
  my $new = ref $old ? (ref $old)->new : $old->new;

  my $orig;
  
  if(ref($old) && defined $old->{_alt})
  { $orig = $old->{_alt}->{orig} }
  else
  { $orig = $old->runtime_prop }
  
  my $runtime_prop = Storable::dclone($orig);
  
  if($runtime_prop->{alt}->{$name})
  {
    foreach my $key (keys %{ $runtime_prop->{alt}->{$name} })
    {
      $runtime_prop->{$key} = $runtime_prop->{alt}->{$name}->{$key};
    }
  }
  else
  {
    Carp::croak("no such alt: $name");
  }

  $new->{_alt} = {
    runtime_prop => $runtime_prop,
    orig         => $orig,
  };   
  
  $new;
}

around runtime_prop => sub {
  my $orig = shift;

  my($self) = @_;
  
  if(ref($self) && defined $self->{_alt})
  {
    return $self->{_alt}->{runtime_prop};
  }
  else
  {
    return $orig->($self);
  }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Role::Alt - Alien::Base role that supports alternates

=head1 VERSION

version 0.03

=head1 SYNOPSIS

From your L<alienfile>

 use alienfile;
 
 plugin 'PkgConfig' => (
   pkg_name => [ 'libfoo', 'libbar', ],
 );

The in your base class:

 package Alien::Libfoo;
 
 use base qw( Alien::Base );
 use Role::Tiny::With qw( with );
 
 with 'Alien::Role::Alt';
 
 1;

Then you can use it:

 use Alien::Libfoo;
 
 my $cflags = Alien::Libfoo->alt('foo1')->cflags;
 my $libs   = Alien::Libfoo->alt('foo1')->libs;

=head1 DESCRIPTION

Some packages come with multiple libraries, and multiple C<.pc> files to
use with them.  This L<Role::Tiny> role can be used with L<Alien::Base>
to access different configurations.

=head1 METHODS

=head2 alt

 my $new_alien = $old_alien->alt($alt_name);

Returns an L<Alien::Base> instance with the alternate configuration.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
