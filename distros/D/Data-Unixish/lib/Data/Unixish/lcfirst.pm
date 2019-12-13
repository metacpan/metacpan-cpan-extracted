package Data::Unixish::lcfirst;

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);

our $VERSION = '1.572'; # VERSION

our %SPEC;

$SPEC{lcfirst} = {
    v => 1.1,
    summary => 'Convert first character of text to lowercase',
    description => <<'_',

_
    args => {
        %common_args,
    },
    tags => [qw/text itemfunc/],
};
sub lcfirst {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    while (my ($index, $item) = each @$in) {
        push @$out, _lcfirst_item($item);
    }

    [200, "OK"];
}

sub _lcfirst_item {
    my $item = shift;

    if (defined($item) && !ref($item)) {
        $item = CORE::lcfirst($item);
    }
    return $item;
}

1;
# ABSTRACT: Convert first character of text to lowercase

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::lcfirst - Convert first character of text to lowercase

=head1 VERSION

This document describes version 1.572 of Data::Unixish::lcfirst (from Perl distribution Data-Unixish), released on 2019-10-26.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res = lduxl('lcfirst', 'Januar', 'JANUAR'); # => ('januar', 'jANUAR')

In command line:

 % echo -e "JANUAR" | dux lcfirst
 jANUAR

=head1 FUNCTIONS


=head2 lcfirst

Usage:

 lcfirst(%args) -> [status, msg, payload, meta]

Convert first character of text to lowercase.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

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
