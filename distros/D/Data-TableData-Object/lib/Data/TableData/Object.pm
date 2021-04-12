package Data::TableData::Object;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-10'; # DATE
our $DIST = 'Data-TableData-Object'; # DIST
our $VERSION = '0.112'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Check::Structure qw(is_aos is_aoaos is_aohos);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(table);

sub table { __PACKAGE__->new(@_) }

sub new {
    my ($class, $data, $spec) = @_;
    if (!defined($data)) {
        die "Please specify table data";
    } elsif (ref($data) eq 'HASH') {
        require Data::TableData::Object::hash;
        Data::TableData::Object::hash->new($data);
    } elsif (is_aoaos($data)) {
        require Data::TableData::Object::aoaos;
        Data::TableData::Object::aoaos->new($data, $spec);
    } elsif (is_aohos($data)) {
        require Data::TableData::Object::aohos;
        Data::TableData::Object::aohos->new($data, $spec);
    } elsif (ref($data) eq 'ARRAY') {
        require Data::TableData::Object::aos;
        Data::TableData::Object::aos->new($data);
    } else {
        die "Unknown table data form, please supply array of scalar, ".
            "array of array-of-scalar, or array of hash-of-scalar";
    }
}

1;
# ABSTRACT: Manipulate data structure via table object

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TableData::Object - Manipulate data structure via table object

=head1 VERSION

This document describes version 0.112 of Data::TableData::Object (from Perl distribution Data-TableData-Object), released on 2021-04-10.

=for Pod::Coverage ^$

=head1 FUNCTIONS

=head2 table($data[ , $spec ]) => obj

Shortcut for C<< Data::TableData::Object->new(...) >>.

=head1 METHODS

=head2 new($data[ , $spec ]) => obj

Detect the structure of C<$data> and create the appropriate
C<Data::TableData::Object::FORM> object.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-TableData-Object>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-TableData-Object>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-TableData-Object>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::TableData::Object::Base> for list of available methods.

L<Data::TableData::Object::aos>

L<Data::TableData::Object::aoaos>

L<Data::TableData::Object::aohos>

L<Data::TableData::Object::hash>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
