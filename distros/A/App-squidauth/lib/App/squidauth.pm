## no critic: InputOutput::RequireBriefOpen

package App::squidauth;

our $DATE = '2021-02-19'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{squidauth} = {
    v => 1.1,
    summary => 'A simple authenticator program for Squid',
    description => <<'_',

This utility can be used as an authenticator program for Squid. It reads users &
passwords from a simple, htpasswd-format text file (by default at
`/etc/proxypasswd`) with the format like:

    user1:$apr1$YFFyJK3J$PfuotoLCk7XQqQiH6I3Cb/
    user2:$apr1$NOvdp7LN$YnH5zmfCn0IhNt/fKZdL2.
    ...

To add entries to this file, you can use <prog:htpasswd> (usually comes with
Apache httpd in an OS package like `httpd-tools`) to add users to this file,
e.g.:

    % htpasswd -c /etc/proxypasswd user1
    % htpasswd    /etc/proxypasswd user2
    ...

_
    args => {
        passwd_file => {
            summary => 'Location of password file',
            schema => 'pathname*',
            default => '/etc/proxypasswd',
        },
    },
};
sub squidauth {
    require Crypt::PasswdMD5;

    my %args = @_;

    my $passwd_file = $args{passwd_file} // "/etc/proxypasswd";
    my $passwd_file_mtime = 0;

    my %passwords; # key=username, val=[salt, pass]

    my $code_read_passwd_file = sub {
        log_debug "Rereading password file '$passwd_file' ...";
        open my $fh, "<", $passwd_file
            or die "Can't open password file '$passwd_file': $!\n";
        $passwd_file_mtime = (-M $passwd_file);
        %passwords = ();
        while (<$fh>) {
            chomp;
            my ($user, $pass) = split /\:/, $_, 2;
            $passwords{$user} = $pass;
        }
    };

    # returns 1 if password is correct
    my $code_cmp_pass = sub {
        my ($pass, $enc) = @_;
        my $salt;

        #DEBUG "Comparing enc($pass, $salt) with $enc...";
        if ($enc =~ /^\$apr1\$(.*?)\$/) {
            # apache MD5
            $salt = $1;
            return Crypt::PasswdMD5::apache_md5_crypt($pass, $salt) eq $enc;
        } else {
            # assume it's crypt()
            $salt = $enc;
            return crypt($pass, $salt) eq $enc;
        }
    };

    $code_read_passwd_file->();

    $|++;
    while (<STDIN>) {
        $code_read_passwd_file->() if $passwd_file_mtime > (-M $passwd_file);
        chomp;
        my ($user, $pass) = split / /, $_, 2; $user ||= "";
        if ($passwords{$user} && $code_cmp_pass->($pass, $passwords{$user})) {
            print "OK\n";
        } else {
            print "ERR\n";
        }
    }

    [200]; # won't be reached
}

1;
# ABSTRACT: A simple authenticator program for Squid

__END__

=pod

=encoding UTF-8

=head1 NAME

App::squidauth - A simple authenticator program for Squid

=head1 VERSION

This document describes version 0.002 of App::squidauth (from Perl distribution App-squidauth), released on 2021-02-19.

=head1 SYNOPSIS

See included script L<squidauth>.

=head1 FUNCTIONS


=head2 squidauth

Usage:

 squidauth(%args) -> [status, msg, payload, meta]

A simple authenticator program for Squid.

This utility can be used as an authenticator program for Squid. It reads users &
passwords from a simple, htpasswd-format text file (by default at
C</etc/proxypasswd>) with the format like:

 user1:$apr1$YFFyJK3J$PfuotoLCk7XQqQiH6I3Cb/
 user2:$apr1$NOvdp7LN$YnH5zmfCn0IhNt/fKZdL2.
 ...

To add entries to this file, you can use L<htpasswd> (usually comes with
Apache httpd in an OS package like C<httpd-tools>) to add users to this file,
e.g.:

 % htpasswd -c /etc/proxypasswd user1
 % htpasswd    /etc/proxypasswd user2
 ...

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<passwd_file> => I<pathname> (default: "/etc/proxypasswd")

Location of password file.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HISTORY

The C<squidauth> script was created back in early 2000's or even late 1990's.

Converted to use L<Perinci::CmdLine> and packaged as a CPAN distribution in Jan
2018.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-squidauth>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-squidauth>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-squidauth/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
