package Data::Sah::Value::perl::Path::filenames;

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-30'; # DATE
our $DIST = 'Data-Sah-ValueBundle-Path'; # DIST
our $VERSION = '0.004'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Files on the filesystem',
        description => <<'_',

This default-value rule can set default value of filenames on the filesystem. By
default it retrieves all non-dir files on the current directory. You can start
at another point in the filesystem, exclude/include names using regex,
exclude/include by type, retrieve files recursively.

_
        prio => 50,
        args => {
            starting_path => {schema=>'dirname*', default=>'.'},
            recurse => {schema=>'bool*'},
            #max_depth => {schema=>'posint*'},
            exclude_name_pattern => {schema=>'re*'},
            include_name_pattern => {schema=>'re*'},
            include_type => {schema=>'str*', summary=>'One or more characters of b (block special file), c (character special file), f (regular file), l (symlink), p (named pipe), s (Unix socket)'},
            exclude_type => {schema=>'str*', summary=>'See `include_type` for more details'},
        },
    };
}

sub value {
    my %cargs = @_;

    my $gen_args = $cargs{args} // {};
    my $res = {};

    if (defined $gen_args->{exclude_name_pattern}) { $gen_args->{exclude_name_pattern} = qr/$gen_args->{exclude_name_pattern}/ unless ref $gen_args->{exclude_name_pattern} }
    if (defined $gen_args->{include_name_pattern}) { $gen_args->{include_name_pattern} = qr/$gen_args->{include_name_pattern}/ unless ref $gen_args->{include_name_pattern} }

    $res->{modules}{'File::Find'} //= 0;
    $res->{expr_value} = join(
        '',
        'do { ', (
            'my $starting_path = ', dmp($gen_args->{starting_path} // "."), '; ',
            'my $recurse = ', dmp($gen_args->{recurse}), '; ',
            #'my $max_depth = ', dmp($gen_args->{max_depth}), '; ',
            'my $include_name_pattern = ', dmp($gen_args->{include_name_pattern}), '; ',
            'my $exclude_name_pattern = ', dmp($gen_args->{exclude_name_pattern}), '; ',
            'my $include_type = ', dmp($gen_args->{include_type} // ''), '; ',
            'my $exclude_type = ', dmp($gen_args->{exclude_type} // ''), '; ',
            'my $include_dot = ', dmp($gen_args->{include_dot}), '; ',
            'my $include_nondot = ', dmp($gen_args->{include_nondot}), '; ',
            'my @files; ',
            'if ($recurse) { File::Find::find(sub { return if (-d $_) && $include_type !~ /d/; push @files, "$File::Find::dir/$_" }, $starting_path) } ',
            'else { opendir my($dh), $starting_path; @files = map { "$starting_path/$_" } grep {$_ ne "." && $_ ne ".." && ($include_type =~ /d/ || !(-d $_)) } readdir $dh; closedir $dh } ',
            #'use DD; dd \@files; ',
            'if ($exclude_name_pattern) { @files = grep { $_ !~ $exclude_name_pattern } @files } ',
            'if ($include_name_pattern) { @files = grep { $_ =~ $include_name_pattern } @files } ',
            'if ($include_type || $exclude_type) { my @ffiles; ', (
                'for my $f (@files) { ', (
                    'my @st = lstat($f) or next; ',
                    'my $is_b = -b _; next if (!$is_b && $include_type =~ /b/) || ($is_b && $exclude_type =~ /b/); ',
                    'my $is_c = -c _; next if (!$is_c && $include_type =~ /c/) || ($is_c && $exclude_type =~ /c/); ',
                    'my $is_f = -f _; next if (!$is_f && $include_type =~ /f/) || ($is_f && $exclude_type =~ /f/); ',
                    'my $is_l = -l _; next if (!$is_l && $include_type =~ /l/) || ($is_l && $exclude_type =~ /l/); ',
                    'my $is_p = -p _; next if (!$is_p && $include_type =~ /p/) || ($is_p && $exclude_type =~ /p/); ',
                    'my $is_s = -S _; next if (!$is_s && $include_type =~ /s/) || ($is_s && $exclude_type =~ /s/); ',
                    'push @ffiles, $f; ',
                ), '} ',
            ), ' @files = @ffiles } ',
            '\@files; ',
        ), '}',
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Value::perl::Path::filenames

=head1 VERSION

This document describes version 0.004 of Data::Sah::Value::perl::Path::filenames (from Perl distribution Data-Sah-ValueBundle-Path), released on 2023-03-30.

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|value)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-ValueBundle-Path>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-ValueBundle-Path>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-ValueBundle-Path>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
