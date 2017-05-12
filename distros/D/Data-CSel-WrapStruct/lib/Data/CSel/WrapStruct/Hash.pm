package Data::CSel::WrapStruct::Hash;

our $DATE = '2016-09-01'; # DATE
our $VERSION = '0.002'; # VERSION

sub new {
    my ($class, $data, $parent) = @_;
    bless [$data, $parent]; # $keys, $children
}

sub value {
    $_[0][0];
}

sub parent {
    $_[0][1];
}

sub _keys {
    if (@_ > 1) {
        $_[0][2] = $_[1];
    }
    $_[0][2];
}

sub children {
    if (@_ > 1) {
        $_[0][3] = $_[1];
    }
    $_[0][3];
}

sub length {
    scalar @{ $_[0][2] };
}

sub has_key {
    exists $_[0][0]{$_[1]};
}

sub pair_value {
    $_[0][0]{$_[1]};
}

1;
# ABSTRACT: Wrap a hashref

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::CSel::WrapStruct::Hash - Wrap a hashref

=head1 VERSION

This document describes version 0.002 of Data::CSel::WrapStruct::Hash (from Perl distribution Data-CSel-WrapStruct), released on 2016-09-01.

=head1 DESCRIPTION

Some notes:

=over

=item * The children are hash values, ordered by keys

=back

=for Pod::Coverage ^(parent|children)$

=head1 METHODS

=head2 new($hash, $parent) => obj

=head2 value() => hash

Return the hash.

=head2 length() => int

The number of keys. An empty hash will return 0.

=head2 has_key($key) => bool

Return true if hash has a key with value of C<$key>. Equivalent to:

 exists($hash->{$key})

=head2 pair_value($key) => any

Retrieve a hash pair value. Equivalent to:

 $hash->{$key}

=head2

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-CSel-WrapStruct>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-CSel-WrapStruct>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-CSel-WrapStruct>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
