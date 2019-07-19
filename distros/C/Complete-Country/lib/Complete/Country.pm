package Complete::Country;

our $DATE = '2019-07-18'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);

our %SPEC;
use Exporter 'import';
our @EXPORT_OK = qw(complete_country_code);

$SPEC{complete_country_code} = {
    v => 1.1,
    summary => 'Complete from list of ISO-3166 country codes',
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        variant => {
            schema => [str=>{in=>['alpha-2','alpha-3']}],
            default => 'alpha-2',
        },
    },
    result_naked => 1,
};
sub complete_country_code {
    require Complete::Util;

    state $codes = do {
        require Locale::Codes::Country_Codes;
        my $codes = {};
        my $id2names  = $Locale::Codes::Data{'country'}{'id2names'};
        my $id2alpha2 = $Locale::Codes::Data{'country'}{'id2code'}{'alpha-2'};
        my $id2alpha3 = $Locale::Codes::Data{'country'}{'id2code'}{'alpha-3'};

        for my $id (keys %$id2names) {
            if (my $c = $id2alpha2->{$id}) {
                $codes->{'alpha-2'}{$c} = $id2names->{$id}[0];
            }
            if (my $c = $id2alpha3->{$id}) {
                $codes->{'alpha-3'}{$c} = $id2names->{$id}[0];
            }
        }
        $codes;
    };

    my %args = @_;
    my $word = $args{word} // '';
    my $variant = $args{variant} // 'alpha-2';
    my $hash = $codes->{$variant};
    return [] unless $hash;

    Complete::Util::complete_hash_key(
        word  => $word,
        hash  => $hash,
        summaries_from_hash_values => 1,
    );
}

1;
# ABSTRACT: Complete from list of ISO-3166 country codes

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Country - Complete from list of ISO-3166 country codes

=head1 VERSION

This document describes version 0.001 of Complete::Country (from Perl distribution Complete-Country), released on 2019-07-18.

=head1 SYNOPSIS

 use Complete::Country qw(complete_country_code);
 my $res = complete_country_code(word => 'V');
 # -> [qw/va vc ve vg vi vn vu/]

=head1 FUNCTIONS


=head2 complete_country_code

Usage:

 complete_country_code(%args) -> any

Complete from list of ISO-3166 country codes.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<variant> => I<str> (default: "alpha-2")

=item * B<word>* => I<str>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Country>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Country>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Country>

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
