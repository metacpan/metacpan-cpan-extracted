package Clang::CastXML::Exception::ParseException;

use Moo;
use 5.022;
use experimental qw( signatures );

# ABSTRACT: Exception for when XML parsing fails
our $VERSION = '0.02'; # VERSION


extends 'Clang::CastXML::Exception';


sub message ($self)
{
  defined $self->previous_exception
    ? ($self->previous_exception =~ s/\s+$//r =~ s/^\s+//r) . "\nXML Parser exception"
    : "XML Parser exception";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clang::CastXML::Exception::ParseException - Exception for when XML parsing fails

=head1 VERSION

version 0.02

=head1 DESCRIPTION

This class represents a XML parser error for CastXML.

=head1 EXTENDS

This class extends L<Clang::CastXML::Exception>.

=head1 METHOD

=head2 message

 my $message = $ex->message;

Returns the message for the exception.

=head1 SEE ALSO

L<Clang::CastXML>, L<Clang::CastXML::Exception>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
