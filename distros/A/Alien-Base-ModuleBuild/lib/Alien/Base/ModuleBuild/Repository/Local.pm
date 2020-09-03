package Alien::Base::ModuleBuild::Repository::Local;

use strict;
use warnings;
use Carp;
use File::chdir;
use File::Copy qw/copy/;
use Path::Tiny qw( path );
use parent 'Alien::Base::ModuleBuild::Repository';

# ABSTRACT: Local file repository handler
our $VERSION = '1.15'; # VERSION

sub new {
  my $class = shift;

  my $self = $class->SUPER::new(@_);

  # make location absolute
  local $CWD = $self->location;
  $self->location("$CWD");

  return $self;
}

sub list_files {
  my $self = shift;

  local $CWD = $self->location;

  opendir( my $dh, $CWD);
  my @files =
    grep { ! /^\./ }
    readdir $dh;

  return @files;
}

sub get_file  {
  my $self = shift;
  my $file = shift || croak "Must specify file to copy";

  my $full_file = do {
    local $CWD = $self->location;
    croak "Cannot find file: $file" unless -e $file;
    path($file)->absolute->stringify;
  };

  copy $full_file, $CWD;

  return $file;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Base::ModuleBuild::Repository::Local - Local file repository handler

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
