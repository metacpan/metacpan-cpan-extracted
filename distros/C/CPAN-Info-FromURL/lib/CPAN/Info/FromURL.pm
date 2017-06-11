package CPAN::Info::FromURL;

our $DATE = '2017-06-09'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(extract_cpan_info_from_url);

our %SPEC;

our $re_proto_http = qr!(?:https?://)!i;
our $re_author   = qr/(?:\w+)/;
our $re_dist     = qr/(?:\w+(?:-\w+)*)/;
our $re_mod      = qr/(?:\w+(?:::\w+)*)/;
our $re_version  = qr/(?:v?[0-9]+(?:\.[0-9]+)*(?:_[0-9]+|-TRIAL)?)/;
our $re_end_or_q = qr/(?:[?&]|\z)/;

sub _normalize_mod {
    my $mod = shift;
    $mod =~ s/'/::/g;
    $mod;
}

$SPEC{extract_cpan_info_from_url} = {
    v => 1.1,
    summary => 'Extract/guess information from a URL',
    description => <<'_',

Return a hash of information from a CPAN-related URL. Possible keys include:
`site` (site nickname, include: `mcpan` [metacpan.org, api.metacpan.org,
fastapi.metacpan.org], `sco` [search.cpan.org], `cpanratings`
[cpanratings.perl.org], `rt` ([rt.cpan.org]), `cpan` [any normal CPAN mirror]),
`author` (CPAN author ID), `module` (module name), `dist` (distribution name),
`version` (distribution version). Some keys might not exist, depending on what
information the URL provides. Return undef if URL is not detected to be of some
CPAN-related URL.

_
    args => {
        url => {
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
            name => "mcpan/pod/MOD",
            args => {url=>'https://metacpan.org/pod/Foo::Bar'},
            result => {site=>'mcpan', module=>'Foo::Bar'},
        },
        {
            name => "mcpan/module/MOD",
            args => {url=>'metacpan.org/module/Foo?'},
            result => {site=>'mcpan', module=>'Foo'},
        },
        {
            name => "mcpan/pod/release/AUTHOR/DIST-VERSION/lib/MOD.pm",
            args => {url=>'http://metacpan.org/pod/release/SRI/Mojolicious-6.46/lib/Mojo.pm'},
            result => {site=>'mcpan', author=>'SRI', dist=>'Mojolicious', version=>'6.46', module=>'Mojo'},
        },
        {
            name => "mcpan/pod/release/AUTHOR/DIST-VERSION/bin/SCRIPT",
            args => {url=>'http://metacpan.org/pod/release/PERLANCAR/App-PMUtils-1.23/bin/pmpath'},
            result => {site=>'mcpan', author=>'PERLANCAR', dist=>'App-PMUtils', version=>'1.23', script=>'pmpath'},
        },
        {
            name => "mcpan/source/AUTHOR/DIST-VERSION/lib/MOD.pm",
            args => {url=>'http://metacpan.org/source/SRI/Mojolicious-6.46/lib/Mojo.pm?'},
            result => {site=>'mcpan', author=>'SRI', dist=>'Mojolicious', version=>'6.46', module=>'Mojo'},
        },
        {
            name => "api.mcpan/source/AUTHOR/DIST-VERSION",
            args => {url=>'http://api.metacpan.org/source/SRI/Mojolicious-6.46?'},
            result => {site=>'mcpan', author=>'SRI', dist=>'Mojolicious', version=>'6.46'},
        },
        {
            name => "fastapi.mcpan/v1/module/MODULE",
            args => {url=>'http://fastapi.metacpan.org/v1/module/Moose'},
            result => {site=>'mcpan', module=>'Moose'},
        },
        {
            name => 'mcpan/release/DIST',
            args => {url=>'https://metacpan.org/release/Foo-Bar'},
            result => {site=>'mcpan', dist=>'Foo-Bar'},
        },
        {
            name => 'mcpan/release/AUTHOR/DIST-VERSION',
            args => {url=>'https://metacpan.org/release/FOO/Bar-1.23'},
            result => {site=>'mcpan', author=>'FOO', dist=>'Bar', version=>'1.23'},
        },
        {
            name => 'mcpan/author/AUTHOR',
            args => {url=>'https://metacpan.org/author/FOO'},
            result => {site=>'mcpan', author=>'FOO'},
        },
        {
            name => 'mcpan/changes/distribution/DIST',
            args => {url=>'https://metacpan.org/changes/distribution/Module-XSOrPP'},
            result => {site=>'mcpan', dist=>'Module-XSOrPP'},
        },
        {
            name => 'mcpan/requires/distribution/DIST',
            args => {url=>'https://metacpan.org/requires/distribution/Module-XSOrPP?sort=[[2,1]]'},
            result => {site=>'mcpan', dist=>'Module-XSOrPP'},
        },

        {
            name => 'sco/dist/DIST',
            args => {url=>'http://search.cpan.org/dist/Foo-Bar/'},
            result => {site=>'sco', dist=>'Foo-Bar'},
        },
        {
            name => 'sco/perldoc?MOD',
            args => {url=>'http://search.cpan.org/perldoc?Foo::Bar'},
            result => {site=>'sco', module=>'Foo::Bar'},
        },
        {
            name => 'sco/search?mode=module&query=MOD',
            args => {url=>'http://search.cpan.org/search?mode=module&query=DBIx%3A%3AClass'},
            result => {site=>'sco', module=>'DBIx::Class'},
        },
        {
            name => 'sco/search?module=MOD',
            args => {url=>'http://search.cpan.org/search?module=ToolSet'},
            result => {site=>'sco', module=>'ToolSet'},
        },
        {
            name => 'sco/search?module=MOD (#2)',
            args => {url=>'http://search.cpan.org/search?module=Acme::Don\'t'},
            result => {site=>'sco', module=>'Acme::Don::t'},
        },
        {
            name => 'sco/~AUTHOR',
            args => {url=>'http://search.cpan.org/~unera?'},
            result => {site=>'sco', author=>'unera'},
        },
        {
            name => 'sco/~AUTHOR/DIST-REL/lib/MOD.pm',
            args => {url=>'http://search.cpan.org/~unera/DR-SunDown-0.02/lib/DR/SunDown.pm'},
            result => {site=>'sco', author=>'unera', dist=>'DR-SunDown', version=>'0.02', module=>'DR::SunDown'},
        },
        {
            name => 'sco/~AUTHOR/DIST-REL/bin/SCRIPT.pm',
            args => {url=>'http://search.cpan.org/~perlancar/App-PMUtils-1.23/bin/pmpath'},
            result => {site=>'sco', author=>'perlancar', dist=>'App-PMUtils', version=>'1.23', script=>'pmpath'},
        },

        {
            name => 'cpan/authors/id/A/AU/AUTHOR',
            args => {url=>'file:/cpan/authors/id/A/AU/AUTHOR?'},
            result => {site=>'cpan', author=>'AUTHOR'},
        },
        {
            name => 'cpan/authors/id/A/AU/AUTHOR/DIST-VERSION.tar.gz',
            args => {url=>'file:/cpan/authors/id/A/AU/AUTHOR/Foo-Bar-1.0.tar.gz'},
            result => {site=>'cpan', author=>'AUTHOR', release=>'Foo-Bar-1.0.tar.gz', dist=>'Foo-Bar', version=>'1.0'},
        },

        {
            name => 'cpanratings/dist/DIST',
            args => {url=>'http://cpanratings.perl.org/dist/Submodules'},
            result => {site=>'cpanratings', dist=>'Submodules'},
        },

        {
            name => 'perldoc.perl.org/MOD/SUBMOD.html',
            args => {url=>'http://perldoc.perl.org/Module/CoreList.html'},
            result => {site=>'perldoc.perl.org', module=>'Module::CoreList'},
        },

        {
            name => 'rt/(Public/)Dist/Display.html?Queue=DIST',
            args => {url=>'https://rt.cpan.org/Dist/Display.html?Queue=Perinci-Sub-Gen-AccessTable-DBI'},
            result => {site=>'rt', dist=>'Perinci-Sub-Gen-AccessTable-DBI'},
        },

        {
            name => 'unknown',
            args => {url=>'https://www.google.com/'},
            result => undef,
        },
    ],
};
sub extract_cpan_info_from_url {
    my $url = shift;

    my $res;

    # metacpan
    if ($url =~ s!\A$re_proto_http?(?:fastapi\.|api\.)?metacpan\.org/?(?:v\d/)?!!i) {

        $res->{site} = 'mcpan';
        # note: /module is the old URL. /pod might misreport a script as a
        # module, e.g. metacpan.org/pod/cpanm.
        if ($url =~ m!\A(?:pod|module)/
                      ($re_mod)(?:[?&]|\z)!x) {
            $res->{module} = $1;
        } elsif ($url =~ s!\A(?:pod/release/|source/)
                           ($re_author)/($re_dist)-($re_version)/?!!x) {
            $res->{author} = $1;
            $res->{dist} = $2;
            $res->{version} = $3;
            if ($url =~ m!\Alib/((?:[^/]+/)*\w+)\.(?:pm|pod)!) {
                $res->{module} = $1; $res->{module} =~ s!/!::!g;
            } elsif ($url =~ m!\A(?:bin|scripts?)/
                               (?:[^/]+/)*
                               (.+?)
                               $re_end_or_q!x) {
                $res->{script} = $1;
            }
        } elsif ($url =~ m!\A(?:pod/release/|source/)
                           ($re_author)/($re_dist)-($re_version)/?
                           $re_end_or_q!x) {
            $res->{author} = $1;
            $res->{dist} = $2;
            $res->{version} = $3;
        } elsif ($url =~ m!\Arelease/
                           ($re_dist)/?
                           $re_end_or_q!x) {
            $res->{dist} = $1;
        } elsif ($url =~ m!\Arelease/
                           ($re_author)/($re_dist)-($re_version)/?
                           $re_end_or_q!x) {
            $res->{author} = $1;
            $res->{dist} = $2;
            $res->{version} = $3;
        } elsif ($url =~ m!\A(?:changes|requires)/distribution/
                           ($re_dist)/?
                           $re_end_or_q!x) {
            $res->{dist} = $1;
        } elsif ($url =~ m!\Aauthor/
                           ($re_author)/?
                           $re_end_or_q!x) {
            $res->{author} = $1;
        }

    } elsif ($url =~ s!\A$re_proto_http?search\.cpan\.org/?!!i) {

        $res->{site} = 'sco';
        if ($url =~ m!\Adist/
                     ($re_dist)/?
                     $re_end_or_q!x) {
            $res->{dist} = $1;
        } elsif ($url =~ m!\Aperldoc\?
                           (.+?)
                           $re_end_or_q!x) {
            require URI::Escape;
            $res->{module} = URI::Escape::uri_unescape($1);
        } elsif ($url =~ m!\Asearch\?!) {
            # used by perlmonks.org
            if ($url =~ m![?&]mode=module(?:&|\z)! && $
                    url =~ m![?&]query=(.+?)(?:&|\z)!) {
                require URI::Escape;
                $res->{module} = _normalize_mod(URI::Escape::uri_unescape($1));
            } elsif ($url =~ m![?&]mode=dist(?:&|\z)! && $
                    url =~ m![?&]query=(.+?)(?:&|\z)!) {
                require URI::Escape;
                $res->{dist} = URI::Escape::uri_unescape($1);
            } elsif ($url =~ m![?&]mode=author(?:&|\z)! && $
                    url =~ m![?&]query=(.+?)(?:&|\z)!) {
                require URI::Escape;
                $res->{author} = URI::Escape::uri_unescape($1);
            # used by some articles
            } elsif ($url =~ m![?&]module=(.+?)(?:&|\z)!) {
                require URI::Escape;
                $res->{module} = _normalize_mod(URI::Escape::uri_unescape($1));
            }
        } elsif ($url =~ s!\A~(\w+)/?!!) {
            $res->{author} = $1;
            if ($url =~ s!($re_dist)-($re_version)/?!!) {
                $res->{dist} = $1;
                $res->{version} = $2;
                if ($url =~ m!\Alib/((?:[^/]+/)*\w+)\.(?:pm|pod)!) {
                    $res->{module} = $1; $res->{module} =~ s!/!::!g;
                } elsif ($url =~ m!\A(?:bin|scripts?)/
                                   (?:[^/]+/)*
                                   (.+?)
                                   $re_end_or_q!x) {
                    $res->{script} = $1;
                }
            }
        }

    } elsif ($url =~ s!\A$re_proto_http?cpanratings\.perl\.org/?!!i) {

        $res->{site} = 'cpanratings';
        if ($url =~ m!\Adist/
                     ($re_dist)/?
                     $re_end_or_q!x) {
            $res->{dist} = $1;
        }

    } elsif ($url =~ s!\A$re_proto_http?perldoc\.perl\.org/?!!i) {

        $res->{site} = 'perldoc.perl.org';
        if ($url =~ m!^(\w+(?:/\w+)*)\.html!) {
            my $mod = $1;
            $mod =~ s!/!::!g;
            $res->{module} = $mod;
        }

    } elsif ($url =~ s!\A$re_proto_http?rt\.cpan\.org/?!!i) {

        $res->{site} = 'rt';
        if ($url =~ m!\A(?:Public/)?Dist/Display\.html!) {
            if ($url =~ m![?&](?:Queue|Name)=(.+?)(?:&|\z)!) {
                require URI::Escape;
                $res->{dist} = URI::Escape::uri_unescape($1);
            }
        }

    } elsif ($url =~ m!/authors/id/(\w)/\1(\w)/(\1\2\w+)
                       (?:/
                           (?:[^/]+/)* # subdir
                           (($re_dist)-($re_version)\.(?:tar\.\w+|tar|zip|tgz|tbz|tbz2))
                       )?
                       $re_end_or_q!ix) {
        $res->{site} = 'cpan';
        $res->{author} = $3;
        if (defined $4) {
            $res->{release} = $4;
            $res->{dist} = $5;
            $res->{version} = $6;
        }
    }
    $res;
}

1;
# ABSTRACT: Extract/guess information from a URL

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Info::FromURL - Extract/guess information from a URL

=head1 VERSION

This document describes version 0.08 of CPAN::Info::FromURL (from Perl distribution CPAN-Info-FromURL), released on 2017-06-09.

=head1 FUNCTIONS


=head2 extract_cpan_info_from_url

Usage:

 extract_cpan_info_from_url($url) -> hash

Extract/guess information from a URL.

Examples:

=over

=item * Example #1 (mcpan/pod/MOD):

 extract_cpan_info_from_url("https://metacpan.org/pod/Foo::Bar"); # -> { module => "Foo::Bar", site => "mcpan" }

=item * Example #2 (mcpan/module/MOD):

 extract_cpan_info_from_url("metacpan.org/module/Foo?"); # -> { module => "Foo", site => "mcpan" }

=item * Example #3 (mcpan/pod/release/AUTHOR/DIST-VERSION/lib/MOD.pm):

 extract_cpan_info_from_url("http://metacpan.org/pod/release/SRI/Mojolicious-6.46/lib/Mojo.pm");

Result:

 {
   author  => "SRI",
   dist    => "Mojolicious",
   module  => "Mojo",
   site    => "mcpan",
   version => 6.46,
 }

=item * Example #4 (mcpan/pod/release/AUTHOR/DIST-VERSION/bin/SCRIPT):

 extract_cpan_info_from_url("http://metacpan.org/pod/release/PERLANCAR/App-PMUtils-1.23/bin/pmpath");

Result:

 {
   author  => "PERLANCAR",
   dist    => "App-PMUtils",
   script  => "pmpath",
   site    => "mcpan",
   version => 1.23,
 }

=item * Example #5 (mcpan/source/AUTHOR/DIST-VERSION/lib/MOD.pm):

 extract_cpan_info_from_url("http://metacpan.org/source/SRI/Mojolicious-6.46/lib/Mojo.pm?");

Result:

 {
   author  => "SRI",
   dist    => "Mojolicious",
   module  => "Mojo",
   site    => "mcpan",
   version => 6.46,
 }

=item * Example #6 (api.mcpan/source/AUTHOR/DIST-VERSION):

 extract_cpan_info_from_url("http://api.metacpan.org/source/SRI/Mojolicious-6.46?");

Result:

 { author => "SRI", dist => "Mojolicious", site => "mcpan", version => 6.46 }

=item * Example #7 (fastapi.mcpan/v1/module/MODULE):

 extract_cpan_info_from_url("http://fastapi.metacpan.org/v1/module/Moose");

Result:

 { module => "Moose", site => "mcpan" }

=item * Example #8 (mcpan/release/DIST):

 extract_cpan_info_from_url("https://metacpan.org/release/Foo-Bar"); # -> { dist => "Foo-Bar", site => "mcpan" }

=item * Example #9 (mcpan/release/AUTHOR/DIST-VERSION):

 extract_cpan_info_from_url("https://metacpan.org/release/FOO/Bar-1.23");

Result:

 { author => "FOO", dist => "Bar", site => "mcpan", version => 1.23 }

=item * Example #10 (mcpan/author/AUTHOR):

 extract_cpan_info_from_url("https://metacpan.org/author/FOO"); # -> { author => "FOO", site => "mcpan" }

=item * Example #11 (mcpan/changes/distribution/DIST):

 extract_cpan_info_from_url("https://metacpan.org/changes/distribution/Module-XSOrPP");

Result:

 { dist => "Module-XSOrPP", site => "mcpan" }

=item * Example #12 (mcpan/requires/distribution/DIST):

 extract_cpan_info_from_url("https://metacpan.org/requires/distribution/Module-XSOrPP?sort=[[2,1]]");

Result:

 { dist => "Module-XSOrPP", site => "mcpan" }

=item * Example #13 (sco/dist/DIST):

 extract_cpan_info_from_url("http://search.cpan.org/dist/Foo-Bar/"); # -> { dist => "Foo-Bar", site => "sco" }

=item * Example #14 (sco/perldoc?MOD):

 extract_cpan_info_from_url("http://search.cpan.org/perldoc?Foo::Bar");

Result:

 { module => "Foo::Bar", site => "sco" }

=item * Example #15 (sco/search?mode=module&query=MOD):

 extract_cpan_info_from_url("http://search.cpan.org/search?mode=module&query=DBIx%3A%3AClass");

Result:

 { module => "DBIx::Class", site => "sco" }

=item * Example #16 (sco/search?module=MOD):

 extract_cpan_info_from_url("http://search.cpan.org/search?module=ToolSet");

Result:

 { module => "ToolSet", site => "sco" }

=item * Example #17 (sco/search?module=MOD (#2)):

 extract_cpan_info_from_url("http://search.cpan.org/search?module=Acme::Don't");

Result:

 { module => "Acme::Don::t", site => "sco" }

=item * Example #18 (sco/~AUTHOR):

 extract_cpan_info_from_url("http://search.cpan.org/~unera?"); # -> { author => "unera", site => "sco" }

=item * Example #19 (sco/~AUTHOR/DIST-REL/lib/MOD.pm):

 extract_cpan_info_from_url("http://search.cpan.org/~unera/DR-SunDown-0.02/lib/DR/SunDown.pm");

Result:

 {
   author  => "unera",
   dist    => "DR-SunDown",
   module  => "DR::SunDown",
   site    => "sco",
   version => 0.02,
 }

=item * Example #20 (sco/~AUTHOR/DIST-REL/bin/SCRIPT.pm):

 extract_cpan_info_from_url("http://search.cpan.org/~perlancar/App-PMUtils-1.23/bin/pmpath");

Result:

 {
   author  => "perlancar",
   dist    => "App-PMUtils",
   script  => "pmpath",
   site    => "sco",
   version => 1.23,
 }

=item * Example #21 (cpan/authors/id/A/AU/AUTHOR):

 extract_cpan_info_from_url("file:/cpan/authors/id/A/AU/AUTHOR?"); # -> { author => "AUTHOR", site => "cpan" }

=item * Example #22 (cpan/authors/id/A/AU/AUTHOR/DIST-VERSION.tar.gz):

 extract_cpan_info_from_url("file:/cpan/authors/id/A/AU/AUTHOR/Foo-Bar-1.0.tar.gz");

Result:

 {
   author  => "AUTHOR",
   dist    => "Foo-Bar",
   release => "Foo-Bar-1.0.tar.gz",
   site    => "cpan",
   version => "1.0",
 }

=item * Example #23 (cpanratings/dist/DIST):

 extract_cpan_info_from_url("http://cpanratings.perl.org/dist/Submodules");

Result:

 { dist => "Submodules", site => "cpanratings" }

=item * Example #24 (perldoc.perl.org/MOD/SUBMOD.html):

 extract_cpan_info_from_url("http://perldoc.perl.org/Module/CoreList.html");

Result:

 { module => "Module::CoreList", site => "perldoc.perl.org" }

=item * Example #25 (rt/(Public/)Dist/Display.html?Queue=DIST):

 extract_cpan_info_from_url("https://rt.cpan.org/Dist/Display.html?Queue=Perinci-Sub-Gen-AccessTable-DBI");

Result:

 { dist => "Perinci-Sub-Gen-AccessTable-DBI", site => "rt" }

=item * Example #26 (unknown):

 extract_cpan_info_from_url("https://www.google.com/"); # -> undef

=back

Return a hash of information from a CPAN-related URL. Possible keys include:
C<site> (site nickname, include: C<mcpan> [metacpan.org, api.metacpan.org,
fastapi.metacpan.org], C<sco> [search.cpan.org], C<cpanratings>
[cpanratings.perl.org], C<rt> ([rt.cpan.org]), C<cpan> [any normal CPAN mirror]),
C<author> (CPAN author ID), C<module> (module name), C<dist> (distribution name),
C<version> (distribution version). Some keys might not exist, depending on what
information the URL provides. Return undef if URL is not detected to be of some
CPAN-related URL.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$url>* => I<str>

=back

Return value:  (hash)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CPAN-Info-FromURL>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CPAN-Info-FromURL>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Info-FromURL>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<CPAN::Author::FromURL>

L<CPAN::Dist::FromURL>

L<CPAN::Module::FromURL>

L<CPAN::Release::FromURL>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
