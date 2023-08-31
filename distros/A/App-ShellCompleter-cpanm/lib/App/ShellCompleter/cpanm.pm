package App::ShellCompleter::cpanm;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Complete::File qw(complete_file);
use Complete::Util qw(answer_has_entries complete_array_elem);
use Getopt::Long::Complete qw(GetOptionsWithCompletion);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-08'; # DATE
our $DIST = 'App-ShellCompleter-cpanm'; # DIST
our $VERSION = '0.212'; # VERSION

my $noop = sub {};

# complete with list of installed modules
my $comp_installed_mods = sub {
    require Complete::Module;

    my %args = @_;

    log_trace("[_cpanm] Adding completion: installed modules");
    Complete::Module::complete_module(
        word => $args{word},
        path_sep => '::',
    );
};

# complete with installable stuff
my $comp_installable = sub {
    my %args = @_;
    my $word   = $args{word} // '';

    # try completing script name if we are in SCRIPT_MODE
    {
        last unless $ENV{SCRIPT_MODE};
        last unless $word eq '' || $word =~ /\A\w[\w-]*\z/;

        my $dbh = _connect_lcpan() or last;

        my $sth;
        $sth = $dbh->prepare(
            "SELECT name FROM script WHERE name LIKE '$word%' ORDER BY name");
        $sth->execute;
        my @scripts;
        my %seen;
        while (my @row = $sth->fetchrow_array) {
            my $script = $row[0];
            push @scripts, $script unless $seen{$script}++;
        }
        return \@scripts if @scripts;
    }

    # first, we try the cheapest method first, which is local files
    {
        log_trace("[_cpanm] Trying completion: tarballs & dirs");
        local $Complete::Common::OPT_FUZZY = 0;
        local $Complete::Common::OPT_WORD_MODE = 0;
        local $Complete::Common::OPT_CHAR_MODE = 0;
        my $answer = complete_file(
            filter => sub { log_trace("  $_"); /\.(zip|tar\.gz|tar\.bz2)$/i || (-d $_) },
            word   => $word,
        );
    }

    # if that fails, and the word looks like the start of module name, try
    # searching for CPAN module. currently we only query local CPAN for speed.

    # if user already types something that looks like a path instead of module
    # name, like '../' or perhaps 'C:\' (windows) then don't bother to complete
    # with module name because it will just delay things without getting any
    # result.
    {
        last unless $word eq '' || $word =~ /\A(\w+)(::\w+)*(::)?\z/;
        use experimental 'smartmatch';

        my $dbh = _connect_lcpan() or last;

        my $sth;
        my $mod_prefix = $args{mod_prefix} // '';
        my $prefixed_word = "$mod_prefix$word";
        my $num_sep = 0; while ($prefixed_word =~ /::/g) { $num_sep++ }
        if ($prefixed_word eq '') {
            $sth = $dbh->prepare("SELECT name,has_child FROM namespace WHERE name='' AND num_sep=0 ORDER BY name");
        } else {
            $sth = $dbh->prepare("SELECT name,has_child FROM namespace WHERE name LIKE '$prefixed_word%' AND num_sep=$num_sep ORDER BY name");
        }
        $sth->execute;
        my @mods;
        while (my @row = $sth->fetchrow_array) {
            my $mod = $row[0];
            $mod =~ s/\A\Q$mod_prefix\E//;
            push @mods, $mod unless grep { $_ eq $mod } @mods;
            if ($row[1]) {
                $mod .= '::';
                push @mods, $mod unless grep { $_ eq $mod } @mods;
            }
        };
        return \@mods if @mods;
    }

    # TODO module name can be suffixed with '@<version>'

    [];
};

sub _connect_lcpan {
    no warnings 'once';

    eval "use App::lcpan 0.32"; ## no critic: TestingAndDebugging::ProhibitNoStrict
    if ($@) {
        log_trace("[_cpanm] App::lcpan not available, skipped ".
                         "trying to complete from CPAN module names");
        return;
    }

    require Perinci::CmdLine::Util::Config;

    my %lcpanargs;
    my $res = Perinci::CmdLine::Util::Config::read_config(
        program_name => "lcpan",
    );
    unless ($res->[0] == 200) {
        log_trace("[_cpanm] Can't get config for lcpan: %s", $res);
        last;
    }
    my $config = $res->[2];

    $res = Perinci::CmdLine::Util::Config::get_args_from_config(
        config => $config,
        args   => \%lcpanargs,
        #subcommand_name => 'update',
        meta   => $App::lcpan::SPEC{update},
    );
    unless ($res->[0] == 200) {
        log_trace("[_cpanm] Can't get args from config: %s", $res);
        return;
    }
    App::lcpan::_set_args_default(\%lcpanargs);
    my $dbh = App::lcpan::_connect_db('ro', $lcpanargs{cpan}, $lcpanargs{index_name});
}

