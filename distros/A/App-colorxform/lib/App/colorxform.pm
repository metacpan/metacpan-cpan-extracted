package App::colorxform;

our $DATE = '2018-09-07'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

sub _color_name_to_fg_code {
    my $name = lc(shift);
    if    ($name eq 'black'       ) { return 30 }
    elsif ($name eq 'red'         ) { return 31 }
    elsif ($name eq 'green'       ) { return 32 }
    elsif ($name eq 'yellow'      ) { return 33 }
    elsif ($name eq 'blue'        ) { return 34 }
    elsif ($name eq 'magenta'     ) { return 35 }
    elsif ($name eq 'cyan'        ) { return 36 }
    elsif ($name eq 'white' || $name eq 'grey' || $name eq 'gray') { return 37 }
    elsif ($name =~ /\A(bold|bright) black\z/   ) { return 90 }
    elsif ($name =~ /\A(bold|bright) red\z/     ) { return 91 }
    elsif ($name =~ /\A(bold|bright) green\z/   ) { return 92 }
    elsif ($name =~ /\A(bold|bright) yellow\z/  ) { return 93 }
    elsif ($name =~ /\A(bold|bright) blue\z/    ) { return 94 }
    elsif ($name =~ /\A(bold|bright) magenta\z/ ) { return 95 }
    elsif ($name =~ /\A(bold|bright) cyan\z/    ) { return 96 }
    elsif ($name =~ /\A(bold|bright) white\z/   ) { return 97 }
    undef;
}

sub _color_name_to_bg_code {
    my $code = _color_name_to_fg_code(@_);
    $code ? $code+10 : undef;
}

$SPEC{'colorxform'} = {
    v => 1.1,
    summary => 'Transform colors on the CLI',
    description => <<'_',

Some CLI programs output horrible colors (e.g. hard to read on terminal with
black background) and the colors are either uncustomizable or cumbersome to
customize. This is where `colorxform` comes in. You pipe the output and it will
replace some colors with another, per your specification.

An example, put this in your `~/.config/colorxform.conf`:

    [profile=ledger]
    fg_transforms = {"blue":"#18b2b2", "red":"bold red"}

then:

    % ledger -f myledger.dat --color --force-color balance | colorxform -P ledger

You can create a shell alias for convenience:

    % function ledger() { `which ledger` --color --force-color "$@" | colorxform -P ledger; }

so you can just issue this to get the colors transformed:

    % ledger -f myledger.dat balance

_
    args => {
        fg_transforms => {
            schema => 'hash*',
            default => {},
            description => <<'_',

List of foreground colors to replace with other colors. You can specify color
code using RGB code (e.g. `#123456`) or color names like those recognized by
<pm:Term::ANSIColor> (e.g. `blue` or `bold blue`).

_
        },
        bg_transforms => {
            schema => 'hash*',
            default => {},
            description => <<'_',

List of background colors to replace with other colors. You can specify color
using RGB code (e.g. `#123456`) or color names like those recognized by
<pm:Term::ANSIColor> (e.g. `blue` or `bold blue`).

_
        },
    },
};
sub colorxform {
    my %args = @_;

    my %codemaps;

    for my $k (keys %{$args{fg_transforms}}) {
        my $code;
        {
            $code = _color_name_to_fg_code($k);
            last if defined $code;
            # XXX support transforming 8-bit and 24-bit input colors
            die "Unrecognized foreground color name/code '$k'";
        }
        my $xformcode;
        {
            my $v = $args{fg_transforms}{$k};
            $xformcode = _color_name_to_fg_code($v);
            last if defined $xformcode;
            if ($v =~ /\A#([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})\z/) {
                $xformcode = sprintf "38;2;%d;%d;%d",
                    hex($1), hex($2), hex($3);
                last;
            }
            die "Unrecognized foreground transform color name/code '$v'";
        }
        $codemaps{$code} = $xformcode;
    }

    for my $k (keys %{$args{bg_transforms}}) {
        my $code;
        {
            $code = _color_name_to_bg_code($k);
            last if defined $code;
            # XXX support transforming 8-bit and 24-bit input colors
            die "Unrecognized background color name/code '$k'";
        }
        my $xformcode;
        {
            my $v = $args{bg_transforms}{$k};
            $xformcode = _color_name_to_bg_code($v);
            last if defined $xformcode;
            if ($v =~ /\A#([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})\z/) {
                $xformcode = sprintf "48;2;%d;%d;%d",
                    hex($1), hex($2), hex($3);
                last;
            }
            die "Unrecognized background transform color name/code '$v'";
        }
        $codemaps{$code} = $xformcode;
    }

    my $transform = sub {
        my $codes = shift;
        my @codes;
        while ($codes =~ /(38;2;[0-9]+;[0-9]+;[0-9]+|38;5;[0-9]+|[0-9]+)/g) {
            push @codes, $1;
        }
        my @xformcodes;
        for (@codes) {
            my $xformcode = exists($codemaps{$_}) ? $codemaps{$_} : $_;
            push @xformcodes, $xformcode;
        }
        join ";", @xformcodes;
    };

    while (my $line = <>) {
        $line =~ s/\e\[(.+?)m/"\e[" . $transform->($1) . "m"/eg;
        print $line;
    };

    [200];
}

1;
# ABSTRACT: Transform colors on the CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

App::colorxform - Transform colors on the CLI

=head1 VERSION

This document describes version 0.002 of App::colorxform (from Perl distribution App-colorxform), released on 2018-09-07.

=head1 FUNCTIONS


=head2 colorxform

Usage:

 colorxform(%args) -> [status, msg, result, meta]

Transform colors on the CLI.

Some CLI programs output horrible colors (e.g. hard to read on terminal with
black background) and the colors are either uncustomizable or cumbersome to
customize. This is where C<colorxform> comes in. You pipe the output and it will
replace some colors with another, per your specification.

An example, put this in your C<~/.config/colorxform.conf>:

 [profile=ledger]
 fg_transforms = {"blue":"#18b2b2", "red":"bold red"}

then:

 % ledger -f myledger.dat --color --force-color balance | colorxform -P ledger

You can create a shell alias for convenience:

 % function ledger() { C<which ledger> --color --force-color "$@" | colorxform -P ledger; }

so you can just issue this to get the colors transformed:

 % ledger -f myledger.dat balance

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<bg_transforms> => I<hash> (default: {})

List of background colors to replace with other colors. You can specify color
using RGB code (e.g. C<#123456>) or color names like those recognized by
L<Term::ANSIColor> (e.g. C<blue> or C<bold blue>).

=item * B<fg_transforms> => I<hash> (default: {})

List of foreground colors to replace with other colors. You can specify color
code using RGB code (e.g. C<#123456>) or color names like those recognized by
L<Term::ANSIColor> (e.g. C<blue> or C<bold blue>).

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-colorxform>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-colorxform>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-colorxform>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
