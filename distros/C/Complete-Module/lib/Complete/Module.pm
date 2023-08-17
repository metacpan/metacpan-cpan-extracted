package Complete::Module;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Complete::Common qw(:all);
use Exporter qw(import);
use List::Util qw(uniq);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-19'; # DATE
our $DIST = 'Complete-Module'; # DIST
our $VERSION = '0.263'; # VERSION

our %SPEC;

our @EXPORT_OK = qw(complete_module);

our $OPT_SHORTCUT_PREFIXES;
if ($ENV{COMPLETE_MODULE_OPT_SHORTCUT_PREFIXES}) {
    $OPT_SHORTCUT_PREFIXES =
        { split /=|;/, $ENV{COMPLETE_MODULE_OPT_SHORTCUT_PREFIXES} };
} else {
    $OPT_SHORTCUT_PREFIXES = {
        #cp  => 'Catalyst/Plugin/' # candidate
        df  => 'DateTime/Format/',
        #dp  => 'Dancer/Plugin/', # candidate
        #d2p  => 'Dancer2/Plugin/', # candidate
        dz  => 'Dist/Zilla/',
        dzb => 'Dist/Zilla/PluginBundle/',
        dzp => 'Dist/Zilla/Plugin/',
        dzr => 'Dist/Zilla/Role/',
        #pa  => 'Plack/App/', # candidate
        #pc  => 'POE/Component/', # candidate
        #pc  => 'Perl/Critic/', # candidate?
        #pcp => 'Perl/Critic/Policy/', # candidate?
        #pd  => 'Padre/Document/', # candidate
        #pm  => 'Plack/Middleware/', # candidate
        #pp  => 'Padre/Plugin/', # candidate
        pw  => 'Pod/Weaver/',
        pwb => 'Pod/Weaver/PluginBundle/',
        pwp => 'Pod/Weaver/Plugin/',
        pwr => 'Pod/Weaver/Role/',
        pws => 'Pod/Weaver/Section/',
        #rtx => 'RT/Extension/', # candidate
        #se  => 'Search/Elasticsearch/', # candidate
        #sec => 'Search/Elasticsearch/Client/', # candidate
        #ser => 'Search/Elasticsearch/Role/', # candidate
        #tp  => 'Template/Plugin/', # candidate
        #tw  => 'Tickit/Widget/', # candidate

        # MooseX, MooX
        # Moose::Exception
        # Finance::Bank
        # Mojo::*, MojoX::*, Mojolicious::*
    };
}

$SPEC{complete_module} = {
    v => 1.1,
    summary => 'Complete with installed Perl module names',
    description => <<'_',

For each directory in `@INC` (coderefs are ignored), find Perl modules and
module prefixes which have `word` as prefix. So for example, given `Te` as
`word`, will return e.g. `[Template, Template::, Term::, Test, Test::, Text::]`.
Given `Text::` will return `[Text::ASCIITable, Text::Abbrev, ...]` and so on.

This function has a bit of overlapping functionality with <pm:Module::List>, but
this function is geared towards shell tab completion. Compared to Module::List,
here are some differences: 1) list modules where prefix is incomplete; 2)
interface slightly different; 3) (currently) doesn't do recursing; 4) contains
conveniences for completion, e.g. map casing, expand intermediate paths (see
`Complete` for more details on those features), autoselection of path separator
character, some shortcuts, and so on.

