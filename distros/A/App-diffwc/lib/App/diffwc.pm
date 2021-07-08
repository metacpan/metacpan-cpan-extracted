package App::diffwc;

our $DATE = '2021-07-08'; # DATE
our $VERSION = '0.007'; # VERSION

use strict;
use warnings;

our %Colors = (
    path_line   => "\e[1m",
    linum_line  => "\e[36m",
    delete_line => "\e[31m",
    insert_line => "\e[32m",
    delete_word => "\e[7m",
    insert_word => "\e[7m",
);

sub postprocess {
    require Text::WordDiff::Unified::ANSIColor;

    my $fh = shift;

    if ($ENV{COLOR_THEME}) {
        require Color::Theme::Util;
        my $theme = Color::Theme::Util::get_color_theme(
            {module_prefixes => [qw/ColorTheme::App::diffwc ColorTheme::Generic/]}, $ENV{DIFFWC_COLOR_THEME});
        require Color::Theme::Util::ANSI;
        if ($theme->{colors}{path_line}) {
            for my $c (keys %Colors) {
                $Colors{$c} = Color::Theme::Util::ANSI::theme_color_to_ansi($theme, $c);
            }
        } elsif ($theme->{colors}{color1}) {
            my %map = (
                path_line    => 'color3',
                linum_line   => 'color4',
                delete_line  => 'color1',
                insert_line  => 'color5',
                delete_word  => 'color1',
                insert_word  => 'color5',
            );
            for my $c (keys %Colors) {
                $Colors{$c} = Color::Theme::Util::ANSI::theme_color_to_ansi(
                    $theme, $map{$c});
            }
        } else {
            warn "Unsuitable color theme '$ENV{COLOR_THEME}', ignored";
        }
    }

    local $Text::WordDiff::Unified::ANSIColor::colors{delete_line} = $Colors{delete_line};
    local $Text::WordDiff::Unified::ANSIColor::colors{insert_line} = $Colors{insert_line};
    local $Text::WordDiff::Unified::ANSIColor::colors{delete_word} = $Colors{delete_word};
    local $Text::WordDiff::Unified::ANSIColor::colors{insert_word} = $Colors{insert_word};

    my (@inslines, @dellines);
    my $code_print_ins_del_lines = sub {
        return unless @inslines || @dellines;
        if (@inslines != @dellines || @inslines > 5) {
            for (@dellines) {
                print $Colors{delete_line}, $_, "\e[0m\n";
            }
            for (@inslines) {
                print $Colors{insert_line}, $_, "\e[0m\n";
            }
        } else {
            my $lines1 = "";
            for (@dellines) { s/^-//; $lines1 .= "$_\n" }
            my $lines2 = "";
            for (@inslines) { s/^[+]//; $lines2 .= "$_\n" }
            print Text::WordDiff::Unified::ANSIColor::word_diff(
                $lines1, $lines2);
        }
        @inslines = (); @dellines = ();
    };
    while (defined(my $line = <$fh>)) {
        chomp $line;
        if ($line =~ /^(\+\+\+|---) /) {
            $code_print_ins_del_lines->();
            print $Colors{path_line}, $line, "\e[0m\n";
        } elsif ($line =~ /^\@/) {
            $code_print_ins_del_lines->();
            print $Colors{linum_line}, $line, "\e[0m\n";
        } elsif ($line =~ /^[+]/) {
            push @inslines, $line;
        } elsif ($line =~ /^[-]/) {
            push @dellines, $line;
        } else {
            $code_print_ins_del_lines->();
            print $line, "\n";
        }
    }
    $code_print_ins_del_lines->();
}

1;
# ABSTRACT: diff + /w/ord highlighting + /c/olor

__END__

=pod

=encoding UTF-8

=head1 NAME

App::diffwc - diff + /w/ord highlighting + /c/olor

=head1 VERSION

This document describes version 0.007 of App::diffwc (from Perl distribution App-diffwc), released on 2021-07-08.

=head1 SYNOPSIS

See the command-line script L<diffwc> and L<diffwc-filter-u>.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-diffwc>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-diffwc>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-diffwc>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
