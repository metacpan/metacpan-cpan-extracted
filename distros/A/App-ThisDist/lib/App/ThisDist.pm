package App::ThisDist;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-03'; # DATE
our $DIST = 'App-ThisDist'; # DIST
our $VERSION = '0.005'; # VERSION

use strict;
use warnings;
use Log::ger;

use File::chdir;

use Exporter qw(import);
our @EXPORT_OK = qw(this_dist);

sub this_dist {
    require File::Slurper;

    my ($dir) = @_;

    if (!$dir) {
        require Cwd;
        $dir = Cwd::getcwd();
    }
    (my $dir_basename = $dir) =~ s!.+[/\\]!!;

    local $CWD = $dir;

    my $dist;
  GUESS: {
      FROM_DIST_INI: {
            if (-f "dist.ini") {
                my $ct = File::Slurper::read_text("dist.ini");
                while ($ct =~ /^\s*name\s*=\s*(.+)/mg) {
                    $dist = $1;
                    log_debug "this-dist: Guessed dist=$dist from dist.ini\n";
                    last GUESS;
                }
            }
        }

      FROM_GIT_CONFIG: {
            if (-f ".git/config") {
                my $ct = File::Slurper::read_text(".git/config");
                while ($ct =~ /^\s*url\s*=\s*(.+)/mg) {
                    my $url = $1;
                    log_debug "this-dist: Found URL '$url'\n";
                    require CPAN::Dist::FromURL;
                    my $res = CPAN::Dist::FromURL::extract_cpan_dist_from_url($url);
                    if (defined $dist) {
                        log_debug "this-dist: Guessed dist=$dist from .git/config URL '$url'\n";
                        last GUESS;
                    }
                }
            }
        }

      FROM_REPO_NAME: {
            require CPAN::Dist::FromRepoName;
            my $res = CPAN::Dist::FromRepoName::extract_cpan_dist_from_repo_name($dir_basename);
            if (defined $res) {
                $dist = $res;
                log_debug "this-dist: Guessed dist=$dist from repo name '$dir_basename'\n";
                last GUESS;
            }
        }
    }
    $dist;
}

1;
# ABSTRACT: Print Perl {distribution,module,author,...} associated with current directory

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ThisDist - Print Perl {distribution,module,author,...} associated with current directory

=head1 VERSION

This document describes version 0.005 of App::ThisDist (from Perl distribution App-ThisDist), released on 2020-10-03.

=head1 DESCRIPTION

See included scripts:

=over

=item * L<this-dist>

=back



=head1 FUNCTIONS

=head2 this_dist

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ThisDist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ThisDist>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ThisDist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::DistUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
