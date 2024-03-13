package App::BPOMUtils::RPO::Ingredients;

use 5.010001;
use locale;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';
use POSIX 'setlocale', 'LC_ALL';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-26'; # DATE
our $DIST = 'App-BPOMUtils-RPO-Ingredients'; # DIST
our $VERSION = '0.006'; # VERSION

our @EXPORT_OK = qw(
                       bpom_rpo_ingredients_group_for_label
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
};

sub _fmtfloat_max_precision {
    my ($max_precision, $num) = @_;
    my $res = sprintf "%.${max_precision}f", $num;
    $res =~ s/0+\z//;
    $res =~ s/[.,]\z//;
    $res;
}

$SPEC{bpom_rpo_ingredients_group_for_label} = {
    v => 1.1,
    summary => 'Group ingredients suitable for food label',
    description => <<'_',

This utility accepts a CSV data from stdin. The CSV must be formatted like this:

    Ingredient,%weight,"Ingredient name for label (Indonesian)","Ingredient name for label (English)","QUID?","Note (Indonesian)","Note (English)","Ingredient group for label (Indonesian)","Ingredient group for label (English)"
    Air,78.48,Air,Water,,
    Gula,16.00,Gula,Sugar,,"mengandung pengawet sulfit","contains sulfite preservative",
    "Nata de coco",5.00,"Nata de coco","Nata de coco",1,"mengandung pengawet sulfit","contains sulfit preservative",
    "Asam sitrat",0.25,"Asam sitrat","Citric acid",,,,"Pengatur keasaman","Acidity regulator"
    "Asam malat",0.10,"Asam malat","Malic acid",,,,"Pengatur keasaman","Acidity regulator"
    "Grape flavor",0.10,Anggur,Grape,,,,"Perisa sintetik","Synthetic flavoring"
    "Tea flavor",0.05,Teh,Tea,,,,"Perisa sintetik","Synthetic flavoring"
    "Natrium benzoat",0.02,"Natrium benzoat","Sodium benzoate",,,,Pengawet,Preservative

It can then group the ingredients based on the ingredient group and generate
this (for Indonesian, `--lang ind`):

    Ingredient,%weight
    Air,78.48
    Gula (mengandung pengawet sulfit),16.00
    "Nata de coco 5% (mengandung pengawet sulfit)",5.00
    "Pengatur keasaman (Asam sitrat, Asam malat)",0.35
    "Perisa sintetik (Anggur, Teh)",0.15
    "Pengawet Natrium benzoat",0.02

And for English, `--lang eng`:

    Ingredient,%weight
    Water,78.48
    Sugar (contains sulfite preservative),16.00
    "Nata de coco 5% (contains sulfite preservative)",5.00
    "Acidity regulator (Citric acid, Malic acid)",0.35
    "Synthetic flavoring (Grape, Tea)",0.15
    "Preservative Sodium benzoate",0.02

_
    args => {
        lang => {
            schema => ['str*', in=>['eng','ind']],
            default => 'ind',
        },
        #weight_precision => {
        #    schema => ['uint*'],
        #    default => 5,
        #},
        quid_precision => {
            schema => ['uint*'], # TODO: support -1 precision (e.g. 11% -> 10%)
            default => 4,
        },
    },
};
sub bpom_rpo_ingredients_group_for_label {
    require Text::CSV;

    my %args = @_;

    my $csv = Text::CSV->new({binary=>1, auto_diag=>1});
    my @rows;
    while (my $row = $csv->getline(\*STDIN)) { push @rows, $row }

    if ($args{lang} eq 'ind') {
        POSIX::setlocale(LC_ALL, "id_ID.UTF-8") or die "Can't set locale to id_ID.UTF-8";
    } else {
    }

    my %weights; # key = ingredient name, value = weight
    my %ingredients; # key = name, value = { weight=>, items=> }
    for my $n (1 .. $#rows) {
        my $row = $rows[$n];
        my ($ingredient0, $weight, $ind_ingredient, $eng_ingredient, $quid, $ind_note, $eng_note, $ind_group, $eng_group) = @$row;
        my ($label_ingredient0, $note, $group) = $args{lang} eq 'eng' ? ($eng_ingredient, $eng_note, $eng_group) : ($ind_ingredient, $ind_note, $ind_group);

        my $label_ingredient = join(
            " ",
            $label_ingredient0,
            ($quid ? (_fmtfloat_max_precision($args{quid_precision}, $weight) . '%') : ()),
            ($note ? ("($note)") : ()),
        );

        my $has_group;
        if ($group) { $has_group++ } else { $group = $label_ingredient }
        $weights{$ingredient0} = $weight;
        $ingredients{ $group } //= {has_group=>$has_group, ingredient0 => $ingredient0};
        $ingredients{ $group }{weight} //= 0;
        $ingredients{ $group }{items} //= [];
        $ingredients{ $group }{items0} //= [];
        $ingredients{$group}{weight} += $weight;
        push @{ $ingredients{$group}{items} }, $label_ingredient;
        push @{ $ingredients{$group}{items0} }, $ingredient0;
    }

    @rows = ();
    my $i = 0;
    for my $group (sort { ($ingredients{$b}{weight} <=> $ingredients{$a}{weight}) || ($a cmp $b) } keys %ingredients) {
        $i++;
        my $ingredient = $group;
        if ($ingredients{$group}{has_group}) {
            $ingredient .= " ";
            if (@{ $ingredients{$group}{items} } > 1) {
                my @items = map { $ingredients{$group}{items}[$_] }
                    sort { $weights{ $ingredients{$group}{items0}[$b] } <=> $weights{ $ingredients{$group}{items0}[$b] } } 0 .. $#{ $ingredients{$group}{items} };
                $ingredient .= "(" . join(", ", @items) . ")";
            } else {
                $ingredient .= $ingredients{$group}{items}[0];
            }
        }
        push @rows, [$ingredient, $ingredients{$group}{weight}];
    }

    [200, "OK", \@rows, {'table.fields'=>['Ingredient', '%weight']}];
}

