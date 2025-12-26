package AnyEvent::FTP::Client::Site::Base;

use strict;
use warnings;
use 5.010;
use Moo;

# ABSTRACT: base class for AnyEvent::FTP::Client::Site::* classes
our $VERSION = '0.20'; # VERSION

sub BUILDARGS
{
  my($class, $client) = @_;
  return { client => $client };
}

has client => ( is => 'ro', required => 1 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Client::Site::Base - base class for AnyEvent::FTP::Client::Site::* classes

=head1 VERSION

version 0.20

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
