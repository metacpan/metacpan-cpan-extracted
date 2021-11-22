package Data::TableData::Object;

use 5.010001;
use strict;
use warnings;

use Data::Check::Structure qw(is_aos is_aoaos is_aohos);
use Exporter qw(import);
use Scalar::Util qw(blessed);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-17'; # DATE
our $DIST = 'Data-TableData-Object'; # DIST
our $VERSION = '0.114'; # VERSION

our @EXPORT_OK = qw(table);

sub table { __PACKAGE__->new(@_) }

sub new {
    my ($class, $data, $spec) = @_;
    if (!defined($data)) {
        die "Please specify table data";
    } elsif (blessed($data) && $data->isa("Data::TableData::Object::Base")) {
        return $data;
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

This document describes version 0.114 of Data::TableData::Object (from Perl distribution Data-TableData-Object), released on 2021-11-17.

=for Pod::Coverage ^$

=head1 FUNCTIONS

=head2 table

Usage:

 my $obj = table($data[ , $spec ]); # => obj

Shortcut for C<< Data::TableData::Object->new(...) >>.

=head1 METHODS

=head2 new

Usage:

 my $obj = Data::TableData::Object->new($data[ , $spec ]); # => obj

Detect the structure of C<$data> and create the appropriate
C<Data::TableData::Object::FORM> object. Note: if C<$data> is already a table
data object ("isa Data::TableData::Object::Base"), then C<$data> will be
returned as-is instead of creating a new object.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-TableData-Object>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Object>.

=head1 SEE ALSO

L<Data::TableData::Object::Base> for list of available methods.

L<Data::TableData::Object::aos>

L<Data::TableData::Object::aoaos>

L<Data::TableData::Object::aohos>

L<Data::TableData::Object::hash>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-TableData-Object>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
