package Data::Serializer::Data::Dump;

our $DATE = '2015-11-01'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent 'Data::Serializer';
use Data::Dump qw(dump);

sub serialize {
    my ($self, $val) = @_;
    dump($val);
}

sub deserialize {
    my ($self, $val) = @_;

    my $res = eval $val;
    die "Data::Serializer error: $@\twhile evaluating:\n $val" if $@;
    $res;
}

1;
# ABSTRACT: Bridge between Data::Serializer and Data::Dump

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Serializer::Data::Dump - Bridge between Data::Serializer and Data::Dump

=head1 VERSION

This document describes version 0.01 of Data::Serializer::Data::Dump (from Perl distribution Data-Serializer-Data-Dump), released on 2015-11-01.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

L<Data::Serializer>

L<Data::Dump>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Serializer-Data-Dump>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Serializer-Data-Dump>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Serializer-Data-Dump>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
