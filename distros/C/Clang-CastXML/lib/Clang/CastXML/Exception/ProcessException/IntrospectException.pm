package Clang::CastXML::Exception::ProcessException::IntrospectException;

use Moo;
use 5.020;
use experimental qw( signatures );

# ABSTRACT: Exception for when castxml fails introspection
our $VERSION = '0.01'; # VERSION


extends 'Clang::CastXML::Exception::ProcessException';


sub message ($self)
{
  my $err = $self->result->err =~ s/\s+$//r =~ s/^\s+//r;
  $err ne ''
    ? "$err\nerror calling castxml for introspection"
    : "error calling castxml for introspection";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clang::CastXML::Exception::ProcessException::IntrospectException - Exception for when castxml fails introspection

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This class represents an exception when trying to introspect C/C++
code by running CastXML.

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
