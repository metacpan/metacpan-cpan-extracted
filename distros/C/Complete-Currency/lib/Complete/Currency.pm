package Complete::Currency;

our $DATE = '2019-07-18'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);

our %SPEC;
use Exporter 'import';
our @EXPORT_OK = qw(complete_currency_code);

$SPEC{complete_currency_code} = {
    v => 1.1,
    summary => 'Complete from list of ISO-4217 currency codes',
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
};
sub complete_currency_code {
    require Complete::Util;

    state $codes = do {
        require Locale::Codes::Currency_Codes;
        my $codes = {};
        my $id2names = $Locale::Codes::Data{'currency'}{'id2names'};
        my $id2alpha = $Locale::Codes::Data{'currency'}{'id2code'}{'alpha'};

        for my $id (keys %$id2names) {
            if (my $c = $id2alpha->{$id}) {
                $codes->{'alpha'}{$c} = $id2names->{$id}[0];
            }
        }
        $codes;
    };

    my %args = @_;
    my $word = $args{word} // '';
    my $hash = $codes->{alpha};
    return [] unless $hash;

    Complete::Util::complete_hash_key(
        word  => $word,
        hash  => $hash,
        summaries_from_hash_values => 1,
    );
}

1;
# ABSTRACT: Complete from list of ISO-4217 currency codes

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Currency - Complete from list of ISO-4217 currency codes

=head1 VERSION

This document describes version 0.001 of Complete::Currency (from Perl distribution Complete-Currency), released on 2019-07-18.

=head1 SYNOPSIS

 use Complete::Currency qw(complete_currency_code);
 my $res = complete_currency_code(word => 'V');
 # -> [qw/VEF VND VUV/]

=head1 FUNCTIONS


=head2 complete_currency_code

Usage:

 complete_currency_code(%args) -> any

Complete from list of ISO-4217 currency codes.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Currency>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Currency>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Currency>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete::Country>

L<Complete::Language>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
