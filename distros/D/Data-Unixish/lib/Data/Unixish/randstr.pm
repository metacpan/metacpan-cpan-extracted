package Data::Unixish::randstr;

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);
our $VERSION = '1.55'; # VERSION

our %SPEC;

my $def_charset = 'AZaz09';
my %charsets = (
    '09'     => '0123456789',
    'AZ'     => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    'az'     => 'abcdefghijklmnopqrstuvwxyz',
    'AZaz'   => 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
    'AZaz09' => 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789',
);
my $charsets_desc = <<'_';

`az` is basic Latin lowercase letters. `AZ` uppercase letters. `AZaz` lowercase
and uppercase letters. `AZaz09` lowercase + uppercase letters + Arabic numbers.
`09` numbers.

_

$SPEC{randstr} = {
    v => 1.1,
    summary => 'Generate a stream of random strings',
    args => {
        %common_args,
        min_len => {
            summary => 'Minimum possible length (inclusive)',
            schema => ['int*', min=>0, default=>16],
            cmdline_aliases => { a=>{} },
        },
        max_len => {
            summary => 'Maximum possible length (inclusive)',
            schema => ['int*', min=>0, default=>16],
            cmdline_aliases => {
                b => {},
                c => {
                    summary => 'Set length (min_len and max_len)',
                    code => sub {
                        my ($args, $val) = @_;
                        $args->{min_len} = $val;
                        $args->{max_len} = $val;
                    },
                },
            },
        },
        charset => {
            summary => 'Character set to use',
            description => $charsets_desc,
            schema => ['str*', default=>$def_charset,
                       in=>[sort keys %charsets]],
        },
        num => {
            summary => 'Number of strings to generate, -1 means infinite',
            schema => ['int*', default=>1],
            cmdline_aliases => { n=>{} },
        },
    },
    tags => [qw/text gen-data/],
    'x.dux.is_stream_output' => 1, # for duxapp < 1.41, will be removed later
    'x.app.dux.is_stream_output' => 1,
};
sub randstr {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    # XXX schema
    my $min_len   = $args{min_len} // 16; $min_len = 0 if $min_len < 0;
    my $max_len   = $args{max_len} // 16; $max_len = 0 if $max_len < 0;
    my $charset   = $args{charset};
    my $chars     = $charsets{$charset};
    return [400, "Unknown charset"] unless defined($chars);
    my $len_chars = length($chars);
    my $num       = $args{num} // 1;

    my $i = 0;
    while (1) {
        last if $num >= 0 && ++$i > $num;
        my $len = $min_len + int(rand()*($max_len-$min_len+1));
        my $rand = join "", map {substr($chars, $len_chars*rand(), 1)} 1..$len;
        push @$out, $rand;
    }

    [200, "OK"];
}

1;
# ABSTRACT: Generate a stream of random strings

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::randstr - Generate a stream of random strings

=head1 VERSION

This document describes version 1.55 of Data::Unixish::randstr (from Perl distribution Data-Unixish), released on 2016-03-16.

=head1 SYNOPSIS

In command line:

 % dux randstr
 trWFSsAwZH4Cli90

 % dux randstr --min-len 1 --max-len 5 --charset AZ -n 5
 WXY
 KQDCG
 MGS
 QMEH
 JDOCK

=head1 FUNCTIONS


=head2 randstr(%args) -> [status, msg, result, meta]

Generate a stream of random strings.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<charset> => I<str> (default: "AZaz09")

Character set to use.

C<az> is basic Latin lowercase letters. C<AZ> uppercase letters. C<AZaz> lowercase
and uppercase letters. C<AZaz09> lowercase + uppercase letters + Arabic numbers.
C<09> numbers.

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<max_len> => I<int> (default: 16)

Maximum possible length (inclusive).

=item * B<min_len> => I<int> (default: 16)

Minimum possible length (inclusive).

=item * B<num> => I<int> (default: 1)

Number of strings to generate, -1 means infinite.

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

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

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Data-Unixish>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
