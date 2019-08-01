package Data::CSel::WrapStruct;

our $DATE = '2019-07-29'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

#use Scalar::Util qw(blessed);
use Data::CSel::WrapStruct::Array;
use Data::CSel::WrapStruct::Hash;
use Data::CSel::WrapStruct::Scalar;
use Data::CSel::WrapStruct::ScalarRef;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       wrap_struct
               );

sub _wrap {
    my ($data, $parent) = @_;
    my $ref = ref($data);
    if (!$ref) {
        return Data::CSel::WrapStruct::Scalar->new(\$data, $parent);
    #} elsif (blessed $data) {
    } elsif ($ref eq 'ARRAY') {
        my $node = Data::CSel::WrapStruct::Array->new($data, $parent);
        $node->children([ map { _wrap($_, $node) } @$data]);
        return $node;
    } elsif ($ref eq 'HASH') {
        my $node = Data::CSel::WrapStruct::Hash->new($data, $parent);
        my @keys = sort keys %$data;
        $node->_keys(\@keys);
        $node->children([ map { _wrap($data->{$_}, $node) } @keys]);
        return $node;
    } elsif ($ref eq 'SCALAR') {
        return Data::CSel::WrapStruct::ScalarRef->new($data, $parent);
    } elsif ($ref eq 'JSON::PP::Boolean') {
        return Data::CSel::WrapStruct::Scalar->new($$data, $parent);
    } else {
        die "Sorry, currently can't handle ref=$ref";
    }
}

sub wrap_struct {
    my $data = shift;
    _wrap($data, undef);
}

1;
# ABSTRACT: Wrap data structure into a tree of objects suitable for use with Data::CSel

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::CSel::WrapStruct - Wrap data structure into a tree of objects suitable for use with Data::CSel

=head1 VERSION

This document describes version 0.004 of Data::CSel::WrapStruct (from Perl distribution Data-CSel-WrapStruct), released on 2019-07-29.

=head1 SYNOPSIS

 use Data::CSel qw(csel);
 use Data::CSel::WrapStruct qw(wrap_struct);

 my $data = [
     0,
     1,
     [2, ["two","dua"], {url=>"http://example.com/two.jpg"}, ["even","prime"]],
     3,
     [4, ["four","empat"], {}, ["even"]],
 ];

 my $tree = wrap_struct($data);
 my @nodes = csel(":root > * > *:nth-child(4) > *", $tree);
 my @tags = map { $_->value } @nodes; # -> ("even", "prime", "even")

Arrays are wrapped in a L<Data::CSel::WrapStruct::Array>, hashes in a
L<Data::CSel::WrapStruct::Hash>, and so on. So if you are using type selectors,
you might want to add C<Data::CSel::WrapStruct> into C<class_prefixes> for
convenience:

 my @hashes = map {$_->value} csel({class_prefixes=>["Data::CSel::WrapStruct"]}, "Hash", $tree);
 # -> ({url=>"http://example.com/two.jpg"}, {})

The wrapper objects provide some methods, e.g.:

 my @empty_hashes = map {$_->value} csel({class_prefixes=>["Data::CSel::WrapStruct"]}, "Hash[length=0]", $tree);
 # -> ({})

Refer to their respective documentation for the list of methods available.

Some more examples:

 [map {$_->value} csel({class_prefixes=>["Data::CSel::WrapStruct"]}, "Scalar[value >= 3]")]
 # -> (3, 4)

=head1 DESCRIPTION

This module provides C<wrap_struct()> which creates a tree of objects from a
generic data structure. You can then perform node selection using
L<Data::CSel>'s C<csel()>.

You can retrieve the original value of data items by calling C<value()> method
on the tree nodes.

=head1 FUNCTIONS

None exported by default, but exportable.

=head2 wrap_struct($data) => tree

Wrap a data structure using a tree of objects.

Currently cannot handle recursive structure.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-CSel-WrapStruct>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-CSel-WrapStruct>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-CSel-WrapStruct>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::CSel>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