_
    args => {
        %arg_word,
        path_sep => {
            summary => 'Path separator',
            schema  => 'str*',
            description => <<'_',

For convenience in shell (bash) completion, instead of defaulting to `::` all
the time, will look at `word`. If word does not contain any `::` then will
default to `/`. This is because `::` (contains colon) is rather problematic as
it is by default a word-break character in bash and the word needs to be quoted
to avoid word-breaking by bash.

_
        },
        find_pm => {
            summary => 'Whether to find .pm files',
            schema  => 'bool*',
            default => 1,
        },
        find_pod => {
            summary => 'Whether to find .pod files',
            schema  => 'bool*',
            default => 1,
        },
        find_pmc => {
            summary => 'Whether to find .pmc files',
            schema  => 'bool*',
            default => 1,
        },
        find_prefix => {
            summary => 'Whether to find module prefixes',
            schema  => 'bool*',
            default => 1,
        },
        ns_prefix => {
            summary => 'Namespace prefix',
            schema  => 'perl::modname*',
            description => <<'_',

This is useful if you want to complete module under a specific namespace
(instead of the root). For example, if you set `ns_prefix` to
`Dist::Zilla::Plugin` (or `Dist::Zilla::Plugin::`) and word is `F`, you can get
`['FakeRelease', 'FileFinder::', 'FinderCode']` (those are modules under the
`Dist::Zilla::Plugin::` namespace).

_
        },
        ns_prefixes => {
            summary => 'Namespace prefixes',
            schema => ['array*', of=>'perl::modname*'],
            description => <<'_',

If you specify this instead of `ns_prefix`, then the routine will search from
all the prefixes instead of just one.

_
        },
        recurse => {
            schema => 'bool*',
            cmdline_aliases => {r=>{}},
        },
        recurse_matching => {
            schema => ['str*', in=>['level-by-level', 'all-at-once']],
            default => 'level-by-level',
        },
        exclude_leaf => {
            schema => 'bool*',
        },
        exclude_dir => {
            schema => 'bool*',
        },
    },
    args_rels => {
        choose_one => [qw/ns_prefix ns_prefixes/],
    },
    result_naked => 1,
};
sub complete_module {
    require Complete::Path;

    my %args = @_;

    my $word = $args{word} // '';
    #log_trace('[compmod] Entering complete_module(), word=<%s>', $word);
    #log_trace('[compmod] args=%s', \%args);

    # convenience: allow Foo/Bar.{pm,pod,pmc}
    $word =~ s/\.(pm|pmc|pod)\z//;

    # convenience (and compromise): if word doesn't contain :: we use the
    # "safer" separator /, but if already contains '::' we use '::'. (Can also
    # use '.' if user uses that.) Using "::" in bash means user needs to use
    # quote (' or ") to make completion behave as expected since : is by default
    # a word break character in bash/readline.
    my $sep = $args{path_sep};
    unless (defined $sep) {
        $sep = $word =~ /::/ ? '::' :
            $word =~ /\./ ? '.' : '/';
    }

    # find shortcut prefixes
    {
        my $tmp = lc $word;
        for (keys %$OPT_SHORTCUT_PREFIXES) {
            if ($tmp =~ /\A\Q$_\E(?:(\Q$sep\E).*|\z)/) {
                substr($word, 0, length($_) + length($1 // '')) =
                    $OPT_SHORTCUT_PREFIXES->{$_};
                last;
            }
        }
    }

    $word =~ s!(::|/|\.)!::!g;

    my $find_pm      = $args{find_pm}     // 1;
    my $find_pmc     = $args{find_pmc}    // 1;
    my $find_pod     = $args{find_pod}    // 1;
    my $find_prefix  = $args{find_prefix} // 1;

    my @ns_prefixes  = $args{ns_prefixes} ? @{$args{ns_prefixes}} : ($args{ns_prefix});
    my $res = [];
    for my $ns_prefix (@ns_prefixes) {
        $ns_prefix //= '';
        $ns_prefix =~ s/(::)+\z//;

        #log_trace('[compmod] invoking complete_path, word=<%s>', $word);
        my $cp_res = Complete::Path::complete_path(
            word => $word,
            starting_path => $ns_prefix,
            list_func => sub {
                my ($path, $intdir, $isint) = @_;
                (my $fspath = $path) =~ s!::!/!g;
                my @res;
                for my $inc (@INC) {
                    next if ref($inc);
                    my $dir = $inc . (length($fspath) ? "/$fspath" : "");
                    opendir my($dh), $dir or next;
                    for (readdir $dh) {
                        next if $_ eq '.' || $_ eq '..';
                        next unless /\A\w+(\.\w+)?\z/;
                        my $is_dir = (-d "$dir/$_");
                        next if $isint && !$is_dir;
                        push @res, "$_\::" if $is_dir && ($isint || $find_prefix);
                        push @res, $1 if /(.+)\.pm\z/  && $find_pm;
                        push @res, $1 if /(.+)\.pmc\z/ && $find_pmc;
                        push @res, $1 if /(.+)\.pod\z/ && $find_pod;
                    }
                }
                [sort(uniq(@res))];
            },
            path_sep => '::',
            is_dir_func => sub { }, # not needed, we already suffix "dirs" with ::
            recurse => $args{recurse},
            recurse_matching => $args{recurse_matching},
            exclude_leaf => $args{exclude_leaf},
            exclude_dir  => $args{exclude_dir},
        );
        push @$res, @$cp_res;
    } # for $ns_prefix

    # dedup
    {
        last unless @ns_prefixes > 1;
        my $res_dedup = [];
        my %seen;
        for (@$res) { push @$res_dedup, $_ unless $seen{$_}++ }
        $res = $res_dedup;
    }

  FILTER_WITH_SCHEMA: {
        my $sch = $args{_schema};
        last unless $sch;

        my $fres = [];
        for my $word (@$res) {
            log_trace("[compmod] Validating word %s with validator ...", $word);
            if ($sch->[1]{in} && !(grep { index($_, $word)==0 } @{ $sch->[1]{in} })) {
                next;
            }
            push @$fres, $word;
        }
        $res = $fres;
    }

    for (@$res) { s/::/$sep/g }

    $res = { words=>$res, path_sep=>$sep };
    #log_trace('[compmod] Leaving complete_module(), result=<%s>', $res);
    $res;
}

1;
# ABSTRACT: Complete with installed Perl module names

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Module - Complete with installed Perl module names

=head1 VERSION

This document describes version 0.263 of Complete::Module (from Perl distribution Complete-Module), released on 2023-03-19.

=head1 SYNOPSIS

 use Complete::Module qw(complete_module);
 my $res = complete_module(word => 'Text::A');
 # -> ['Text::ANSI', 'Text::ANSITable', 'Text::ANSITable::', 'Text::Abbrev']

=head1 SETTINGS

=head2 C<$Complete::Module::OPT_SHORTCUT_PREFIXES> => hash

Shortcut prefixes. The default is:

 {
   bs  => "Bencher/Scenario/",
   bss => "Bencher/Scenarios/",
   df  => "DateTime/Format/",
   dz  => "Dist/Zilla/",
   dzb => "Dist/Zilla/PluginBundle/",
   dzp => "Dist/Zilla/Plugin/",
   dzr => "Dist/Zilla/Role/",
   pw  => "Pod/Weaver/",
   pwb => "Pod/Weaver/PluginBundle/",
   pwp => "Pod/Weaver/Plugin/",
   pwr => "Pod/Weaver/Role/",
   pws => "Pod/Weaver/Section/",
   rp  => "Regexp/Pattern/",
   ss  => "Sah/Schema/",
   sss => "Sah/Schemas/",
 }
If user types one of the keys, it will be replaced with the matching value from
this hash.

=head1 FUNCTIONS


=head2 complete_module

Usage:

 complete_module(%args) -> any

Complete with installed Perl module names.

For each directory in C<@INC> (coderefs are ignored), find Perl modules and
module prefixes which have C<word> as prefix. So for example, given C<Te> as
C<word>, will return e.g. C<[Template, Template::, Term::, Test, Test::, Text::]>.
Given C<Text::> will return C<[Text::ASCIITable, Text::Abbrev, ...]> and so on.

This function has a bit of overlapping functionality with L<Module::List>, but
this function is geared towards shell tab completion. Compared to Module::List,
here are some differences: 1) list modules where prefix is incomplete; 2)
interface slightly different; 3) (currently) doesn't do recursing; 4) contains
conveniences for completion, e.g. map casing, expand intermediate paths (see
C<Complete> for more details on those features), autoselection of path separator
character, some shortcuts, and so on.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<exclude_dir> => I<bool>

