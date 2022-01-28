package App::BorderStyleUtils;

use 5.010001;
use strict;
use utf8;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-01-27'; # DATE
our $DIST = 'App-BorderStyleUtils'; # DIST
our $VERSION = '0.015'; # VERSION

our %SPEC;

$SPEC{list_border_style_modules} = {
    v => 1.1,
    summary => 'List BorderStyle modules',
    args => {
        detail => {
            schema => 'bool*',
            summary => 'Currently does not do anything yet',
            cmdline_aliases => {l=>{}},
        },
    },
    examples => [
        {
            summary => 'List style names',
            args => {},
        },
        #{
        #    summary => 'List style names and their descriptions',
        #    args => {detail=>1},
        #},
    ],
};
sub list_border_style_modules {
    require Module::List::Tiny;

    my %args = @_;

    my @res;
    my %resmeta;

    my $mods = Module::List::Tiny::list_modules(
        "BorderStyle::", {list_modules => 1, recurse => 1});
    for my $mod (sort keys %$mods) {
        $mod =~ s/\ABorderStyle:://;
        push @res, $mod;
    }

    [200, "OK", \@res, \%resmeta];
}

$SPEC{show_border_style} = {
    v => 1.1,
    summary => 'Show example table with specified border style',
    args => {
        style => {
            schema => 'perl::borderstyle::modname_with_optional_args*',
            req => 1,
            pos => 0,
        },
    },
    examples => [
        {
            summary => 'Show the details for the ASCII::SingleLineDoubleAfterHeader border style',
            args => {style=>'ASCII::SingleLineDoubleAfterHeader'},
        },
    ],
};
sub show_border_style {
    require Module::Load::Util;
    require String::Pad;

    my %args = @_;

    my @res;
    my %resmeta;

    my $bs = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefix=>'BorderStyle'}, $args{style});

    my $map = {
        A => sub { $bs->get_border_char(0, 0) // '' },
        B => sub { $bs->get_border_char(0, 1) // '' },
        C => sub { $bs->get_border_char(0, 2) // '' },
        D => sub { $bs->get_border_char(0, 3) // '' },
        E => sub { $bs->get_border_char(1, 0) // '' },
        F => sub { $bs->get_border_char(1, 1) // '' },
        G => sub { $bs->get_border_char(1, 2) // '' },
        H => sub { $bs->get_border_char(2, 0) // '' },
        I => sub { $bs->get_border_char(2, 1) // '' },
        J => sub { $bs->get_border_char(2, 2) // '' },
        K => sub { $bs->get_border_char(2, 3) // '' },
        a => sub { $bs->get_border_char(2, 4) // '' },
        b => sub { $bs->get_border_char(2, 5) // '' },
        c => sub { $bs->get_border_char(2, 6) // '' },
        d => sub { $bs->get_border_char(2, 7) // '' },
        L => sub { $bs->get_border_char(3, 0) // '' },
        M => sub { $bs->get_border_char(3, 1) // '' },
        N => sub { $bs->get_border_char(3, 2) // '' },
        O => sub { $bs->get_border_char(4, 0) // '' },
        P => sub { $bs->get_border_char(4, 1) // '' },
        Q => sub { $bs->get_border_char(4, 2) // '' },
        R => sub { $bs->get_border_char(4, 3) // '' },
        e => sub { $bs->get_border_char(4, 4) // '' },
        f => sub { $bs->get_border_char(4, 5) // '' },
        g => sub { $bs->get_border_char(4, 6) // '' },
        h => sub { $bs->get_border_char(4, 7) // '' },
        S => sub { $bs->get_border_char(5, 0) // '' },
        T => sub { $bs->get_border_char(5, 1) // '' },
        U => sub { $bs->get_border_char(5, 2) // '' },
        V => sub { $bs->get_border_char(5, 3) // '' },

        'Ȧ' => sub { $bs->get_border_char(6, 0) // '' },
        'Ḃ' => sub { $bs->get_border_char(6, 1) // '' },
        'Ċ' => sub { $bs->get_border_char(6, 2) // '' },
        'Ḋ' => sub { $bs->get_border_char(6, 3) // '' },

        'Ṣ' => sub { $bs->get_border_char(7, 0) // '' },
        'Ṭ' => sub { $bs->get_border_char(7, 1) // '' },
        'Ụ' => sub { $bs->get_border_char(7, 2) // '' },
        'Ṿ' => sub { $bs->get_border_char(7, 3) // '' },

        'Ȯ' => sub { $bs->get_border_char(8, 0) // '' },
        'Ṗ' => sub { $bs->get_border_char(8, 1) // '' },
        'Ꝙ' => sub { $bs->get_border_char(8, 2) // '' },
        'Ṙ' => sub { $bs->get_border_char(8, 3) // '' },
        'ė' => sub { $bs->get_border_char(8, 4) // '' },
        'ḟ' => sub { $bs->get_border_char(8, 5) // '' },
        'ġ' => sub { $bs->get_border_char(8, 6) // '' },
        'ḣ' => sub { $bs->get_border_char(8, 7) // '' },

        x => sub { 'x' },
        y => sub { 'y' },
        ###

        t0 => sub { "Positions for border character" },
        t1 => sub { "Table with header row, without row/column spans" },
        t2 => sub { "Table without header row, with data rows" },
        t3 => sub { "Table with header row, but without any data row" },
        t4 => sub { "Table with row/column spans" },
        t14=> sub { "Table with multirow header" },
        t15=> sub { "Table with multirow header (separator line cut by rowspan)" },


        t5 => sub { "top border" },
        t6 => sub { "header row" },
        t7 => sub { "separator between header & data row" },
        t8 => sub { "data row" },
        t9 => sub { "separator between data rows" },
        t10=> sub { "bottom border" },
        t11=> sub { "top border (for case when there is no header row)" },
        t12=> sub { "bottom border (for case when there is header row but no data row)" },
        t13=> sub { "separator between header rows" },
        _symbols => sub {
            my $template = shift;
            if ($template =~ /\A[.,]+\z/) {
                String::Pad::pad($template =~ /,/ ? 'header' : 'cell', length($template), 'r', ' ', 1);
            }
            #die "BUG: Unknown template '$template'";
        },
    };

    my $table = <<'_';
# t0

 ---------------------------------------------
 y\x  0    1    2    3    4    5    6    7
  0  'A'  'B'  'C'  'D'                              <--- t5
  1  'E'  'F'  'G'                                   <--- t6
  2  'H'  'I'  'J'  'K'  'a'  'b'                    <--- t7
  3  'L'  'M'  'N'                                   <--- t8
  4  'O'  'P'  'Q'  'R'  'e'  'f'  'g'  'h'          <--- t9
  5  'S'  'T'  'U'  'V'                              <--- t10

  6  'Ȧ'  'Ḃ'  'Ċ'  'Ḋ'                              <--- t11
  7  'Ṣ'  'Ṭ'  'Ụ'  'Ṿ'                              <--- t12
  8  'Ȯ'  'Ṗ'  'Ꝙ'  'Ṙ'  'ė'  'ḟ'  'ġ'  'ḣ'          <--- t13
 ---------------------------------------------

ABBBBBBBBCBBBBBBBBD     #
E ,,,,,, F ,,,,,, G     #
HIIIIIIIIJIIIIIIIIK     # <--- t7
L ...... M ...... N     # t1
OPPPPPPPPQPPPPPPPPR     # <--- t9
L ...... M ...... N     #
STTTTTTTTUTTTTTTTTV     #

ȦḂḂḂḂḂḂḂḂĊḂḂḂḂḂḂḂḂḊ     #
L ...... M ...... N     # t2
OPPPPPPPPQPPPPPPPPR     # <--- t7
L ...... M ...... N     #
STTTTTTTTUTTTTTTTTV     #

ABBBBBBBBCBBBBBBBBD     #
E ,,,,,, F ,,,,,, G     # t3
ṢṬṬṬṬṬṬṬṬỤṬṬṬṬṬṬṬṬṾ     #

ABBBBBBBBBBBCBBBBBBBBCBBBBBBBBD     #
E ,,,,,,,,, F ,,,,,, F ,,,,,, G     #
HIIIIIaIIIIIJIIIIIIIIbIIIIIIIIK     # <--- t7
L ... M ... M ............... N     #
OPPPPPfPPPPPQPPPPPPPPePPPPPPPPR     # <--- t9
L ......... M ...... M ...... N     # t4
OPPPPPPPPPPPQPPPPPPPPfPPPPPPPPR     # <--- t9
L ......... M ............... N     #
L           gPPPPPPPPPPPPPPPPPR     # <--- t9
L           M ............... N     #
OPPPPPPPPPPPh                 N     # <--- t9
L ......... M                 N     #
STTTTTTTTTTTUTTTTTTTTTTTTTTTTTV     #

ABBBBBBBBBBBBBCBBBBBBBBBCBBBBBBBBBD     #
E ,,,......,, F ,,,,,,, F ,,,,,,, G     #
ȮṖṖṖṖṖṖṖṖṖṖṖṖṖꝘṖṖṖṖṖṖṖṖṖꝘṖṖṖṖṖṖṖṖṖṘ     # <--- t13
E ,,,,,,,,,,, F ,,,,,,, F ,,,,,,, G     #
ȮṖṖṖṖṖṖṖṖṖṖṖṖṖꝘṖṖṖṖṖṖṖṖṖḟṖṖṖṖṖṖṖṖṖṘ     # <--- t13
E             F ,,,,,,,,,,,,,,,,, G     #
E ,,,,,,,,,,, ġṖṖṖṖṖṖṖṖṖṖṖṖṖṖṖṖṖṖṖṘ     # <--- t13
E             F                   G     #
ȮṖṖṖṖṖṖṖṖṖṖṖṖṖḣ ,,,,,,,,,,,,,,,,, G     # <--- t13
E ,,,,,,,,,,, F                   G     #
HIIIIIIaIIIIIIJIIIIIIIIIIIIIIIIIIIK     # t14
L .... M .... M ................. N     #
OPPPPPPfPPPPPPQPPPPPPPPPePPPPPPPPPR     # <--- t9
L ........... M ....... M ....... N     #
OPPPPPPPPPPPPPQPPPPPPPPPfPPPPPPPPPR     # <--- t9
L             M ................. N     #
L ........... gPPPPPPPPPPPPPPPPPPPR     # <--- t9
L             M                   N     #
OPPPPPPPPPPPPPh ................. N     # <--- t9
L ........... M                   N     #
STTTTTTTTTTTTTUTTTTTTTTTTTTTTTTTTTV     #

ABBBBBBBBBCBBBBBBBBBBBBBBBBBBBBBCBBBBBBBBBD     #
F ,,,,,,, F       ,,,,,,,       F ,,,,,,, G     #
F         cIIIIIIIIIIaIIIIIIIIIId         G     # <--- t7
L         M ,,,,,,,, M ,,,,,,,, F         N     # t15
OPPPPPPPPPQPPPPPPPPPPQPPPPPPPPPPQPPPPPPPPPR     # <--- t9
M ,,,,,,  M ,,,,,,   M ,,,,,,   M ,,,,,,  N     #
STTTTTTTTTUTTTTTTTTTTUTTTTTTTTTTUTTTTTTTTTV     #
_

    $table =~ s{([A-Za-su-zȦḂĊḊṢṬỤṾȮṖꝘṘėḟġḣ#]|t\d+|([.,])+)}
               {
                   $2 ? $map->{_symbols}->($1) :
                       $map->{$1} ? $map->{$1}->() : $1
               }eg;

    [200, "OK", $table];
}

1;
# ABSTRACT: CLI utilities related to border styles

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BorderStyleUtils - CLI utilities related to border styles

=head1 VERSION

This document describes version 0.015 of App::BorderStyleUtils (from Perl distribution App-BorderStyleUtils), released on 2022-01-27.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<list-border-style-modules>

=item * L<show-border-style>

=back

=head1 FUNCTIONS


=head2 list_border_style_modules

Usage:

 list_border_style_modules(%args) -> [$status_code, $reason, $payload, \%result_meta]

List BorderStyle modules.

Examples:

=over

=item * List style names:

 list_border_style_modules();

Result:

 [
   200,
   "OK",
   [
     "ASCII::None",
     "ASCII::SingleLine",
     "ASCII::SingleLineDoubleAfterHeader",
     "ASCII::SingleLineHorizontalOnly",
     "ASCII::SingleLineInnerOnly",
     "ASCII::SingleLineOuterOnly",
     "ASCII::SingleLineVerticalOnly",
     "ASCII::Space",
     "ASCII::SpaceInnerOnly",
     "BoxChar::None",
     "BoxChar::SingleLine",
     "BoxChar::SingleLineHorizontalOnly",
     "BoxChar::SingleLineInnerOnly",
     "BoxChar::SingleLineOuterOnly",
     "BoxChar::SingleLineVerticalOnly",
     "BoxChar::Space",
     "BoxChar::SpaceInnerOnly",
     "Test::CustomChar",
     "Test::Labeled",
     "Test::Random",
     "Text::ANSITable::OldCompat::Default::bold",
     "Text::ANSITable::OldCompat::Default::brick",
     "Text::ANSITable::OldCompat::Default::bricko",
     "Text::ANSITable::OldCompat::Default::csingle",
     "Text::ANSITable::OldCompat::Default::double",
     "Text::ANSITable::OldCompat::Default::none_ascii",
     "Text::ANSITable::OldCompat::Default::none_boxchar",
     "Text::ANSITable::OldCompat::Default::none_utf8",
     "Text::ANSITable::OldCompat::Default::single_ascii",
     "Text::ANSITable::OldCompat::Default::single_boxchar",
     "Text::ANSITable::OldCompat::Default::single_utf8",
     "Text::ANSITable::OldCompat::Default::singleh_ascii",
     "Text::ANSITable::OldCompat::Default::singleh_boxchar",
     "Text::ANSITable::OldCompat::Default::singleh_utf8",
     "Text::ANSITable::OldCompat::Default::singlei_ascii",
     "Text::ANSITable::OldCompat::Default::singlei_boxchar",
     "Text::ANSITable::OldCompat::Default::singlei_utf8",
     "Text::ANSITable::OldCompat::Default::singleo_ascii",
     "Text::ANSITable::OldCompat::Default::singleo_boxchar",
     "Text::ANSITable::OldCompat::Default::singleo_utf8",
     "Text::ANSITable::OldCompat::Default::singlev_ascii",
     "Text::ANSITable::OldCompat::Default::singlev_boxchar",
     "Text::ANSITable::OldCompat::Default::singlev_utf8",
     "Text::ANSITable::OldCompat::Default::space_ascii",
     "Text::ANSITable::OldCompat::Default::space_boxchar",
     "Text::ANSITable::OldCompat::Default::space_utf8",
     "Text::ANSITable::OldCompat::Default::spacei_ascii",
     "Text::ANSITable::OldCompat::Default::spacei_boxchar",
     "Text::ANSITable::OldCompat::Default::spacei_utf8",
     "UTF8::Brick",
     "UTF8::BrickOuterOnly",
     "UTF8::DoubleLine",
     "UTF8::None",
     "UTF8::SingleLine",
     "UTF8::SingleLineBold",
     "UTF8::SingleLineBoldHeader",
     "UTF8::SingleLineCurved",
     "UTF8::SingleLineDoubleAfterHeader",
     "UTF8::SingleLineHorizontalOnly",
     "UTF8::SingleLineInnerOnly",
     "UTF8::SingleLineOuterOnly",
     "UTF8::SingleLineVerticalOnly",
     "UTF8::Space",
     "UTF8::SpaceInnerOnly",
   ],
   {},
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Currently does not do anything yet.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 show_border_style

Usage:

 show_border_style(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show example table with specified border style.

Examples:

=over

=item * Show the details for the ASCII::SingleLineDoubleAfterHeader border style:

 show_border_style(style => "ASCII::SingleLineDoubleAfterHeader");

Result:

 [
   200,
   "OK",
   "# Positions for border character\n\n ---------------------------------------------\n y\\x  0    1    2    3    4    5    6    7\n  0  '.'  '-'  '+'  '.'                              <--- top border\n  1  '|'  '|'  '|'                                   <--- header row\n  2  '+'  '='  '+'  '+'  '+'  '+'                    <--- separator between header & data row\n  3  '|'  '|'  '|'                                   <--- data row\n  4  '+'  '-'  '+'  '+'  '+'  '+'  '+'  '+'          <--- separator between data rows\n  5  '`'  '-'  '+'  '''                              <--- bottom border\n\n  6  '.'  '-'  '+'  '.'                              <--- top border (for case when there is no header row)\n  7  '`'  '-'  '+'  '''                              <--- bottom border (for case when there is header row but no data row)\n  8  '+'  '-'  '+'  '+'  '+'  '+'  '+'  '+'          <--- separator between header rows\n ---------------------------------------------\n\n.--------+--------.     #\n| header | header |     #\n+========+========+     # <--- separator between header & data row\n| cell   | cell   |     # Table with header row, without row/column spans\n+--------+--------+     # <--- separator between data rows\n| cell   | cell   |     #\n`--------+--------'     #\n\n.--------+--------.     #\n| cell   | cell   |     # Table without header row, with data rows\n+--------+--------+     # <--- separator between header & data row\n| cell   | cell   |     #\n`--------+--------'     #\n\n.--------+--------.     #\n| header | header |     # Table with header row, but without any data row\n`--------+--------'     #\n\n.-----------+--------+--------.     #\n| header    | header | header |     #\n+=====+=====+========+========+     # <--- separator between header & data row\n| cel | cel | cell            |     #\n+-----+-----+--------+--------+     # <--- separator between data rows\n| cell      | cell   | cell   |     # Table with row/column spans\n+-----------+--------+--------+     # <--- separator between data rows\n| cell      | cell            |     #\n|           +-----------------+     # <--- separator between data rows\n|           | cell            |     #\n+-----------+                 |     # <--- separator between data rows\n| cell      |                 |     #\n`-----------+-----------------'     #\n\n.-------------+---------+---------.     #\n| header      | header  | header  |     #\n+-------------+---------+---------+     # <--- separator between header rows\n| header      | header  | header  |     #\n+-------------+---------+---------+     # <--- separator between header rows\n|             | header            |     #\n| header      +-------------------+     # <--- separator between header rows\n|             |                   |     #\n+-------------+ header            |     # <--- separator between header rows\n| header      |                   |     #\n+======+======+===================+     # Table with multirow header\n| cell | cell | cell              |     #\n+------+------+---------+---------+     # <--- separator between data rows\n| cell        | cell    | cell    |     #\n+-------------+---------+---------+     # <--- separator between data rows\n|             | cell              |     #\n| cell        +-------------------+     # <--- separator between data rows\n|             |                   |     #\n+-------------+ cell              |     # <--- separator between data rows\n| cell        |                   |     #\n`-------------+-------------------'     #\n\n.---------+---------------------+---------.     #\n| header  |       header        | header  |     #\n|         +==========+==========+         |     # <--- separator between header & data row\n|         | header   | header   |         |     # Table with multirow header (separator line cut by rowspan)\n+---------+----------+----------+---------+     # <--- separator between data rows\n| header  | header   | header   | header  |     #\n`---------+----------+----------+---------'     #\n",
   {},
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<style>* => I<perl::borderstyle::modname_with_optional_args>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-BorderStyleUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BorderStyleUtils>.

=head1 SEE ALSO

L<BorderStyle>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BorderStyleUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
