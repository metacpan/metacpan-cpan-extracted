package App::Milter::Limit::Util;
$App::Milter::Limit::Util::VERSION = '0.52';
# ABSTRACT: utility functions for App::Milter::Limit


use strict;
use POSIX qw(setsid);
use File::Path 2.0 ();
use App::Milter::Limit::Config;


sub daemonize {
    my $pid = fork and exit 0;

    my $sid = setsid();

    # detach from controlling TTY
    $SIG{HUP} = 'IGNORE';
    $pid = fork and exit 0;

    # reset umask
    umask 027;

    chdir '/' or die "can't chdir: $!";

    open STDIN,  '+>/dev/null';
    open STDOUT, '+>&STDIN';
    open STDERR, '+>&STDIN';

    return $sid;
}


sub get_uid {
    my $user = shift;

    unless ($user =~ /^\d+$/) {
        my $uid = getpwnam($user);
        unless (defined $uid) {
            die qq{no such user "$user"\n};
        }

        return $uid;
    }
    else {
        return $user;
    }
}


sub get_gid {
    my $group = shift;

    unless ($group =~ /^\d+$/) {
        my $gid = getgrnam($group);
        unless (defined $gid) {
            die qq{no such group "$group"\n};
        }

        return $gid;
    }
    else {
        return $group;
    }
}


sub make_path {
    my $path = shift;

    unless (-d $path) {
        File::Path::make_path($path, { mode => 0755 });
    }

    my $conf = App::Milter::Limit::Config->global;

    chown $$conf{user}, $$conf{group}, $path
        or die "chown($path): $!";
}

1;

__END__

=pod

=head1 NAME

App::Milter::Limit::Util - utility functions for App::Milter::Limit

=head1 VERSION

version 0.52

=head1 DESCRIPTION

This module provides utility functions for App::Milter::Limit.

=head1 FUNCTIONS

=head2 daemonize

This daemonizes the program.  When you call this, the program will fork(),
detach from the controlling TTY, close STDIN, STDOUT, and STDERR, and change to
the root directory.

=head2 get_uid ($username)

return the UID for the given C<$username>

=head2 get_gid ($groupname)

return the GID for the given C<$groupname>

=head2 make_path ($path)

create the given directory path if necessary, creating intermediate directories
as necessary.  The final directory will be C<chown()>'ed as the user/group from
the config file.

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/milter-limit>
and may be cloned from L<git://github.com/mschout/milter-limit.git>

=head1 BUGS

Please report any bugs or feature requests to bug-app-milter-limit@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=App-Milter-Limit

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
