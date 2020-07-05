package Clang::CastXML::Exception::ProcessException::BadCastXMLVersionException;

use Moo;
use 5.020;
use experimental qw( signatures );

# ABSTRACT: Exception for when we can't find the CastXML version
our $VERSION = '0.01'; # VERSION


extends 'Clang::CastXML::Exception::ProcessException';


sub message ($) { "unable to find castxml version" }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clang::CastXML::Exception::ProcessException::BadCastXMLVersionException - Exception for when we can't find the CastXML version

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This class represents an exception when trying to determine the CastXML
version.

=head1 EXTENDS

This class extends L<Clang::CastXML::Exception::ProcessException>.

=head1 METHODS

=head2 message

 my $message = $ex->message;

Returns the exception message.

=head1 SEE ALSO

L<Clang::CastXML>, L<Clang::CastXML::Exception>,
L<Clang::CastXML::Exception::ProcessException>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
