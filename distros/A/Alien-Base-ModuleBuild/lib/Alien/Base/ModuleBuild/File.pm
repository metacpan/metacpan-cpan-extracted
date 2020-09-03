package Alien::Base::ModuleBuild::File;

use strict;
use warnings;
use Carp;

# ABSTRACT: Private class
our $VERSION = '1.15'; # VERSION

sub new {
  my $class = shift;
  my $self = ref $_[0] ? shift : { @_ };

  bless $self, $class;

  return $self;
}

sub has_version {
  my $self = shift;
  return defined $self->version;
}

sub get {
  my $self = shift;
  my $repo = $self->repository;

  my $filename = $repo->get_file($self->filename);
  if ( my $new_filename = $repo->{new_filename} ) {
    $filename = $new_filename;
  }

  ## whatever happened, record the new filename
  $self->{filename} = $filename;

  if (defined $self->{sha1} || defined $self->{sha256}) {
    unless (eval { require Digest::SHA }) {
      warn "sha1 or sha256 sums are specified but cannot be checked since Digest::SHA is not installed";
      return $filename;
    }

    eval { require Digest::SHA } or return $filename;
    ## verify that the SHA-1 and/or SHA-256 sums match if provided
    if (defined $self->{sha1}) {
      my $sha = Digest::SHA->new(1);
      $sha->addfile($filename);
      unless ($sha->hexdigest eq $self->{sha1}) {
          carp "SHA-1 of downloaded $filename is ", $sha->hexdigest,
          " Expected: ", $self->{sha1};
          return undef;
      }
    }
    if (defined $self->{sha256}) {
      my $sha = Digest::SHA->new(256);
      $sha->addfile($filename);
      unless ($sha->hexdigest eq $self->{sha256}) {
          carp "SHA-256 of downloaded $filename is ", $sha->hexdigest,
          " Expected: ", $self->{sha256};
          return undef;
      }
    }
  }

  return $filename;
}

sub platform   { shift->{platform}   }
sub repository { shift->{repository} }
sub version    { shift->{version}    }
sub filename   { shift->{filename}   }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Base::ModuleBuild::File - Private class

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