(No description)

=item * B<exclude_leaf> => I<bool>

(No description)

=item * B<find_pm> => I<bool> (default: 1)

Whether to find .pm files.

=item * B<find_pmc> => I<bool> (default: 1)

Whether to find .pmc files.

=item * B<find_pod> => I<bool> (default: 1)

Whether to find .pod files.

=item * B<find_prefix> => I<bool> (default: 1)

Whether to find module prefixes.

=item * B<ns_prefix> => I<perl::modname>

Namespace prefix.

This is useful if you want to complete module under a specific namespace
(instead of the root). For example, if you set C<ns_prefix> to
C<Dist::Zilla::Plugin> (or C<Dist::Zilla::Plugin::>) and word is C<F>, you can get
C<['FakeRelease', 'FileFinder::', 'FinderCode']> (those are modules under the
C<Dist::Zilla::Plugin::> namespace).

=item * B<ns_prefixes> => I<array[perl::modname]>

Namespace prefixes.

If you specify this instead of C<ns_prefix>, then the routine will search from
all the prefixes instead of just one.

=item * B<path_sep> => I<str>

Path separator.

For convenience in shell (bash) completion, instead of defaulting to C<::> all
the time, will look at C<word>. If word does not contain any C<::> then will
default to C</>. This is because C<::> (contains colon) is rather problematic as
it is by default a word-break character in bash and the word needs to be quoted
to avoid word-breaking by bash.

=item * B<recurse> => I<bool>

(No description)

=item * B<recurse_matching> => I<str> (default: "level-by-level")

(No description)

=item * B<word>* => I<str> (default: "")

Word to complete.


=back

Return value:  (any)

=head1 ENVIRONMENT

=head2 C<COMPLETE_MODULE_OPT_SHORTCUT_PREFIXES> => str

Can be used to set the default for C<$Complete::Module::OPT_SHORTCUT_PREFIXES>.
It should be in the form of:

 shortcut1=Value1;shortcut2=Value2;...

For example:

 dzp=Dist/Zilla/Plugin/;pwp=Pod/Weaver/Plugin/

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Module>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Module>.

=head1 SEE ALSO

L<Complete::Perl>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

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

This software is copyright (c) 2023, 2021, 2017, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Module>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