sub run_completer {
    my %cargs = @_;

    die "This script is for shell completion only\n"
        unless $ENV{GETOPT_LONG_DUMP} || $ENV{COMP_LINE} || $ENV{COMMAND_LINE};

    # the list of options is taken from Menlo::CLI:Compat. should be updated
    # from time to time.
    GetOptionsWithCompletion(
        sub {
            my %args  = @_;
            my $type      = $args{type};
            my $word      = $args{word};
            if ($type eq 'arg') {
                log_trace("[_cpanm] Completing arg");
                my $seen_opts = $args{seen_opts};
                if ($seen_opts->{'--uninstall'} || $seen_opts->{'--reinstall'}) {
                    return $comp_installed_mods->(word=>$word);
                } else {
                    return $comp_installable->(
                        mod_prefix => $cargs{mod_prefix},
                        word=>$word, mirror=>$seen_opts->{'--mirror'});
                }
            } elsif ($type eq 'optval') {
                my $ospec = $args{ospec};
                my $opt   = $args{opt};
                log_trace("[_cpanm] Completing optval (opt=$opt)");
                if ($ospec eq 'l|local-lib=s' ||
                        $ospec eq 'L|local-lib-contained=s') {
                    return complete_file(filter=>'d', word=>$word);
                } elsif ($ospec eq 'format=s') {
                    return complete_array_elem(
                        array=>[qw/tree json yaml dists/], word=>$word);
                } elsif ($ospec eq 'cpanfile=s') {
                    return complete_file(word=>$word);
                }
            }
            return [];
        },
        'f|force'   => $noop,
        'n|notest!' => $noop,
        'test-only' => $noop,
        'S|sudo!'   => $noop,
        'v|verbose' => $noop,
        'verify!'   => $noop,
        'q|quiet!'  => $noop,
        'h|help'    => $noop,
        'V|version' => $noop,
        'perl=s'          => $noop,
        'l|local-lib=s'   => $noop,
        'L|local-lib-contained=s' => $noop,
        'self-contained!' => $noop,
        'exclude-vendor!' => $noop,
        'mirror=s@'       => $noop,
        'mirror-only!'    => $noop,
        'mirror-index=s'  => $noop,
        'M|from=s'        => $noop, # url (this is --mirror and --mirror-only combined)
        'cpanmetadb=s'    => $noop,
        'cascade-search!' => $noop,
        'prompt!'         => $noop,
        'installdeps'     => $noop,
        'skip-installed!' => $noop,
        'skip-satisfied!' => $noop,
        'reinstall'       => $noop,
        'interactive!'    => $noop,
        'i|install'       => $noop,
        'info'            => $noop,
        'look'            => $noop,
        'U|uninstall'     => $noop,
        'self-upgrade'    => $noop,
        'uninst-shadows!' => $noop,
        'lwp!'    => $noop,
        'wget!'   => $noop,
        'curl!'   => $noop,
        'auto-cleanup=s' => $noop,
        'man-pages!' => $noop,
        'scandeps'   => $noop,
        'showdeps'   => $noop,
        'format=s'   => $noop,
        'save-dists=s' => $noop,
        'skip-configure!' => $noop,
        'static-install!' => $noop,
        'dev!'       => $noop,
        'metacpan!'  => $noop,
        'report-perl-version!' => $noop,
        'configure-timeout=i' => $noop,
        'build-timeout=i' => $noop,
        'test-timeout=i' => $noop,
        'with-develop' => $noop,
        'without-develop' => $noop,
        'with-configure' => $noop,
        'without-configure' => $noop,
        'with-feature=s' => $noop,
        'without-feature=s' => $noop,
        'with-all-features' => $noop,
        'pp|pureperl!' => $noop,
        "cpanfile=s" => $noop,
        #$self->install_type_handlers,
        #$self->build_args_handlers,
    );
}

1;
# ABSTRACT: Shell completion for cpanm

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ShellCompleter::cpanm - Shell completion for cpanm

=head1 VERSION

This document describes version 0.212 of App::ShellCompleter::cpanm (from Perl distribution App-ShellCompleter-cpanm), released on 2023-07-08.

=head1 SYNOPSIS

See L<_cpanm> included in this distribution.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ShellCompleter-cpanm>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BashCompleter-cpanm>.

=head1 SEE ALSO

L<Bash::Completion::Plugins::cpanm>, which focuses on completing module name
remotely using MetaCPAN API. This module, on the other hand, focuses on
completing C<cpanm> command-line options.

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

This software is copyright (c) 2023, 2021, 2020, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ShellCompleter-cpanm>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
