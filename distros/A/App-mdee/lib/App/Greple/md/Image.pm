package App::Greple::md::Image;

# The files of the images of a Markdown file.  They are shown by
# Text::ANSI::Image; this module finds them.

use v5.26;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = qw(local_path);

use File::Basename qw(dirname);
use File::Spec;
use Cwd qw(realpath);

# The local file of the image of a URL, or undef.  Nothing is fetched
# from the network.
#
#   images/a.png, /path/a.png
#       a path, relative to the directory of the Markdown file
#   https://raw.githubusercontent.com/OWNER/REPO/BRANCH/PATH
#   https://github.com/OWNER/REPO/blob/BRANCH/PATH (or raw, ?raw=true)
#       PATH in the work tree of the git repository which has the
#       Markdown file, when one of its remotes is github.com/OWNER/REPO.
#       The README files of CPAN distributions point to their images
#       this way, for MetaCPAN.  The branch is not looked at: the file
#       is the one in the work tree.
sub local_path {
    my($url, $dir) = @_;
    $dir = File::Spec->rel2abs($dir);
    if ($url !~ m{^[a-z][a-z0-9+.-]*:}i) {
	return $url =~ m{^/} ? $url : "$dir/$url";
    }
    my($owner, $repo, $rest) =
	$url =~ m{^https://raw\.githubusercontent\.com/([^/]+)/([^/]+)/(.+)}i ? ($1, $2, $3) :
	$url =~ m{^https://github\.com/([^/]+)/([^/]+)/(?:blob|raw)/(.+)}i    ? ($1, $2, $3) :
	return;
    $repo =~ s/\.git$//;
    $rest =~ s/[?#].*//s;
    my $top = git_top($dir) // return;
    grep { m{github\.com[:/]\Q$owner\E/\Q$repo\E(?:\.git)?/?$}i } remote_urls($top)
	or return;
    # BRANCH/PATH: the branch may have slashes, so the path is the
    # longest tail that names a file in the work tree.  No part of it
    # may go up, and the file must be in the work tree.
    my @part = map { s/%([0-9A-Fa-f]{2})/chr hex $1/ger } split m{/}, $rest, -1;
    return if grep { $_ eq '' or $_ eq '.' or $_ eq '..' or m{/} } @part;
    my $real_top = realpath($top) // return;
    for my $i (1 .. $#part) {
	my $path = join '/', $top, @part[$i .. $#part];
	-f $path or next;
	my $real = realpath($path) // next;
	return $real if index($real, "$real_top/") == 0;
    }
    return;
}

# The top of the work tree of the git repository which has the
# directory, found by its .git (a directory, or a file in a worktree).
sub git_top {
    my $dir = shift;
    state %top;
    $top{$dir} //= do {
	my $d = $dir;
	$d = dirname($d) until -e "$d/.git" or $d eq '/' or $d eq '.';
	-e "$d/.git" ? $d : '';
    };
    $top{$dir} || undef;
}

# The URLs of the remotes of a repository, from git itself (no shell).
sub remote_urls {
    my $top = shift;
    state %urls;
    $urls{$top} //= do {
	my @u;
	if (open my $fh, '-|', 'git', '-C', $top, 'config', '--get-regexp', '^remote\..*\.url$') {
	    @u = map { /^\S+\s+(\S+)/ ? $1 : () } <$fh>;
	    close $fh;
	}
	\@u;
    };
    @{$urls{$top}};
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Greple::md::Image - find the files of the images of a Markdown text

=head1 SYNOPSIS

    use App::Greple::md::Image qw(local_path);

    my $file = local_path('images/a.png', $dir) or return;

=head1 DESCRIPTION

This module finds the image files for the C<image_types> option of
L<App::Greple::md>, which shows them with L<Text::ANSI::Image>.

=over 4

=item B<local_path>(I<URL>, I<DIR>)

Returns the local file of an image, or C<undef>.  A path is taken
relative to I<DIR>, the directory of the Markdown file.  A GitHub URL,
C<https://raw.githubusercontent.com/OWNER/REPO/BRANCH/PATH> or
C<https://github.com/OWNER/REPO/blob/BRANCH/PATH>, is taken as the
file I<PATH> in the git work tree of I<DIR>, if one of its remotes is
C<github.com/OWNER/REPO>.  Nothing is fetched from the network.

=back

=head1 SEE ALSO

L<App::Greple::md>, L<Text::ANSI::Image>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2026 Kazumasa Utashiro.

This software is released under the MIT License.
L<https://opensource.org/licenses/MIT>

=cut
