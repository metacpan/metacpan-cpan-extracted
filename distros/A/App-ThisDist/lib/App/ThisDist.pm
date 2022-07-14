package App::ThisDist;

use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
use File::chdir;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-05'; # DATE
our $DIST = 'App-ThisDist'; # DIST
our $VERSION = '0.016'; # VERSION

our @EXPORT_OK = qw(this_dist this_mod);

sub this_dist {
    require File::Slurper;

    my ($dir, $extract_version) = @_;

    if (defined $dir) {
        log_debug "chdir to $dir ...";
    }

    local $CWD = $dir if defined $dir;

    unless (defined $dir) {
        require Cwd;
        $dir = Cwd::getcwd();
    }

    (my $dir_basename = $dir) =~ s!.+[/\\]!!;

    my ($distname, $distver);

  GUESS: {
      FROM_DISTMETA_2: {
            for my $file ("MYMETA.json", "META.json") {
                next unless -f $file;
                log_debug "Found distribution metadata $file";
                require JSON::PP;
                my $content = File::Slurper::read_text($file);
                my $meta = JSON::PP::decode_json($content);
                if ($meta && ref $meta eq 'HASH' && defined $meta->{name}) {
                    $distname = $meta->{name};
                    log_debug "Got distname=$distname from distribution metadata $file";
                    if (defined $meta->{version}) {
                        $distver = $meta->{version};
                        log_debug "Got distver=$distver from distribution metadata $file";
                    }
                    last GUESS;
                } else {
                    last;
                }
            }
        }

      FROM_DISTMETA_1_1: {
            for my $file ("MYMETA.yml", "META.yml") {
                next unless -f $file;
                log_debug "Found distribution metadata $file";
                require YAML::XS;
                my $meta = YAML::XS::LoadFile($file);
                if ($meta && ref $meta eq 'HASH' && defined $meta->{name}) {
                    $distname = $meta->{name};
                    log_debug "Got distname=$distname from distribution metadata $file";
                    if (defined $meta->{version}) {
                        $distver = $meta->{version};
                        log_debug "Got distver=$distver from distribution metadata $file";
                    }
                    last GUESS;
                } else {
                    last;
                }
            }
        }

      FROM_DIST_INI: {
            last unless -f "dist.ini";
            log_debug "Found dist.ini";
            my $content = File::Slurper::read_text("dist.ini");
            while ($content =~ /^\s*name\s*=\s*(.+)/mg) {
                $distname = $1;
                log_debug "Got distname=$distname from dist.ini";
                if ($content =~ /^version\s*=\s*(.+)/m) {
                    $distver = $1;
                    log_debug "Got distver=$distver from dist.ini";
                }
                last GUESS;
            }
        }

      FROM_MAKEFILE_PL: {
            last unless -f "Makefile.PL";
            log_debug "Found Makefile.PL";
            my $content = File::Slurper::read_text("Makefile.PL");
            unless ($content =~ /use ExtUtils::MakeMaker/) {
                log_debug "Makefile.PL doesn't seem to use ExtUtils::MakeMaker, skipped";
                last;
            }
            unless ($content =~ /["']DISTNAME["']\s*=>\s*["'](.+?)["']/) {
                log_debug "Couldn't extract value of DISTNAME from Makefile.PL, skipped";
                last;
            }
            $distname = $1;
            log_debug "Got distname=$distname from Makefile.PL";
            if ($content =~ /["']VERSION["']\s*=>\s*["'](.+?)["']/) {
                $distver = $1;
                log_debug "Got distver=$distver from Makefile.PL";
            }
            last GUESS;
        }

      FROM_MAKEFILE: {
            last unless -f "Makefile";
            log_debug "Found Makefile";
            my $content = File::Slurper::read_text("Makefile");
            unless ($content =~ /by MakeMaker/) {
                log_debug "Makefile doesn't seem to be generated from MakeMaker.PL, skipped";
                last;
            }
            unless ($content =~ /^DISTNAME\s*=\s*(.+)/m) {
                log_debug "Couldn't extract value of DISTNAME from Makefile, skipped";
                last;
            }
            $distname = $1;
            log_debug "Got distname=$distname from Makefile";
            if ($content =~ /^VERSION\s*=\s*(.+)/m) {
                $distver = $1;
                log_debug "Got distver=$distver from Makefile";
            }
            last GUESS;
        }

      FROM_BUILD_PL: {
            last unless -f "Build.PL";
            log_debug "Found Build.PL";
            my $content = File::Slurper::read_text("Build.PL");
            unless ($content =~ /use Module::Build/) {
                log_debug "Build.PL doesn't seem to use Module::Build, skipped";
                last;
            }
            unless ($content =~ /module_name\s*=>\s*["'](.+?)["']/s) {
                log_debug "Couldn't extract value of module_name from Build.PL, skipped";
                last;
            }
            $distname = $1; $distname =~ s/::/-/g;
            log_debug "Got distname=$distname from Build.PL";
            # XXX extract version?
            last GUESS;
        }

        # note: Build script does not contain dist name

      FROM_GIT_CONFIG: {
            last; # currently disabled
            last unless -f ".git/config";
            log_debug "Found .git/config";
            my $content = File::Slurper::read_text(".git/config");
            while ($content =~ /^\s*url\s*=\s*(.+)/mg) {
                my $url = $1;
                log_debug "Found URL '$url' in git config";
                require CPAN::Dist::FromURL;
                my $res = CPAN::Dist::FromURL::extract_cpan_dist_from_url($url);
                if (defined $distname) {
                    log_debug "Guessed distname=$distname from .git/config URL '$url'";
                    # XXX extract version?
                    last GUESS;
                }
            }
        }

      FROM_REPO_NAME: {
            last; # currently disabled
            log_debug "Using CPAN::Dist::FromRepoName to guess from dir name ...";
            require CPAN::Dist::FromRepoName;
            my $res = CPAN::Dist::FromRepoName::extract_cpan_dist_from_repo_name($dir_basename);
            if (defined $res) {
                $distname = $res;
                log_debug "Guessed distname=$distname from repo name '$dir_basename'";
                # XXX extract version?
                last GUESS;
            }
        }

        log_debug "Can't guess distribution, giving up";
    }
    $extract_version ? "$distname ".(defined $distver ? $distver : "?") : $distname;
}

sub this_mod {
    my $res = this_dist(@_);
    return $res unless defined $res && $res =~ /\S/;
    $res =~ s/-/::/g;
    $res;
}

1;
# ABSTRACT: Print Perl {distribution,module,author,...} associated with current directory

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ThisDist - Print Perl {distribution,module,author,...} associated with current directory

=head1 VERSION

This document describes version 0.016 of App::ThisDist (from Perl distribution App-ThisDist), released on 2022-06-05.

=head1 DESCRIPTION

See included scripts:

=over

=item * L<this-dist>

=item * L<this-mod>

=back



=head1 FUNCTIONS

=head2 this_dist

Usage:

 my $dist = this_dist([ $dir ] [ , $extract_version? ]); => e.g. "App-Foo" or "App-Foo 1.23"

If C<$dir> is not specified, will default to current directory. If
C<$extract_version> is set to true, will also try to extract distribution
version and will return "?" for version when version cannot be found.

=head2 this_mod

A thin wrapper for L</this_dist>. It just converts "-" in the result to "::", so
"Foo-Bar" becomes "Foo::Bar".

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ThisDist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ThisDist>.

=head1 SEE ALSO

L<App::DistUtils>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ThisDist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
