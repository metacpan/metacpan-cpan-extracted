package Data::Dmp::Org;

our $DATE = '2014-10-21'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp (); # for _double_quote()
use Scalar::Util qw(looks_like_number blessed reftype);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(dd dmp);

# for when dealing with circular refs
our %_seen_refaddrs;

*_double_quote = \&Data::Dmp::_double_quote;

sub _dump {
    my ($val, $level) = @_;

    my $ref = ref($val);
    if ($ref eq '') {
        if (!defined($val)) {
            return "undef";
        } elsif (looks_like_number($val)) {
            return $val;
        } else {
            return _double_quote($val);
        }
    }
    my $refaddr = "$val";
    if ($_seen_refaddrs{$refaddr}++) {
        return "[[$refaddr]]";
    }

    my $class;
    if (blessed $val) {
        $ref = reftype($val);
    }

    my $prefix = ("*" x ($level+1)) . " ";

    my $res;
    if ($ref eq 'ARRAY') {
        $res = "$refaddr";
        for (@$val) {
            $res .= "\n$prefix" . _dump($_, $level+1);
        }
    } elsif ($ref eq 'HASH') {
        $res = "$refaddr";
        for (sort keys %$val) {
            my $k = /\W/ ? _double_quote($_) : $_;
            my $v = _dump($val->{$_}, $level+1);
            $res .= "\n${prefix}$k :: $v";
        }
    } elsif ($ref eq 'SCALAR') {
        $res = "\\"._dump($$val, $level);
    } elsif ($ref eq 'REF') {
        $res = "\\"._dump($$val, $level);
    } else {
        die "Sorry, I can't dump $val (ref=$ref) yet";
    }
    $res;
}

our $_is_dd;
sub _dd_or_dmp {
    local %_seen_refaddrs;

    my $res;
    if (@_ > 1) {
        $res = join("", map {"* " . _dump($_, 1) . "\n"} @_);
    } else {
        $res = "* " . _dump($_[0], 1) . "\n";
    }

    if ($_is_dd) {
        say $res;
        return @_;
    } else {
        return $res;
    }
}

sub dd { local $_is_dd=1; _dd_or_dmp(@_) }
sub dmp { goto &_dd_or_dmp }

1;
# ABSTRACT: Dump Perl data structures as Org document

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dmp::Org - Dump Perl data structures as Org document

=head1 VERSION

This document describes version 0.01 of Data::Dmp::Org (from Perl distribution Data-Dmp-Org), released on 2014-10-21.

=head1 SYNOPSIS

 use Data::Dmp::Org; # exports dd() and dmp()
 dd [1, 2, 3];

=head1 DESCRIPTION

This is an experiment module to generate Org document that represents Perl data
structure. The goal is to view it in Emacs or equivalent Org editor/viewer.

=head1 FUNCTIONS

=head2 dd($data, ...) => $data ...

Dump data as Org to STDOUT. Return original data.

=head2 dmp($data, ...) => $str

Return dump result as string.

=head1 SEE ALSO

L<Data::Dmp>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Dmp-Org>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Dmp-Org>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Dmp-Org>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
