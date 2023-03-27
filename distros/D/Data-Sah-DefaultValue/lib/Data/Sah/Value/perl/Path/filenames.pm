package Data::Sah::Value::perl::Path::filenames;

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-20'; # DATE
our $DIST = 'Data-Sah-DefaultValue'; # DIST
our $VERSION = '0.002'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Files on the filesystem',
        description => <<'_',

This default-value rule can set default value of filenames on the filesystem. By
default it retrieves all non-dir files on the current directory. You can
exclude/include using regex and retrieve files recursively.

_
        prio => 50,
        args => {
            recursive => {schema=>'bool*'},
            exclude => {schema=>'re*'},
            include => {schema=>'re*'},
        },
    };
}

sub value {
    my %cargs = @_;

    my $gen_args = $cargs{args} // {};
    my $res = {};

    if (defined $gen_args->{exclude}) { $gen_args->{exclude} = qr/$gen_args->{exclude}/ unless ref $gen_args->{exclude} }
    if (defined $gen_args->{include}) { $gen_args->{include} = qr/$gen_args->{include}/ unless ref $gen_args->{include} }

    $res->{modules}{'File::Find'} //= 0;
    $res->{expr_value} = join(
        '',
        'do { ', (
            'my $recursive = ', dmp($gen_args->{recursive}), '; ',
            'my $exclude = ', dmp($gen_args->{exclude}), '; ',
            'my $include = ', dmp($gen_args->{include}), '; ',
            'my @files; ',
            'if ($recursive) { File::Find::find(sub { return if -d $_; push @files, "$File::Find::dir/$_" }, ".") } ',
            'else { opendir my $dh, "."; @files = grep {$_ ne "." && $_ ne ".." && !(-d $_) } readdir $dh; closedir $dh } ',
            'if ($exclude) { @files = grep { $_ !~ $exclude } @files } ',
            'if ($include) { @files = grep { $_ =~ $include } @files } ',
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

This document describes version 0.002 of Data::Sah::Value::perl::Path::filenames (from Perl distribution Data-Sah-DefaultValue), released on 2023-01-20.

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|value)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-DefaultValue>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-DefaultValue>.

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

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-DefaultValue>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
