package Data::Transmute::Rules::DNS::Zone::Struct::FromSpanel;

our $DATE = '2019-08-23'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our @RULES = (
    [transmute_hash_values => {
        key_is => 'records',
        rules => [
            [transmute_array_elems => {
                rules => [
                    [rename_hash_key => {from=>'owner', to=>'name'}],
                ],
            }],
            [transmute_array_elems => {
                index_filter => sub { my %args=@_; my $data = $args{array}->[ $args{index} ]; $data->{type} eq 'MX' },
                rules => [
                    [rename_hash_key => {from=>'pref', to=>'priority'}],
                ],
            }],
        ],
    }],
);

1;
# ABSTRACT: Convert Spanel DNS zone structure to that accepted by DNS::Zone::Struct::To::BIND (Sah::Schema::dns::zone)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Transmute::Rules::DNS::Zone::Struct::FromSpanel - Convert Spanel DNS zone structure to that accepted by DNS::Zone::Struct::To::BIND (Sah::Schema::dns::zone)

=head1 VERSION

This document describes version 0.001 of Data::Transmute::Rules::DNS::Zone::Struct::FromSpanel (from Perl distribution Data-Transmute-Rules-DNS-Zone-Struct-FromSpanel), released on 2019-08-23.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Transmute-Rules-DNS-Zone-Struct-FromSpanel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Transmute-Rules-DNS-Zone-Struct-FromSpanel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Transmute-Rules-DNS-Zone-Struct-FromSpanel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
