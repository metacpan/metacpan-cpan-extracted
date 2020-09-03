package Alien::Base::ModuleBuild::Cabinet;

use strict;
use warnings;
use Sort::Versions qw( versioncmp );

# ABSTRACT: Private class
our $VERSION = '1.15'; # VERSION

sub new {
  my $class = shift;
  my $self = ref $_[0] ? shift : { @_ };

  bless $self, $class;

  return $self;
}

sub files { shift->{files} }

sub add_files {
  my $self = shift;
  push @{ $self->{files} }, @_;
  return $self->files;
}

sub sort_files {
  my $self = shift;

  $self->{files} = [
    sort { $b->has_version <=> $a->has_version || ($a->has_version ? versioncmp($b->version, $a->version) : versioncmp($b->filename, $a->filename)) }
    @{ $self->{files} }
  ];

  ## split files which have versions and those which don't (sorted on filename)
  #my ($name, $version) = part { $_->has_version } @{ $self->{files} };
  #
  ## store the sorted lists of versioned, then non-versioned
  #my @sorted;
  #push @sorted, sort { versioncmp( $b->version,  $a->version  ) } @$version if $version;
  #push @sorted, sort { versioncmp( $b->filename, $a->filename ) } @$name    if $name;
  #
  #$self->{files} = \@sorted;

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Base::ModuleBuild::Cabinet - Private class

=head1 VERSION

version 1.15

=head1 AUTHOR

Original author: Joel A Berger E<lt>joel.a.berger@gmail.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

David Mertens (run4flat)

Mark Nunberg (mordy, mnunberg)

Christian Walde (Mithaldu)

Brian Wightman (MidLifeXis)

Graham Ollis (plicease)

Zaki Mughal (zmughal)

mohawk2

Vikas N Kumar (vikasnkumar)

Flavio Poletti (polettix)

Salvador Fandiño (salva)

Gianni Ceccarelli (dakkar)

Pavel Shaydo (zwon, trinitum)

Kang-min Liu (劉康民, gugod)

Nicholas Shipp (nshp)

Petr Pisar (ppisar)

Alberto Simões (ambs)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2020 by Joel A Berger.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
