package Net::FTPServer::RO_FTPThis::Server;

our $DATE = '2017-11-10'; # DATE
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

use parent qw(Net::FTPServer::RO::Server);

sub user_login_hook {
    my $self = shift;
    my $user = shift;
    my $user_is_anon = shift;

    # reject non-anonymous login
    die "only anonymous ftp mode supported" unless $user_is_anon;

    my $dir = $self->config("root directory");
    my @st = stat($dir) or die "Can't stat '$dir': $!";
    my @pw;
    if ($st[4] == 0) {
        @pw = getpwnam("nobody") or die "Can't get user nobody";
    } else {
        @pw = getpwuid($st[4]) or die "Can't get user with UID $st[4]";
    }

    if ($> == 0) {
        # chroot to directory and change to directory's owner

        chroot $dir or die "cannot chroot to '$dir': $!";

        # We don't allow users to relogin, so completely change to the user
        # specified.
        warn "D: Dropping to user $pw[0]\n" if $ENV{DEBUG};
        $self->_drop_privs ($pw[2], $pw[3], $pw[0]);
    } else {
        die "non-root mode unsupported yet";
    }
}

1;
# ABSTRACT: Subclass of Net::FTPServer::RO::Server for ftp_this

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FTPServer::RO_FTPThis::Server - Subclass of Net::FTPServer::RO::Server for ftp_this

=head1 VERSION

This document describes version 0.003 of Net::FTPServer::RO_FTPThis::Server (from Perl distribution App-FTPThis), released on 2017-11-10.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-FTPThis>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ftpthis>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FTPThis>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
