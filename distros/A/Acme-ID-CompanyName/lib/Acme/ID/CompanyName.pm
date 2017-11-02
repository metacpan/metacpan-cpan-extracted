package Acme::ID::CompanyName;

our $DATE = '2017-10-26'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(gen_generic_id_company_names);

our %SPEC;

our @Words = qw(
alam
alami
abad
abadi
aman
ampuh
amanah
amanat

eka
eterna

bangsa
berjaya
berdikari
berdiri
bersama
bersatu
bersaudara

dika
delta
dunia

eterna
elegan

fajar
forsa
fortuna

global
graha

inti
internasional
indonesia
indotama

jasa
jaya

karya
kurnia

lestari

mulia
mandala
makmur
maju
milenia
milenial
multi
mitra

nusantara

oasis
optima
optimum
optimus
obor
orisinal
optimis

perusahaan
pertama
pratama
prima
putra

sarana
sejahtera
sejati
sentosa
santosa
sintesa
sintesis
sumber

tentram
tenteram
tunggal
tren

umum
utara
utama
);

my %Per_Letter_Words;
for my $letter ("a".."z") {
    for (@Words) {
        /(.).+/ or die;
        push @{ $Per_Letter_Words{$1} }, $_;
    }
}

our @Prefixes = qw(
indo
multi
mitra
dwi
eka
tri
tetra
panca
);

our @Suffixes = qw(
indo
tama
);

## some more specific words
# elektrik
# industri
# teknologi
# otomatis
# media

## some more specific prefixes/suffixes
# tekno-
# oto-
# media-

$SPEC{gen_generic_id_company_names} = {
    v => 1.1,
    summary => 'Generate nice-sounding, generic Indonesian company names',
    args => {
        type => {
            schema => 'str*',
            default => 'PT',
            summary => 'Just a string to be prepended before the name',
            cmdline_aliases => {t=>{}},
        },
        num_names => {
            schema => ['int*', min=>0],
            default => 1,
            cmdline_aliases => {n=>{}},
        },
        num_words => {
            schema => ['int*', min=>1],
            default => 3,
            cmdline_aliases => {w=>{}},
        },
        add_prefixes => {
            schema => ['bool*'],
            default => 1,
        },
        add_suffixes => {
            schema => ['bool*'],
            default => 1,
        },
        # XXX option to use some more specific words & suffixes/prefixes
        desired_initials => {
            schema => ['str*', min_len=>1, match=>qr/\A[A-Za-z]+\z/],
        },
    },
    result_naked => 1,
};
sub gen_generic_id_company_names {
    my %args = @_;

    my $type = $args{type} // 'PT';
    my $num_names = $args{num_names} // 1;
    my $num_words = $args{num_words} // 3;
    my $desired_initials = lc($args{desired_initials} // "");
    my $add_prefixes = $args{add_prefixes} // 1;
    my $add_suffixes = $args{add_suffixes} // 1;

    $num_words = length($desired_initials)
        if $num_words < length($desired_initials);

    my @res;
    my $name_tries = 0;
    for my $i (1..$num_names) {
        die "Can't produce that many unique company names"
            if ++$name_tries > 5*$num_names;

        my @words;
        my $word_tries = 0;
        my $has_added_prefix;
        my $has_added_suffix;
        for my $j (1..$num_words) {
            die "Can't produce a company name that satisfies requirements"
                if ++$word_tries > 1000;

            my $word;
            if (length($desired_initials) >= $j and
                    my $letter = substr($desired_initials, $j-1, 1)) {
                die "There are no words that start with '$letter'"
                    unless $Per_Letter_Words{$letter};
                $word = $Per_Letter_Words{$letter}->[
                    @{ $Per_Letter_Words{$letter} } * rand()
                ];
            } else {
                $word = $Words[@Words * rand()];
            }

          ADD_PREFIX:
            {
                last unless $add_prefixes;
                last unless !$has_added_prefix && rand()*$num_words*6 < 1;
                my $prefix = $Prefixes[@Prefixes * rand()];

                # avoid prefixing e.g. 'indo-' to 'indonesia'
                last if $word =~ /^\Q$prefix\E/;

                # amalgamate letter
                if (substr($prefix, -1, 1) eq substr($word, 0, 1)) {
                    $word =~ s/^.//;
                }

                $word = "$prefix$word";
                $has_added_prefix++;
            }

          ADD_SUFFIX:
            {
                last unless $add_suffixes;
                last unless !$has_added_suffix && rand()*$num_words*3 < 1;
                my $suffix = $Suffixes[@Suffixes * rand()];

                # avoid suffixing e.g. '-tama' to 'pertama'
                last if $word =~ /\Q$suffix\E$/;

                # amalgamate letter
                if (substr($word, -1, 1) eq substr($suffix, 0, 1)) {
                    $word =~ s/.$//;
                }

                $word = "$word$suffix";
                $has_added_suffix++;
            }

            # avoid duplicate words
            redo if grep { $word eq $_ } @words;

            push @words, ucfirst $word;
        }
        my $name = join(" ", $type, @words);

        # avoid duplicate name
        redo if grep { $name eq $_ } @res;

        push @res, $name;

    }
    return \@res;
}

1;
# ABSTRACT: Generate nice-sounding, generic Indonesian company names

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::ID::CompanyName - Generate nice-sounding, generic Indonesian company names

=head1 VERSION

This document describes version 0.003 of Acme::ID::CompanyName (from Perl distribution Acme-ID-CompanyName), released on 2017-10-26.

=head1 SYNOPSIS

 use Acme::ID::CompanyName qw(gen_generic_id_company_names);
 my $names = gen_generic_id_company_names(num_names => 2);

Sample output:

 [
   "Sentosa Jaya Abadi",
   "Putra Utama Global",
 ]

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 gen_generic_id_company_names

Usage:

 gen_generic_id_company_names(%args) -> any

Generate nice-sounding, generic Indonesian company names.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<add_prefixes> => I<bool> (default: 1)

=item * B<add_suffixes> => I<bool> (default: 1)

=item * B<desired_initials> => I<str>

=item * B<num_names> => I<int> (default: 1)

=item * B<num_words> => I<int> (default: 3)

=item * B<type> => I<str> (default: "PT")

Just a string to be prepended before the name.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-ID-CompanyName>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-ID-CompanyName>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-ID-CompanyName>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