1;
# ABSTRACT: Group ingredients suitable for food label

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BPOMUtils::RPO::Ingredients - Group ingredients suitable for food label

=head1 VERSION

This document describes version 0.006 of App::BPOMUtils::RPO::Ingredients (from Perl distribution App-BPOMUtils-RPO-Ingredients), released on 2024-02-26.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes CLI utilities related to helping with Processed Food
Registration (RPO - Registrasi Pangan Olahan), particularly with regards to
ingredients.

=over

=item * L<bpom-rpo-ingredients-group-for-label>

=back

=head1 FUNCTIONS


=head2 bpom_rpo_ingredients_group_for_label

Usage:

 bpom_rpo_ingredients_group_for_label(%args) -> [$status_code, $reason, $payload, \%result_meta]

Group ingredients suitable for food label.

This utility accepts a CSV data from stdin. The CSV must be formatted like this:

 Ingredient,%weight,"Ingredient name for label (Indonesian)","Ingredient name for label (English)","QUID?","Note (Indonesian)","Note (English)","Ingredient group for label (Indonesian)","Ingredient group for label (English)"
 Air,78.48,Air,Water,,
 Gula,16.00,Gula,Sugar,,"mengandung pengawet sulfit","contains sulfite preservative",
 "Nata de coco",5.00,"Nata de coco","Nata de coco",1,"mengandung pengawet sulfit","contains sulfit preservative",
 "Asam sitrat",0.25,"Asam sitrat","Citric acid",,,,"Pengatur keasaman","Acidity regulator"
 "Asam malat",0.10,"Asam malat","Malic acid",,,,"Pengatur keasaman","Acidity regulator"
 "Grape flavor",0.10,Anggur,Grape,,,,"Perisa sintetik","Synthetic flavoring"
 "Tea flavor",0.05,Teh,Tea,,,,"Perisa sintetik","Synthetic flavoring"
 "Natrium benzoat",0.02,"Natrium benzoat","Sodium benzoate",,,,Pengawet,Preservative

It can then group the ingredients based on the ingredient group and generate
this (for Indonesian, C<--lang ind>):

 Ingredient,%weight
 Air,78.48
 Gula (mengandung pengawet sulfit),16.00
 "Nata de coco 5% (mengandung pengawet sulfit)",5.00
 "Pengatur keasaman (Asam sitrat, Asam malat)",0.35
 "Perisa sintetik (Anggur, Teh)",0.15
 "Pengawet Natrium benzoat",0.02

And for English, C<--lang eng>:

 Ingredient,%weight
 Water,78.48
 Sugar (contains sulfite preservative),16.00
 "Nata de coco 5% (contains sulfite preservative)",5.00
 "Acidity regulator (Citric acid, Malic acid)",0.35
 "Synthetic flavoring (Grape, Tea)",0.15
 "Preservative Sodium benzoate",0.02

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<lang> => I<str> (default: "ind")

(No description)

=item * B<quid_precision> => I<uint> (default: 4)

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-BPOMUtils-RPO-Ingredients>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BPOMUtils-RPO-Ingredients>.

=head1 SEE ALSO

L<https://registrasipangan.pom.go.id>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BPOMUtils-RPO-Ingredients>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
