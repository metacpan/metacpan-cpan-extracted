package Perinci::CmdLine::dux;

our $DATE = '2019-10-26'; # DATE
our $VERSION = '1.540'; # VERSION

use 5.010;
use Log::ger;
use Moo;
#extends 'Perinci::CmdLine';
extends 'Perinci::CmdLine::Lite';

# we don't have our own color theme class
#sub color_theme_class_prefix { 'Perinci::CmdLine::ColorTheme' }

sub action_call {
    my ($self, $r) = @_;

    binmode(STDOUT, ":encoding(utf8)");

    # set `in` argument for the dux function
    my $chomp = $r->{meta}{"x.app.dux.strip_newlines"} //
        $r->{meta}{"x.dux.strip_newlines"} // # backward-compat, will be removed someday
            1;
    require Tie::Diamond;
    tie my(@diamond), 'Tie::Diamond', {chomp=>$chomp, utf8=>1} or die;
    $r->{args}{in}  = \@diamond;

    # set `out` argument for the dux function
    my $streamo = $r->{meta}{"x.app.dux.is_stream_output"} //
        $r->{meta}{"x.dux.is_stream_output"}; # backward-compat, will be removed someday
    my $fmt = $r->{format} // 'text';
    if (!defined($streamo)) {
        # turn on streaming if format is simple text
        my $iactive;
        if (-t STDOUT) {
            $iactive = 1;
        } elsif ($ENV{INTERACTIVE}) {
            $iactive = 1;
        } elsif (defined($ENV{INTERACTIVE}) && !$ENV{INTERACTIVE}) {
            $iactive = 0;
        }
        $streamo = 1 if $fmt eq 'text-simple' || $fmt eq 'text' && !$iactive;
    }

    #say "fmt=$fmt, streamo=".($streamo//0);
    if ($streamo) {
        die "Can't format stream as $fmt, please use --format text-simple\n"
            unless $fmt =~ /^text/;
        $r->{is_stream_output} = 1;
        require Tie::Simple;
        my @out;
        tie @out, "Tie::Simple", undef,
            PUSH => sub {
                my $data = shift;
                for (@_) {
                    print $self->hook_format_row($r, $_);
                }
            };
        $r->{args}{out} = \@out;
    } else {
        $r->{args}{out} = [];
    }

    $r->{args}{-dux_cli} = 1;

    $self->SUPER::action_call($r);
}

sub hook_format_result {
    my ($self, $r) = @_;

    # turn off streaming if response is an error response
    if ($r->{res}[0] !~ /\A2/) {
        $r->{is_stream_output} = 0;
    }

    return '' if $r->{is_stream_output};

    if ($r->{res} && $r->{res}[0] == 200 && $r->{args}{-dux_cli}) {
        # insert out to result, so it can be displayed
        $r->{res}[2] = $r->{args}{out};
    }
    $self->SUPER::hook_format_result($r);
}

sub hook_display_result {
    no warnings 'uninitialized';

    my ($self, $r) = @_;

    my $res = $r->{res};
    my $x = $r->{args}{out};

    if ($x) {
        # we only set 'out' for action=call, not for other actions
        my $i = 0;
        while (~~(@$x) > 0) {
            log_trace("[pericmd] Running hook_format_row ...") unless $i;
            $i++;
            print $self->hook_format_row($r, shift(@$x));
        }
    } else {
        print $r->{fres};
    }
}

1;
# ABSTRACT: Perinci::CmdLine subclass for dux cli

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::dux - Perinci::CmdLine subclass for dux cli

=head1 VERSION

This document describes version 1.540 of Perinci::CmdLine::dux (from Perl distribution App-dux), released on 2019-10-26.

=head1 DESCRIPTION

This subclass sets C<in> and C<out> arguments for the dux function, and displays
the resulting <out> array.

It also add a special flag function argument C<< -dux_cli => 1 >> so the
function is aware it is being run through the dux CLI application.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-dux>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-dux>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-dux>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::CmdLine>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
