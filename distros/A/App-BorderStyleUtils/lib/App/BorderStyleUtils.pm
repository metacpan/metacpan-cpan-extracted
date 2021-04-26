package App::BorderStyleUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-24'; # DATE
our $DIST = 'App-BorderStyleUtils'; # DIST
our $VERSION = '0.012'; # VERSION

use 5.010001;
use strict;
use utf8;
use warnings;
use Log::ger;

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

        x => sub { 'x' },
        y => sub { 'y' },
        ###

        t0 => sub { "Positions for border character" },
        t1 => sub { "Table with header row, without row/column spans" },
        t2 => sub { "Table without header row, with data rows" },
        t3 => sub { "Table with header row, but without any data row" },
        t4 => sub { "Table with row/column spans" },
        t5 => sub { "top border" },
        t6 => sub { "header row" },
        t7 => sub { "separator between header & data row" },
        t8 => sub { "data row" },
        t9 => sub { "separator between data rows" },
        t10=> sub { "bottom border" },
        t11=> sub { "top border (for case when there is no header row)" },
        t12=> sub { "bottom border (for case when there is header row but no data row)" },
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
 ---------------------------------------------

ABBBBBBBBCBBBBBBBBD     #
E ,,,,,, F ,,,,,, G     #
HIIIIIIIIJIIIIIIIIK     #
L ...... M ...... N     # t1
OPPPPPPPPQPPPPPPPPR     #
L ...... M ...... N     #
STTTTTTTTUTTTTTTTTV     #

ȦḂḂḂḂḂḂḂḂĊḂḂḂḂḂḂḂḂḊ     #
L ...... M ...... N     # t2
OPPPPPPPPQPPPPPPPPR     #
L ...... M ...... N     #
STTTTTTTTUTTTTTTTTV     #

ABBBBBBBBCBBBBBBBBD     #
E ,,,,,, F ,,,,,, G     # t3
ṢṬṬṬṬṬṬṬṬỤṬṬṬṬṬṬṬṬṾ     #

ABBBBBBBBBBBCBBBBBCBBBBBD     #
E ,,,,,,,,, F ,,, F ,,, G     #
HIIIIIaIIIIIJIIIIIbIIIIIK     #
L ... M ... M ......... N     #
OPPPPPfPPPPPQPPPPPePPPPPR     #
L ......... M ... M ... N     #
OPPPPPPPPPPPQPPPPPfPPPPPR     # t4
L ......... M ......... N     #
L           gPPPPPPPPPPPR     #
L           M ......... N     #
OPPPPPPPPPPPh           N     #
L ......... M           N     #
STTTTTTTTTTTUTTTTTTTTTTTV     #
_

    $table =~ s{([A-Za-su-zȦḂĊḊṢṬỤṾ#]|t\d+|([.,])+)}
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

This document describes version 0.012 of App::BorderStyleUtils (from Perl distribution App-BorderStyleUtils), released on 2021-04-24.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<list-border-style-modules>

=item * L<show-border-style>

=back

=head1 FUNCTIONS


=head2 list_border_style_modules

Usage:

 list_border_style_modules(%args) -> [status, msg, payload, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 show_border_style

Usage:

 show_border_style(%args) -> [status, msg, payload, meta]

Show example table with specified border style.

Examples:

=over

=item * Show the details for the ASCII::SingleLineDoubleAfterHeader border style:

 show_border_style(style => "ASCII::SingleLineDoubleAfterHeader");

Result:

 [
   200,
   "OK",
   "# Positions for border character\n\n ---------------------------------------------\n y\\x  0    1    2    3    4    5    6    7\n  0  '.'  '-'  '+'  '.'                              <--- top border\n  1  '|'  '|'  '|'                                   <--- header row\n  2  '+'  '='  '+'  '+'  '+'  '+'                    <--- separator between header & data row\n  3  '|'  '|'  '|'                                   <--- data row\n  4  '+'  '-'  '+'  '+'  '+'  '+'  '+'  '+'          <--- separator between data rows\n  5  '`'  '-'  '+'  '''                              <--- bottom border\n\n  6  ''  ''  ''  ''                              <--- top border (for case when there is no header row)\n  7  ''  ''  ''  ''                              <--- bottom border (for case when there is header row but no data row)\n ---------------------------------------------\n\n.--------+--------.     #\n| header | header |     #\n+========+========+     #\n| cell   | cell   |     # Table with header row, without row/column spans\n+--------+--------+     #\n| cell   | cell   |     #\n`--------+--------'     #\n\n     #\n| cell   | cell   |     # Table without header row, with data rows\n+--------+--------+     #\n| cell   | cell   |     #\n`--------+--------'     #\n\n.--------+--------.     #\n| header | header |     # Table with header row, but without any data row\n     #\n\n.-----------+-----+-----.     #\n| header    | hea | hea |     #\n+=====+=====+=====+=====+     #\n| cel | cel | cell      |     #\n+-----+-----+-----+-----+     #\n| cell      | cel | cel |     #\n+-----------+-----+-----+     # Table with row/column spans\n| cell      | cell      |     #\n|           +-----------+     #\n|           | cell      |     #\n+-----------+           |     #\n| cell      |           |     #\n`-----------+-----------'     #\n",
   {},
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<style>* => I<perl::borderstyle::modname_with_optional_args>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-BorderStyleUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BorderStyleUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BorderStyleUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<BorderStyle>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
