package Complete::Module;

our $DATE = '2017-09-08'; # DATE
our $VERSION = '0.260'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

use Complete::Common qw(:all);
use List::Util qw(uniq);

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
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
            schema  => 'str*',
            description => <<'_',

This is useful if you want to complete module under a specific namespace
(instead of the root). For example, if you set `ns_prefix` to
`Dist::Zilla::Plugin` (or `Dist::Zilla::Plugin::`) and word is `F`, you can get
`['FakeRelease', 'FileFinder::', 'FinderCode']` (those are modules under the
`Dist::Zilla::Plugin::` namespace).

_
        },
    },
    result_naked => 1,
};
sub complete_module {
    require Complete::Path;

    my %args = @_;

    my $word = $args{word} // '';
    #$log->tracef('[compmod] Entering complete_module(), word=<%s>', $word);
    #$log->tracef('[compmod] args=%s', \%args);

    my $ns_prefix = $args{ns_prefix} // '';
    $ns_prefix =~ s/(::)+\z//;

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

    #$log->tracef('[compmod] invoking complete_path, word=<%s>', $word);
    my $res = Complete::Path::complete_path(
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
    );

    for (@$res) { s/::/$sep/g }

    $res = { words=>$res, path_sep=>$sep };
    #$log->tracef('[compmod] Leaving complete_module(), result=<%s>', $res);
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

This document describes version 0.260 of Complete::Module (from Perl distribution Complete-Module), released on 2017-09-08.

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

=item * B<find_pm> => I<bool> (default: 1)

Whether to find .pm files.

=item * B<find_pmc> => I<bool> (default: 1)

Whether to find .pmc files.

=item * B<find_pod> => I<bool> (default: 1)

Whether to find .pod files.

=item * B<find_prefix> => I<bool> (default: 1)

Whether to find module prefixes.

=item * B<ns_prefix> => I<str>

Namespace prefix.

This is useful if you want to complete module under a specific namespace
(instead of the root). For example, if you set C<ns_prefix> to
C<Dist::Zilla::Plugin> (or C<Dist::Zilla::Plugin::>) and word is C<F>, you can get
C<['FakeRelease', 'FileFinder::', 'FinderCode']> (those are modules under the
C<Dist::Zilla::Plugin::> namespace).

=item * B<path_sep> => I<str>

Path separator.

For convenience in shell (bash) completion, instead of defaulting to C<::> all
the time, will look at C<word>. If word does not contain any C<::> then will
default to C</>. This is because C<::> (contains colon) is rather problematic as
it is by default a word-break character in bash and the word needs to be quoted
to avoid word-breaking by bash.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Module>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete::Perl>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
