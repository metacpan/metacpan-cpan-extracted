{   package DateTime::Format::XSD;

    use strict;
    use warnings;
    use base qw(DateTime::Format::ISO8601);
    our $VERSION = '0.2';

    sub format_datetime {
        my ($format, $date) = @_;
        my $out = $date->strftime('%FT%T%z');
        $out =~ s/(\d\d)$/:$1/;
        return $out;
    }
};
1;

=head1 NAME

DateTime::Format::XSD - Format DateTime according to xsd:dateTime

=head1 SYNOPSIS

  my $str = DateTime::Format::XSD->format_datetime($dt);

=head1 DESCRIPTION

XML Schema defines a usage profile which is a subset of the ISO8601
profile. This profile defines that the following is the only possible
representation for a dateTime, despite all other options ISO provides.

   YYYY-MM-DD"T"HH:MI:SS(Z|[+-]zh:zm)

This module is a subclass of DateTime::Format::ISO8601, therefore it
will be able to parse all other ISO options, but will only format it
in this exact spec.

=head1 SEE ALSO

L<DateTime>, L<DateTime::Format::ISO8601>, The XML Schema speficitation.

=head1 AUTHORS

Daniel Ruoso C<daniel@ruoso.com>

=head1 BUG REPORTS

Please submit all bugs regarding C<DateTime::Format::XSD> to
C<bug-datetime-format-xsd@rt.cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

