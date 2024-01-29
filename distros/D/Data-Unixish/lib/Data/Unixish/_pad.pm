package Data::Unixish::_pad;

use 5.010;
use locale;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use String::Pad qw(pad);
use Text::ANSI::Util qw(ta_pad);
use Text::ANSI::WideUtil qw(ta_mbpad);
use Text::WideChar::Util qw(mbpad);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-23'; # DATE
our $DIST = 'Data-Unixish'; # DIST
our $VERSION = '1.573'; # VERSION

sub _pad {
    my ($which, %args) = @_;
    my ($in, $out) = ($args{in}, $args{out});

    __pad_begin($which, \%args);
    while (my ($index, $item) = each @$in) {
        push @$out, __pad_item($which, $item, \%args);
    }

    [200, "OK"];
}

sub __pad_begin {
    my ($which, $args) = @_;
    $args->{char} //= ' ';
}

sub __pad_item {
    my ($which, $item, $args) = @_;

    {
        last if !defined($item) || ref($item);
        if ($args->{ansi}) {
            if ($args->{mb}) {
                $item = ta_mbpad($item, $args->{width}, $which,
                                 $args->{char}, $args->{trunc});
            } else {
                $item = ta_pad  ($item, $args->{width}, $which,
                                 $args->{char}, $args->{trunc});
            }
        } elsif ($args->{mb}) {
            $item = mbpad($item, $args->{width}, $which,
                          $args->{char}, $args->{trunc});
        } else {
            $item = pad  ($item, $args->{width}, $which,
                          $args->{char}, $args->{trunc});
        }
    }
    return $item;
}

1;
# ABSTRACT: _pad

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::_pad - _pad

=head1 VERSION

This document describes version 1.573 of Data::Unixish::_pad (from Perl distribution Data-Unixish), released on 2023-09-23.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish>.

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

This software is copyright (c) 2023, 2019, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
