package App::INIUtils;

use strict;
use 5.010001;

use Sort::Sub;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-24'; # DATE
our $DIST = 'App-INIUtils'; # DIST
our $VERSION = '0.035'; # VERSION

our %SPEC;

our %args_common = (
    ini => {
        summary => 'INI file',
        schema  => ['str*'],
        req     => 1,
        pos     => 0,
        cmdline_src => 'stdin_or_file',
        tags    => ['common'],
    },

    # only for parser = Config::IOD::INI::Reader
    default_section => {
        schema  => 'str*',
        default => 'GLOBAL',
        tags    => ['common', 'category:parser'],
    },
    allow_duplicate_key => {
        schema  => 'bool',
        default => 1,
        tags    => ['common', 'category:parser'],
    },
);

our %arg_parser = (
    parser => {
        summary => 'Parser to use',
        schema  => ['str*', {
            in => [
                'Config::IOD::INI::Reader',
                'Config::INI::Reader',
                'Config::IniFiles',
            ],
        }],
        default => 'Config::INI::Reader',
        tags    => ['common'],
    },
);

our %arg_inplace = (
    inplace => {
        summary => 'Modify file in-place',
        schema => ['bool', is=>1],
        description => <<'_',

Note that this can only be done if you specify an actual file and not STDIN.
Otherwise, an error will be thrown.

_
    },
);

sub _check_inplace {
    my $args = shift;
    if ($args->{inplace}) {
        die [412, "To use in-place editing, please supply an actual file"]
            if @{ $args->{-cmdline_srcfilenames_ini} // []} == 0;
        die [412, "To use in-place editing, please supply only one file"]
            if @{ $args->{-cmdline_srcfilenames_ini} // []} > 1;
    }
}

sub _return_mod_result {
    my ($args, $doc) = @_;

    if ($args->{inplace}) {
        require File::Slurper;
        File::Slurper::write_text(
            $args->{-cmdline_srcfilenames_iod}[0], $doc->as_string);
        [200, "OK"];
    } else {
        [200, "OK", $doc->as_string, {'cmdline.skip_format'=>1}];
    }
}

sub _get_cii_parser_options {
    my $args = shift;
    return (
        default_section          => $args->{default_section},
        allow_duplicate_key      => $args->{allow_duplicate_key},
    );
}

sub _get_cii_parser {
    require Config::IOD::INI;

    my $args = shift;
    Config::IOD::INI->new(
        _get_cii_parser_options($args),
    );
}

sub _get_ciir_reader {
    require Config::IOD::INI::Reader;

    my $args = shift;
    Config::IOD::INI::Reader->new(
        _get_cii_parser_options($args),
    );
}

sub _parse_str {
    my ($ini, $parser) = @_;

    if ($parser eq 'Config::INI::Reader') {
        require Config::INI::Reader;
        return Config::INI::Reader->read_string($ini);
    } elsif ($parser eq 'Config::IOD::INI::Reader') {
        require Config::IOD::INI::Reader;
        return Config::IOD::INI::Reader->new->read_string($ini);
    } elsif ($parser eq 'Config::IniFiles') {
        require Config::IniFiles;
        my $cfg = Config::IniFiles->new(-file => \$ini);
        die join("\n", @Config::IniFiles::errors) unless $cfg;
        return $cfg;
    } else {
        die "Unknown parser '$parser'";
    }
}

sub _dump_str {
    my ($ini, $parser) = @_;
    my $res = _parse_str($ini, $parser);
    if ($parser eq 'Config::IniFiles') {
        $res = $res->{v};
    }
    $res;
}

$Sort::Sub::argsopt_sortsub{sort_sub}{cmdline_aliases} = {S=>{}};
$Sort::Sub::argsopt_sortsub{sort_args}{cmdline_aliases} = {A=>{}};

$SPEC{sort_ini_sections} = {
    v => 1.1,
    summary => '',
    args => {
        %App::INIUtils::args_common,
        %Sort::Sub::argsopt_sortsub,
    },
    result_naked => 1,
};
sub sort_ini_sections {
    my %args = @_;

    my $parser = App::INIUtils::_get_cii_parser(\%args);

    my $doc = $parser->read_string($args{ini});
    my @raw_lines = split /^/, $args{ini};

    my $sortsub_routine = $args{sort_sub} // 'asciibetically';
    my $sortsub_args    = $args{sort_args} // {};
    my $sorter = Sort::Sub::get_sorter($sortsub_routine, $sortsub_args);

    my @sections;
    $doc->each_section(
        sub {
            my ($self, %cargs) = @_;
            push @sections, \%cargs;
        });

    @sections = sort { $sorter->($a->{section}, $b->{section}) } @sections;

    my @res;
    for my $section (@sections) {
        my @section_lines = @raw_lines[ $section->{linum_start}-1 .. $section->{linum_end}-1 ];

        # normalize number of blank lines to 1
        while (1) {
            last unless @section_lines;
            last if $section_lines[-1] =~ /\S/;
            pop @section_lines;
        }
        push @res, @section_lines, "\n";
    }

    join "", @res;
}

1;
# ABSTRACT: INI utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

App::INIUtils - INI utilities

=head1 VERSION

This document describes version 0.035 of App::INIUtils (from Perl distribution App-INIUtils), released on 2024-06-24.

=head1 SYNOPSIS

This distribution provides the following command-line utilities:

=over

=item 1. L<delete-ini-key>

=item 2. L<delete-ini-section>

=item 3. L<dump-ini>

=item 4. L<get-ini-key>

=item 5. L<get-ini-section>

=item 6. L<grep-ini>

=item 7. L<insert-ini-key>

=item 8. L<insert-ini-section>

=item 9. L<list-ini-sections>

=item 10. L<map-ini>

=item 11. L<parse-ini>

=item 12. L<sort-ini-sections>

=back

The main feature of these utilities is tab completion.

=head1 FUNCTIONS


=head2 sort_ini_sections

Usage:

 sort_ini_sections(%args) -> any

.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_duplicate_key> => I<bool> (default: 1)

(No description)

=item * B<default_section> => I<str> (default: "GLOBAL")

(No description)

=item * B<ini>* => I<str>

INI file.

=item * B<sort_args> => I<array[str]>

Arguments to pass to the Sort::Sub::* routine.

=item * B<sort_sub> => I<sortsub::spec>

Name of a Sort::Sub::* module (without the prefix).


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-INIUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-INIUtils>.

=head1 SEE ALSO

L<App::IODUtils>

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

This software is copyright (c) 2024, 2019, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-INIUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
