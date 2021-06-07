package App::ThisDist;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-02'; # DATE
our $DIST = 'App-ThisDist'; # DIST
our $VERSION = '0.009'; # VERSION

use strict;
use warnings;
use Log::ger;

use File::chdir;

use Exporter qw(import);
our @EXPORT_OK = qw(this_dist);

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

1;
# ABSTRACT: Print Perl {distribution,module,author,...} associated with current directory

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ThisDist - Print Perl {distribution,module,author,...} associated with current directory

=head1 VERSION

This document describes version 0.009 of App::ThisDist (from Perl distribution App-ThisDist), released on 2021-04-02.

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ThisDist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ThisDist>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-ThisDist/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::DistUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
