#line 1
package Module::Install::Repository;

use strict;
use 5.008_001;
our $VERSION = '0.03';

use base qw(Module::Install::Base);

sub auto_set_repository {
    my $self = shift;

    return unless $Module::Install::AUTHOR;

    my $repo = _find_repo();
    if ($repo) {
        $self->repository($repo);
    } else {
        warn "Cannot determine repository URL\n";
    }
}

sub _find_repo {
    if (-e ".git") {
        # TODO support remote besides 'origin'?
        if (`git remote show origin` =~ /URL: (.*)$/m) {
            # XXX Make it public clone URL, but this only works with github
            my $git_url = $1;
            $git_url =~ s![\w\-]+\@([^:]+):!git://$1/!;
            return $git_url;
        } elsif (`git svn info` =~ /URL: (.*)$/m) {
            return $1;
        }
    } elsif (-e ".svn") {
        if (`svn info` =~ /URL: (.*)$/m) {
            return $1;
        }
    } elsif (-e "_darcs") {
        # defaultrepo is better, but that is more likely to be ssh, not http
        if (my $query_repo = `darcs query repo`) {
            if ($query_repo =~ m!Default Remote: (http://.+)!) {
                return $1;
            }
        }

        open my $handle, '<', '_darcs/prefs/repos' or return;
        while (<$handle>) {
            chomp;
            return $_ if m!^http://!;
        }
    } elsif (-e "$ENV{HOME}/.svk") {
        # Is there an explicit way to check if it's an svk checkout?
        my $svk_info = `svk info` or return;
        SVK_INFO: {
            if ($svk_info =~ /Mirrored From: (.*), Rev\./) {
                return $1;
            }

            if ($svk_info =~ m!Merged From: (/mirror/.*), Rev\.!) {
                $svk_info = `svk info /$1` or return;
                redo SVK_INFO;
            }
        }

        return;
    }
}

1;
__END__

=encoding utf-8

#line 114
