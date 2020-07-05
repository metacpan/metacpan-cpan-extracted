package Clang::CastXML::Exception::ProcessException;

use Moo;
use 5.020;
use experimental qw( signatures );

# ABSTRACT: Exception for when the CastXML process fails
our $VERSION = '0.01'; # VERSION


extends 'Clang::CastXML::Exception';


has result => (
  is       => 'ro',
  required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clang::CastXML::Exception::ProcessException - Exception for when the CastXML process fails

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This class represents a execution exception while running CastXML.
It shouldn't be thrown directly, instead it is subclassed by
L<Clang::CastXML::Exception::ProcessException::BadCastXMLVersionException>
and
L<Clang::CastXML::Exception::ProcessException::IntrospectException>
which represent specific types of processing exceptions.

=head1 EXTENDS

This class extends L<Clang::CastXML::Exception>.

=head1 PROPERTIES

=head2 result

 my $result = $ex->result;

This returns the L<Clang::CastXML::Wrapper::Result> of the failed
CastXML run.

=head1 SEE ALSO

L<Clang::CastXML>, L<Clang::CastXML::Exception>,
L<Clang::CastXML::Exception::ProcessException::BadCastXMLVersionException>,
L<Clang::CastXML::Exception::ProcessException::IntrospectException>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
