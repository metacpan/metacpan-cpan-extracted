package Apache::AuthzUserDir;

use strict;
use Apache::Constants ':common';

$Apache::AuthzUserDir::VERSION = '0.92';

sub handler {
    my $r = shift;
    my $requires = $r->requires;
    return OK unless $requires;

    # get user's authentication credentials
    my ($res, $sent_pw) = $r->get_basic_auth_pw;
    return $res if $res != OK;

    my $user = $r->connection->user;

    unless($user and $sent_pw) {
        $r->note_basic_auth_failure;
        $r->log_reason("Both a username and password must be provided", $r->filename);
        return AUTH_REQUIRED;
    }

    my($file,$userdir_user);
    $file = $r->uri;

    # validity checking - require something after /~ or DECLINE
    unless ($file =~ (/\/\~.+/)) {
        return DECLINED;
    }
   
    # user is everything after /~ until another slash is seen (or until the end
    # of the string to accomodate sloppy http://foo.com/~user requests w/o 
    # trailing slash)

    ($userdir_user) = $file =~ /~([^\/]+)/;

    for my $entry (@$requires) {
        my($requirement, @rest) = split(/\s+/, $entry->{requirement});

        if (lc $requirement eq 'valid-user') {
            if ($userdir_user eq $user) {
                return OK;
            } else {
                # Forbid a different user is trying to get in.
                $r->log_reason("Apache::AuthzUserDir - declined $user access to $file");
                return FORBIDDEN;
            }
        } else {
            $r->log_reason("Apache::AuthzUserDir - unknown require $requirement");
        }
    }
    $r->note_basic_auth_failure;
    $r->log_reason("Apache::AuthzUserDir - user $user: not authorized", $r->uri);
    return AUTH_REQUIRED;
}

1;
__END__

=head1 NAME

Apache::AuthzUserDir - mod_perl UserDir authorization module

=head1 SYNOPSIS

 <Directory /home/*/public_html>
 PerlAuthzHandler Apache::AuthzUserDir

 # This is the standard authentication stuff.
 # Any can be used, but basic .htpasswd authentication
 # is shown for simplicity.
 AuthName "Foo Bar Authentication"
 AuthType Basic
 AuthUserFile /usr/local/apache/.htpasswd-userdirs
 # This tells apache to only let in users whose
 # http login name matches the * in /home/*/public_html
 require valid-user

 </Directory>

=head1 DESCRIPTION

Apache::AuthzUserDir is designed to work with mod_perl
and Apache's mod_userdir such that a single systemwide 
<Directory> block and .htpasswd file can be used to
allow authenticated users only into their own UserDir 
(typically, public_html) directories.

This is especially useful with mod_dav and mod_ssl running on an 
alternate port for users to upload to their public webspace.

=head1 COPYRIGHT
Copyright (C) 2002, Peter Clark
All Rights Reserved

This module is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
