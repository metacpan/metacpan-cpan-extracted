package App::LocaleTextDomainUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-26'; # DATE
our $DIST = 'App-LocaleTextDomainUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

our %args_common = (
    search_dirs => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'search_dir',
        schema => ['array*', of=>'str*'],
        cmdline_aliases => {I=>{}},
    },
    textdomain => {
        schema => 'str*',
        pos => 0,
    },
);

$SPEC{list_localedata_dirs} = {
    v => 1.1,
    summary => 'Print list of LocaleData directories to be used to search for *.mo files',
    description => <<'_',

If search_dirs is specified, then will use search_dirs.

Otherwise, will use:

    dist_dir($textdomain) + ("/locale", "/LocaleData")
    @INC + "/LocaleData"
    default ("/usr/share/locale" OR "/usr/local/share/locale") + "/LocaleData"

_
    args => {
        %args_common,
    },
    result_naked => 1,
};
sub list_localedata_dirs {
    my %args = @_;

    my @res;

    if ($args{search_dirs} && @{ $args{search_dirs} }) {
        push @res, $_ for @{ $args{search_dirs} };
    } else {
        # dist-dir(textdomain)
        if (defined $args{textdomain}) {
            my $sharedir = eval {
                require File::ShareDir;
                File::ShareDir::dist_dir($args{textdomain});
            };
            if ($sharedir) {
                push @res, "$sharedir/locale", "$sharedir/LocaleData";
            }
        }

        # @INC
        for (@INC) {
            push @res, "$_/LocaleData" unless ref $_;
        }

        # default dir
        for ("/usr/share/locale", "/usr/local/share/locale") {
            if (-d $_) {
                push @res, "$_/LocaleData";
                last;
            }
        }
    }

    \@res;
}

$SPEC{list_mo_files} = {
    v => 1.1,
    summary => 'List .mo files',
    description => <<'_',

Will look for inside each localedata dirs.

_
    args => {
        %args_common,
    },
    result_naked => 1,
};
sub list_mo_files {
    my %args = @_;
    my $textdomain = $args{textdomain};

    my $localedata_dirs = list_localedata_dirs(%args);

    my @res;
    for my $dir (@$localedata_dirs) {
        if (defined $textdomain) {
            push @res, glob("$dir/*/LC_MESSAGES/$textdomain.mo");
        } else {
            push @res, glob("$dir/*/LC_MESSAGES/*.mo");
        }
    }

    \@res;
}

1;
# ABSTRACT: Utilities related to Locale::TextDomain

__END__

=pod

=encoding UTF-8

=head1 NAME

App::LocaleTextDomainUtils - Utilities related to Locale::TextDomain

=head1 VERSION

This document describes version 0.001 of App::LocaleTextDomainUtils (from Perl distribution App-LocaleTextDomainUtils), released on 2019-12-26.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<list-localedata-dirs>

=item * L<list-mo-files>

=back

=head1 FUNCTIONS


=head2 list_localedata_dirs

Usage:

 list_localedata_dirs(%args) -> any

Print list of LocaleData directories to be used to search for *.mo files.

If search_dirs is specified, then will use search_dirs.

Otherwise, will use:

 dist_dir($textdomain) + ("/locale", "/LocaleData")
 @INC + "/LocaleData"
 default ("/usr/share/locale" OR "/usr/local/share/locale") + "/LocaleData"

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<search_dirs> => I<array[str]>

=item * B<textdomain> => I<str>

=back

Return value:  (any)



=head2 list_mo_files

Usage:

 list_mo_files(%args) -> any

List .mo files.

Will look for inside each localedata dirs.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<search_dirs> => I<array[str]>

=item * B<textdomain> => I<str>

=back

Return value:  (any)

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-LocaleTextDomainUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-LocaleTextDomainUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-LocaleTextDomainUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Locale::TextDomain>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
