package Complete::Fish::Gen::FromGetoptLongDescriptive;

our $DATE = '2016-10-27'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       gen_fish_complete_from_getopt_long_descriptive_script
                       gen_fish_complete_from_getopt_long_descriptive_spec
               );

$SPEC{gen_fish_complete_from_getopt_long_descriptive_spec} = {
    v => 1.1,
    summary => 'From Getopt::Long::Descriptive spec, generate tab completion '.
        'commands for the fish shell',
    description => <<'_',

This routine generate fish `complete` command for each short/long option,
enabling fish to display the options in a different color.

_
    args => {
        spec => {
            summary => 'Getopt::Long::Descriptive specification',
            schema => 'array*',
            req => 1,
            pos => 0,
        },
        cmdname => {
            summary => 'Command name to be completed',
            schema => 'str*',
            req => 1,
        },
        compname => {
            summary => 'Completer name, if there is a completer for option values',
            schema => 'str*',
        },
    },
    result => {
        schema => 'str*',
        summary => 'A script that can be fed to the fish shell',
    },
};
sub gen_fish_complete_from_getopt_long_descriptive_spec {
    my %args = @_;

    my $gldspec = $args{spec} or return [400, "Please specify 'spec'"];

    require Getopt::Long::Util;
    my $glspec = {};
    my $opt_desc = {};

    for my $i (0..$#{$gldspec}) {
        next if !$i; # first argument is program usage
        my $ospec = $gldspec->[$i];
        next unless @$ospec;
        my ($glospec, $desc) = @$ospec;
        my $parsed = Getopt::Long::Util::parse_getopt_long_opt_spec($glospec);
        $glspec->{$glospec} = sub {};
        for my $o (@{ $parsed->{opts} }) {
            $opt_desc->{$o} = $desc;
        }
    }

    require Complete::Fish::Gen::FromGetoptLong;
    Complete::Fish::Gen::FromGetoptLong::gen_fish_complete_from_getopt_long_spec(
        spec => $glspec,
        opt_desc => $opt_desc,
        cmdname => $args{cmdname},
        compname => $args{compname},
    );
}

$SPEC{gen_fish_complete_from_getopt_long_descriptive_script} = {
    v => 1.1,
    summary => 'Generate fish completion script from Getopt::Long::Descriptive script',
    description => <<'_',

This routine generate fish `complete` command for each short/long option,
enabling fish to display the options in a different color.

_
    args => {
        filename => {
            schema => 'filename*',
            req => 1,
            pos => 0,
            cmdline_aliases => {f=>{}},
        },
        cmdname => {
            summary => 'Command name to be completed, defaults to filename',
            schema => 'str*',
        },
        compname => {
            summary => 'Completer name',
            schema => 'str*',
        },
        skip_detect => {
            schema => ['bool', is=>1],
            cmdline_aliases => {D=>{}},
        },
    },
    result => {
        schema => 'str*',
        summary => 'A script that can be fed to the fish shell',
    },
};
sub gen_fish_complete_from_getopt_long_descriptive_script {
    my %args = @_;

    my $filename = $args{filename};
    return [404, "No such file or not a file: $filename"] unless -f $filename;

    require Getopt::Long::Descriptive::Dump;
    my $dump_res = Getopt::Long::Descriptive::Dump::dump_getopt_long_descriptive_script(
        filename => $filename,
        skip_detect => $args{skip_detect},
    );
    return $dump_res unless $dump_res->[0] == 200;

    my $cmdname = $args{cmdname};
    if (!$cmdname) {
        ($cmdname = $filename) =~ s!.+/!!;
    }
    my $compname = $args{compname};

    my $gldspec = $dump_res->[2];

    gen_fish_complete_from_getopt_long_descriptive_spec(
        spec => $gldspec,
        cmdname => $cmdname,
        compname => $compname,
    );
}

1;
# ABSTRACT: Generate fish completion script from Getopt::Long::Descriptive spec/script

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Fish::Gen::FromGetoptLongDescriptive - Generate fish completion script from Getopt::Long::Descriptive spec/script

=head1 VERSION

This document describes version 0.001 of Complete::Fish::Gen::FromGetoptLongDescriptive (from Perl distribution Complete-Fish-Gen-FromGetoptLongDescriptive), released on 2016-10-27.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 gen_fish_complete_from_getopt_long_descriptive_script(%args) -> [status, msg, result, meta]

Generate fish completion script from Getopt::Long::Descriptive script.

This routine generate fish C<complete> command for each short/long option,
enabling fish to display the options in a different color.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmdname> => I<str>

Command name to be completed, defaults to filename.

=item * B<compname> => I<str>

Completer name.

=item * B<filename>* => I<filename>

=item * B<skip_detect> => I<bool>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value: A script that can be fed to the fish shell (str)


=head2 gen_fish_complete_from_getopt_long_descriptive_spec(%args) -> [status, msg, result, meta]

From Getopt::Long::Descriptive spec, generate tab completion commands for the fish shell.

This routine generate fish C<complete> command for each short/long option,
enabling fish to display the options in a different color.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmdname>* => I<str>

Command name to be completed.

=item * B<compname> => I<str>

Completer name, if there is a completer for option values.

=item * B<spec>* => I<array>

Getopt::Long::Descriptive specification.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value: A script that can be fed to the fish shell (str)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Fish-Gen-FromGetoptLongDescriptive>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Fish-Gen-FromGetoptLongDescriptive>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Fish-Gen-FromGetoptLongDescriptive>

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
