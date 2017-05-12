package CHI::Serializer::Sereal;

our $DATE = '2014-06-29'; # DATE
our $VERSION = '0.01'; # VERSION

use Moo;
#use strict;   # implied by Moo
#use warnings; # implied by Moo

use Sereal qw(encode_sereal decode_sereal);

sub serialize {
    return encode_sereal($_[1]);
}

sub deserialize {
    return decode_sereal($_[1]);
}

sub serializer {
    return 'Sereal';
}

1;
# ABSTRACT: Sereal serializer for CHI

__END__

=pod

=encoding UTF-8

=head1 NAME

CHI::Serializer::Sereal - Sereal serializer for CHI

=head1 VERSION

This document describes version 0.01 of CHI::Serializer::Sereal (from Perl distribution CHI-Serializer-Sereal), released on 2014-06-29.

=for Pod::Coverage ^(serialize|deserialize|serializer)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CHI-Serializer-Sereal>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-CHI-Serializer-Sereal>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CHI-Serializer-Sereal>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
