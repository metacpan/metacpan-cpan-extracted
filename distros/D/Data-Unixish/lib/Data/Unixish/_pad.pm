package Data::Unixish::_pad;

our $DATE = '2019-10-26'; # DATE
our $VERSION = '1.572'; # VERSION

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

This document describes version 1.572 of Data::Unixish::_pad (from Perl distribution Data-Unixish), released on 2019-10-26.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
