package App::BorderStyleUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-23'; # DATE
our $DIST = 'App-BorderStyleUtils'; # DIST
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{list_border_style_modules} = {
    v => 1.1,
    summary => 'List BorderStyle modules',
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
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

        x => sub { "Table without row/column spans" },
        y => sub { "Table with row/column spans" },
        _text => sub {
            my $template = shift;
            String::Pad::pad($template =~ /,/ ? 'header' : 'cell', length($template), 'r', ' ', 1);
        },
    };

    my $table = <<'_';
ABBBBBBBBCBBBBBBBBD     #
E ,,,,,, F ,,,,,, G     #
HIIIIIIIIJIIIIIIIIK     #
L ...... M ...... N     # x
OPPPPPPPPQPPPPPPPPR     #
L ...... M ...... N     #
STTTTTTTTUTTTTTTTTV     #

ABBBBBBBBBBBCBBBBBCBBBBBD     #
E ,,,,,,,,, F ,,, F ,,, G     #
HIIIIIaIIIIIJIIIIIbIIIIIK     #
L ... M ... M ......... N     #
OPPPPPfPPPPPQPPPPPePPPPPR     #
L ......... M ... M ... N     #
OPPPPPPPPPPPQPPPPPfPPPPPR     # y
L ......... M ......... N     #
L           gPPPPPPPPPPPR     #
L           M ......... N     #
OPPPPPPPPPPPh           N     #
L ......... M           N     #
STTTTTTTTTTTUTTTTTTTTTTTV     #
_

    $table =~ s{([A-Za-z#]|([.,])+)}
               {
                   $2 ? $map->{_text}->($1) :
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

This document describes version 0.008 of App::BorderStyleUtils (from Perl distribution App-BorderStyleUtils), released on 2021-01-23.

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

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>


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

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-BorderStyleUtils/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<BorderStyle>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
