package Alien::LibJIT;
# ABSTRACT: your very own libjit for nefarious Perl purposes

use strict;
use warnings;
use File::ShareDir ();
use Config ();
use File::Spec;

our $VERSION = '0.03'; # VERSION


sub new {
  my $class = shift;

  Carp::croak('You must call this as a class method') if ref($class);

  my $self = bless {
    base_dir => File::Spec->catdir(
      File::ShareDir::dist_dir('Alien-LibJIT'),
      'libjit'
    ),
  } => $class;

  return $self;
}


sub lib_dir {
  my $self = shift;
  return $self->{lib_dir} if defined $self->{lib_dir};
  $self->{lib_dir} = File::Spec->catdir($self->{base_dir}, 'lib');
}


sub static_library {
  my $self = shift;
  return File::Spec->catfile($self->lib_dir, "libjit" . $Config::Config{lib_ext});
}


sub include_dir {
  my $self = shift;
  return $self->{include_dir} if defined $self->{include_dir};
  $self->{include_dir} = File::Spec->catdir($self->{base_dir}, 'include');
}

1;

__END__

=pod

=head1 NAME

Alien::LibJIT - your very own libjit for nefarious Perl purposes

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Alien::LibJIT;

  my $aroot = Alien::ROOT->new;

=head1 DESCRIPTION

Installs a copy of libjit for use from XS modules.

This version of C<Alien::LibJIT> comes with the libjit
code from L<http://git.savannah.gnu.org/r/libjit.git>
as of 1.9.2013.

=head1 METHODS

=head2 Alien::LibJIT->new

Creates a new C<Alien::LibJIT> object.

=head2 lib_dir

Returns the directory which the libjit static library
resides in.

=head2 static_library

Returns the path to the libjit static library.

=head2 include_dir

Returns the directory which the libjit headers
reside in.

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

Mattia Barbon E<lt>mattia@barbon.orgE<gt>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Alien::LibJIT

You can also look for information at:

=over

=item * Metacpan

L<metacpan.org/module/Alien::LibJIT>

=item * CPAN Request Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-LibJIT>

=item * CPAN Testers Platform Compatibility Matrix

L<http://cpantesters.org/show/Alien-LibJIT.html>

=back

=head1 SEE ALSO

L<Alien>, the Alien manifesto.

L<LibJIT>, an XS wrapper for libjit using this module.

L<Perl::JIT>, a JIT compiler for Perl.

=head1 LICENSE

This module is licensed under the same terms as Perl itself,

=head1 AUTHORS

=over 4

=item *

Mattia Barbon <mattia@barbon.org>

=item *

Steffen Mueller <smueller@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steffen Mueller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
