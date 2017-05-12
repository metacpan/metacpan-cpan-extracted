package App::LinguaSUUtils;

our $DATE = '2016-02-08'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::LinguaCommonUtils qw(%arg_words %arg_nums);

our %SPEC;

$SPEC{num_to_word} = {
    v => 1.1,
    summary => 'Convert number (123) to word ("saratus dua puluh tilu")',
    'x.no_index' => 1,
    args => {
        %arg_nums,
    },
    result_naked => 1,
};
sub num_to_word {
    require Lingua::SU::Nums2Words;

    my %args = @_;

    [map {Lingua::SU::Nums2Words::nums2words($_)} @{ $args{nums} }];
}

1;
# ABSTRACT: Command-line utilities related to the Sundanese language

__END__

=pod

=encoding UTF-8

=head1 NAME

App::LinguaSUUtils - Command-line utilities related to the Sundanese language

=head1 VERSION

This document describes version 0.01 of App::LinguaSUUtils (from Perl distribution App-LinguaSUUtils), released on 2016-02-08.

=head1 SYNOPSIS

This distribution provides the following command-line utilities:

=over

=item * L<su-n2w>

=back

=head1 DESCRIPTION

This distribution will become a collection of CLI utilities related to the
Sundanese language. Currently it contains very little and the collection will be
expanded in subsequent releases.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-LinguaSUUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-LinguaSUUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-LinguaSUUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
