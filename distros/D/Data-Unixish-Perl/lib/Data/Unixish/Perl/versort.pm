package Data::Unixish::Perl::versort;

our $DATE = '2016-08-25'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);

our %SPEC;

$SPEC{versort} = {
    v => 1.1,
    summary => 'Sort version numbers',
    description => <<'_',

Invalid versions are put at the back.

_
    args => {
        %common_args,
        reverse => {
            summary => 'Whether to reverse sort result',
            schema=>[bool => {default=>0}],
            cmdline_aliases => { r=>{} },
        },
    },
    tags => [qw/ordering/],
};
sub versort {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});
    my $reverse = $args{reverse} ? -1 : 1;

    no warnings;
    my @buf;

    while (my ($index, $item) = each @$in) {
        my $rec = [$item];
        my $v;
        eval { $v = version->parse($item) };
        push @$rec, (defined($v) ? 0:1), $v; # cache invalidness & parsed version
        push @buf, $rec;
    }

    @buf = sort {
        my $cmp;

        # invalid versions are put at the back
        $cmp = $a->[1] <=> $b->[1];
        goto L1 if $cmp;

        if ($a->[1]) {
            # invalid versions are compared ascibetically
            $cmp = $a cmp $b;
        } else {
            # valid versions are compared
            $cmp = $a->[2] <=> $b->[2];
        }

      L1:
        $cmp = $reverse * $cmp;
        #say "D:a=<$a->[0]>, b=<$b->[0]>, cmp=<$cmp>";
        $cmp;
    } @buf;

    push @$out, $_->[0] for @buf;

    [200, "OK"];
}

1;
# ABSTRACT: Sort version numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::Perl::versort - Sort version numbers

=head1 VERSION

This document describes version 0.001 of Data::Unixish::Perl::versort (from Perl distribution Data-Unixish-Perl), released on 2016-08-25.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res;
 @res = lduxl('sort', "v1.1", "v1.10", "v1.9"); # => ("v1.1", "v1.9", "v1.10")
 @res = lduxl([sort => {reverse=>1}], "v1.1", "v1.10", "v1.9"); # => ("v1.10", "v1.9", "v1.1")

In command line:

 % echo -e "v1.1\nv1.9\nv1.10" | dux Perl::versort --format=text-simple
 v1.1
 v1.9
 v1.10

=head1 FUNCTIONS


=head2 versort(%args) -> [status, msg, result, meta]

Sort version numbers.

Invalid versions are put at the back.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<reverse> => I<bool> (default: 0)

Whether to reverse sort result.

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

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<version>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
