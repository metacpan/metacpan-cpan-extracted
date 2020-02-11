## no critic: InputOutput::RequireBriefOpen

package App::rpgrep;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-09'; # DATE
our $DIST = 'App-rpgrep'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use App::RegexpPatternUtils;
use AppBase::Grep;
use Perinci::Sub::Util qw(gen_modified_sub);
use Regexp::Pattern;

our %SPEC;

gen_modified_sub(
    output_name => 'rpgrep',
    base_name   => 'AppBase::Grep::grep',
    summary     => 'Print lines matching a Regexp::Pattern pattern',
    description => <<'_',

_
    remove_args => [
        'regexps',
        'pattern',
    ],
    add_args    => {
        %App::RegexpPatternUtils::args_common_get_pattern,
        files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            schema => ['array*', of=>'filename*'],
            pos => 1,
            greedy => 1,
        },
        # XXX recursive (-r)
    },
    output_code => sub {
        my %args = @_;
        my ($fh, $file);

        my @files = @{ delete($args{files}) // [] };
        my %gen_args = %{ delete($args{gen_args}) // {} };
        $gen_args{-anchor} = 1 if delete $args{anchor};
        $args{pattern} = re($args{pattern}, \%gen_args);

        # XXX remove code duplication with App::abgrep

        my $show_label = 0;
        if (!@files) {
            $fh = \*STDIN;
        } elsif (@files > 1) {
            $show_label = 1;
        }

        $args{_source} = sub {
          READ_LINE:
            {
                if (!defined $fh) {
                    return unless @files;
                    $file = shift @files;
                    log_trace "Opening $file ...";
                    open $fh, "<", $file or do {
                        warn "rpgrep: Can't open '$file': $!, skipped\n";
                        undef $fh;
                    };
                    redo READ_LINE;
                }

                my $line = <$fh>;
                if (defined $line) {
                    return ($line, $show_label ? $file : undef);
                } else {
                    undef $fh;
                    redo READ_LINE;
                }
            }
        };

        AppBase::Grep::grep(%args);
    },
);

1;
# ABSTRACT: Print lines matching a Regexp::Pattern pattern

__END__

=pod

=encoding UTF-8

=head1 NAME

App::rpgrep - Print lines matching a Regexp::Pattern pattern

=head1 VERSION

This document describes version 0.002 of App::rpgrep (from Perl distribution App-rpgrep), released on 2020-02-09.

=head1 FUNCTIONS


=head2 rpgrep

Usage:

 rpgrep(%args) -> [status, msg, payload, meta]

Print lines matching a Regexp::Pattern pattern.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Require all patterns to match, instead of just one.

=item * B<anchor> => I<bool>

Generate an anchored version of the pattern.

=item * B<color> => I<str>

=item * B<count> => I<true>

Supress normal output, return a count of matching lines.

=item * B<files> => I<array[filename]>

=item * B<gen_args> => I<hash>

Supply generator arguments.

If pattern is a dynamic pattern (generated on-demand) and the generator requires
some arguments, you can supply them here.

=item * B<ignore_case> => I<bool>

=item * B<invert_match> => I<bool>

Invert the sense of matching.

=item * B<line_number> => I<true>

=item * B<pattern>* => I<regexppattern::name>

Name of pattern, with module prefix but without the 'Regexp::Pattern'.

=item * B<quiet> => I<true>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-rpgrep>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-rpgrep>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-rpgrep>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern>

L<App::RegexpPatternUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
