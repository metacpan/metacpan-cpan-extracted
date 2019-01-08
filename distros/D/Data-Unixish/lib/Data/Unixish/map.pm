package Data::Unixish::map;

use 5.010;
use locale;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);

our $VERSION = '1.570'; # VERSION

our %SPEC;

$SPEC{map} = {
    v => 1.1,
    summary => 'Perl map',
    description => <<'_',

Process each item through a callback.

_
    args => {
        %common_args,
        callback => {
            summary => 'The callback coderef to use',
            schema  => ['any*' => of => ['code*', 'str*']],
            req     => 1,
            pos     => 0,
        },
    },
    tags => [qw/perl unsafe itemfunc/],
};
sub map {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    _map_begin(\%args);
    local ($., $_);
    while (($., $_) = each @$in) {
        push @$out, $args{callback}->();
    }

    [200, "OK"];
}

sub _map_begin {
    my $args = shift;

    if (ref($args->{callback}) ne 'CODE') {
        if ($args->{-cmdline}) {
            $args->{callback} = eval "no strict; no warnings; sub { $args->{callback} }";
            die "invalid Perl code for map: $@" if $@;
        } else {
            die "Please supply coderef for 'callback'";
        }
    }
}

sub _map_item {
    my ($item, $args) = @_;
    local $_ = $item;
    $args->{callback}->();
}

1;
# ABSTRACT: Perl map

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::map - Perl map

=head1 VERSION

This document describes version 1.570 of Data::Unixish::map (from Perl distribution Data-Unixish), released on 2019-01-06.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res = lduxl([map => {callback => sub { 1 + $_ }}], 1, 2, 3);
 # => (2, 3, 4)

In command-line:

 % echo -e "1\n2\n3" | dux map '1 + $_'
 2
 3
 4

=head1 FUNCTIONS


=head2 map

Usage:

 map(%args) -> [status, msg, payload, meta]

Perl map.

Process each item through a callback.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<callback>* => I<code|str>

The callback coderef to use.

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

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
