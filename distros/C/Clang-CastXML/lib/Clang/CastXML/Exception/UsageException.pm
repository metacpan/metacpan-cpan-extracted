package Clang::CastXML::Exception::UsageException;

use Moo;
use 5.020;
use experimental qw( signatures );

# ABSTRACT: Exception for when the Clang::CastXML is fed rubbish
our $VERSION = '0.01'; # VERSION


extends 'Clang::CastXML::Exception';


has diagnostic => (
  is       => 'ro',
  required => 1,
);


sub message { shift->diagnostic }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clang::CastXML::Exception::UsageException - Exception for when the Clang::CastXML is fed rubbish

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This class represents a usage exception.  Usually when you provide the wrong
types of arguments to a method or function.

=head1 EXTENDS

This class extends L<Clang::CastXML::Exception>.

=head1 PROPERTIES

=head2 diagnostic

 my $diag = $ex->diagnostic;

This returns a concise diagnostic of what usage was wrong.

=head1 METHODS

=head2 message

 my $message = $ex->message;

This returns the exception message.

=head1 SEE ALSO

L<Clang::CastXML>, L<Clang::CastXML::Exception>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
