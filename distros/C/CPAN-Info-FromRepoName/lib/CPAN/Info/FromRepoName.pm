package CPAN::Info::FromRepoName;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-02'; # DATE
our $DIST = 'CPAN-Info-FromRepoName'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(extract_cpan_info_from_repo_name);

our %SPEC;

our $re_proto_http = qr!(?:https?://)!i;
our $re_author   = qr/(?:\w+)/;
our $re_dist     = qr/(?:\w+(?:-\w+)*)/;
our $re_mod      = qr/(?:\w+(?:::\w+)*)/;
our $re_version  = qr/(?:v?[0-9]+(?:\.[0-9]+)*(?:_[0-9]+|-TRIAL)?)/;
our $re_end_or_q = qr/(?:[?&#]|\z)/;

sub _normalize_mod {
    my $mod = shift;
    $mod =~ s/'/::/g;
    $mod;
}

$SPEC{extract_cpan_info_from_repo_name} = {
    v => 1.1,
    summary => 'Extract/guess information from a repo name',
    description => <<'_',

Guess information from a repo name and return a hash (or undef if nothing can be
guessed). Possible keys include `dist` (Perl distribution name).

_
    args => {
        repo_name => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'hash',
    },
    result_naked => 1,
    examples => [
        {
            name => "perl-<dist>",
            args => {repo_name=>'perl-Foo-Bar'},
            result => {dist=>"Foo-Bar"},
        },
        {
            name => "p5-<dist>",
            args => {repo_name=>'perl-Foo-Bar'},
            result => {dist=>"Foo-Bar"},
        },
        {
            name => "cpan-<dist>",
            args => {repo_name=>'cpan-Foo-Bar'},
            result => {dist=>"Foo-Bar"},
        },
        {
            name => "<dist>-perl",
            args => {repo_name=>'Foo-Bar-perl'},
            result => {dist=>"Foo-Bar"},
        },
        {
            name => "<dist>-p5",
            args => {repo_name=>'Foo-Bar-p5'},
            result => {dist=>"Foo-Bar"},
        },
        {
            name => "<dist>-cpan",
            args => {repo_name=>'Foo-Bar-cpan'},
            result => {dist=>"Foo-Bar"},
        },
        {
            name => "<dist>",
            args => {repo_name=>'CPAN-Foo-Bar'},
            result => {dist=>"CPAN-Foo-Bar"},
        },
        {
            name => "unknown",
            args => {repo_name=>'@foo'},
            result => undef,
        },
    ],
};
sub extract_cpan_info_from_repo_name {
    state $re_modname;
    state $re_distname = do {
        require Regexp::Pattern::Perl::Module;
        $re_modname  = $Regexp::Pattern::Perl::Module::RE{perl_modname}{pat};

        require Regexp::Pattern::Perl::Dist;
        $Regexp::Pattern::Perl::Dist::RE{perl_distname}{pat};
    };

    my $repo_name = shift;

    my $res;

    if ($repo_name =~ /\A(?:perl|p5|cpan)-($re_distname)\z/) {
        $res->{dist} = $1;
    } elsif ($repo_name =~ /\A($re_distname)-(?:perl|p5|cpan)\z/) {
        $res->{dist} = $1;
    } elsif ($repo_name =~ /\A($re_distname)\z/) {
        $res->{dist} = $1;
    }
    $res;
}

1;
# ABSTRACT: Extract/guess information from a repo name

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Info::FromRepoName - Extract/guess information from a repo name

=head1 VERSION

This document describes version 0.001 of CPAN::Info::FromRepoName (from Perl distribution CPAN-Info-FromRepoName), released on 2020-10-02.

=head1 FUNCTIONS


=head2 extract_cpan_info_from_repo_name

Usage:

 extract_cpan_info_from_repo_name($repo_name) -> hash

ExtractE<sol>guess information from a repo name.

Examples:

=over

=item * Example #1 (perl-<distE<gt>):

 extract_cpan_info_from_repo_name("perl-Foo-Bar"); # -> { dist => "Foo-Bar" }

=item * Example #2 (p5-<distE<gt>):

 extract_cpan_info_from_repo_name("perl-Foo-Bar"); # -> { dist => "Foo-Bar" }

=item * Example #3 (cpan-<distE<gt>):

 extract_cpan_info_from_repo_name("cpan-Foo-Bar"); # -> { dist => "Foo-Bar" }

=item * Example #4 (<distE<gt>-perl):

 extract_cpan_info_from_repo_name("Foo-Bar-perl"); # -> { dist => "Foo-Bar" }

=item * Example #5 (<distE<gt>-p5):

 extract_cpan_info_from_repo_name("Foo-Bar-p5"); # -> { dist => "Foo-Bar" }

=item * Example #6 (<distE<gt>-cpan):

 extract_cpan_info_from_repo_name("Foo-Bar-cpan"); # -> { dist => "Foo-Bar" }

=item * Example #7 (<distE<gt>):

 extract_cpan_info_from_repo_name("CPAN-Foo-Bar"); # -> { dist => "CPAN-Foo-Bar" }

=item * Example #8 (unknown):

 extract_cpan_info_from_repo_name("\@foo"); # -> undef

=back

Guess information from a repo name and return a hash (or undef if nothing can be
guessed). Possible keys include C<dist> (Perl distribution name).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$repo_name>* => I<str>


=back

Return value:  (hash)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CPAN-Info-FromRepoName>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CPAN-Info-FromRepoName>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Info-FromRepoName>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<CPAN::Info::FromURL>

L<CPAN::Author::FromRepoName>

L<CPAN::Dist::FromRepoName>

L<CPAN::Module::FromRepoName>

L<CPAN::Release::FromRepoName>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
