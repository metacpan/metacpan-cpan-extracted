package Complete::Nutrient;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-30'; # DATE
our $DIST = 'Complete-Nutrient'; # DIST
our $VERSION = '0.002'; # VERSION

use Complete::Common qw(:all);
use Exporter qw(import);

our @EXPORT_OK = qw(
                       complete_nutrient_symbol
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to nutrients',
};

my $nutrients;
my $symbol_replace_map;
$SPEC{'complete_nutrient_symbol'} = {
    v => 1.1,
    summary => 'Complete from list of nutrient symbols',
    description => <<'MARKDOWN',

List of nutrients is taken from <pm:TableData::Health::Nutrient>.

MARKDOWN
    args => {
        %arg_word,
        filter => {
            schema => 'code*',
            description => <<'MARKDOWN',

Filter coderef will be passed the nutrient hashref row and should return true
when the nutrient is to be included.

MARKDOWN
        },
        lang => {
            summary => 'Choose language for summary',
            schema => ['str*', in=>[qw/eng ind/]],
            default => 'eng',
        },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_nutrient_symbol {
    my %args = @_;

    my $lang = $args{lang} // 'eng';
    my $filter = $args{filter};

    unless ($nutrients) {
        require TableData::Health::Nutrient;
        my $td = TableData::Health::Nutrient->new;
        my @nutrients = $td->get_all_rows_hashref;
        $nutrients = \@nutrients;

        $symbol_replace_map = {};
        for my $row (@nutrients) {
            next unless defined $row->{aliases} && length($row->{aliases});
            $symbol_replace_map->{ $row->{symbol} } = [split /,/, lc($row->{aliases})];
        }
    }

    my $symbols = [];
    my $summaries = [];
    for my $n (@$nutrients) {
        if ($filter) { next unless $filter->($n) }
        push @$symbols, $n->{symbol};
        push @$summaries, $lang eq 'ind' ? $n->{ind_name} : $n->{eng_name};
    }

    require Complete::Util;
    Complete::Util::complete_array_elem(
        word=>$args{word},
        array=>$symbols,
        replace_map=>$symbol_replace_map,
        summaries=>$summaries);
}

1;
# ABSTRACT: Completion routines related to nutrients

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Nutrient - Completion routines related to nutrients

=head1 VERSION

This document describes version 0.002 of Complete::Nutrient (from Perl distribution Complete-Nutrient), released on 2024-05-30.

=for Pod::Coverage .+

=head1 FUNCTIONS


=head2 complete_nutrient_symbol

Usage:

 complete_nutrient_symbol(%args) -> array

Complete from list of nutrient symbols.

List of nutrients is taken from L<TableData::Health::Nutrient>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filter> => I<code>

Filter coderef will be passed the nutrient hashref row and should return true
when the nutrient is to be included.

=item * B<lang> => I<str> (default: "eng")

Choose language for summary.

=item * B<word>* => I<str> (default: "")

Word to complete.


=back

Return value:  (array)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Nutrient>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Nutrient>.

=head1 SEE ALSO

L<Complete>

Other C<Complete::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Nutrient>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
