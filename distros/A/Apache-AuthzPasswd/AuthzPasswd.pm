package Apache::AuthzPasswd;

use strict;
use mod_perl;

$Apache::AuthzPasswd::VERSION = '0.12';

# setting the constants to help identify which version of mod_perl
# is installed
use constant MP2 => ($mod_perl::VERSION >= 1.99);

# test for the version of mod_perl, and use the appropriate libraries
BEGIN {
        if (MP2) {
                require Apache::Const;
                require Apache::Access;
                require Apache::Connection;
                require Apache::Log;
                require Apache::RequestRec;
                require Apache::RequestUtil;
		require APR::Table;
                Apache::Const->import(-compile => 'HTTP_UNAUTHORIZED','HTTP_INTERNAL_SERVER_ERROR','OK');
        } else {
	       # require Apache::Log;
                require Apache::Constants;
                Apache::Constants->import('HTTP_UNAUTHORIZED','HTTP_INTERNAL_SERVER_ERROR','OK');
        }
}

sub handler {
    my $r = shift;
    my $requires = $r->requires;
    return MP2 ? Apache::OK : Apache::Constants::OK unless $requires;

    my $name = MP2 ? $r->user : $r->connection->user;

    my $setremotegroup = $r->dir_config('SetRemoteGroup') || "no";

    for my $req (@$requires) {
        my($require, @list) = split /\s+/, $req->{requirement};

	#ok if user is one of these users
	if ($require eq "user") {
	    return MP2 ? Apache::OK : Apache::Constants::OK if grep $name eq $_, @list;
	}
	#ok if user is simply authenticated
	elsif ($require eq "valid-user") {
	    return MP2 ? Apache::OK : Apache::Constants::OK;
	}
	elsif ($require eq "group") {
	    # Get users primary group's gid
	    my $ugid= [ getpwnam($name) ]->[3];
	    foreach my $thisgroup (@list) {
		# Then check if the user is member of the group
		my ($group, $passwd, $gid, $members) = getgrnam $thisgroup;
		unless($group) {
		    $r->note_basic_auth_failure;
		    MP2 ? $r->log_error("Apache::AuthzPasswd - group: $thisgroup unknown", $r->uri) : $r->log_reason("Apache::AuthzPasswd - group: $thisgroup unknown", $r->uri);
		    return MP2 ? Apache::HTTP_INTERNAL_SERVER_ERROR : Apache::Constants::HTTP_INTERNAL_SERVER_ERROR;
		}
		if($ugid == $gid || $members =~ /\b$name\b/) {
		    if($setremotegroup eq "yes") {
			$r->log->debug("Setting REMOTE_GROUP to $group");
			my $x = $r->subprocess_env(REMOTE_GROUP => $group);
		    }
		    return MP2 ? Apache::OK : Apache::Constants::OK;
		}
	    }
	}
    }
    
    $r->note_basic_auth_failure;
    MP2 ? $r->log_error("Apache::AuthzPasswd - user $name: not authorized", $r->uri) : $r->log_reason("Apache::AuthzPasswd - user $name: not authorized", $r->uri);
    return MP2 ? Apache::HTTP_UNAUTHORIZED : Apache::Constants::HTTP_UNAUTHORIZED;
}

1;

__END__

=head1 NAME

Apache::AuthzPasswd - mod_perl /etc/group Group Authorization module

=head1 SYNOPSIS

    <Directory /foo/bar>
    # This is the standard authentication stuff
    AuthName "Foo Bar Authentication"
    AuthType Basic

    # The following is needed when you will authenticate
    # via /etc/passwd as well as authorize via /etc/group.
    # Apache::AuthenPasswd is a separate module.
    PerlAuthenHandler Apache::AuthenPasswd

    # Set REMOTE_GROUP CGI env variable to authorized
    # group.  Defaults to no.
    PerlSetVar SetRemoteGroup  yes || no

    # Standard require stuff, users, groups and
    # "valid-user" all work OK
    require user username1 username2 ...
    require group groupname1 groupname2 ...
    require valid-user

    PerlAuthzHandler Apache::AuthzPasswd

    </Directory>

    These directives can also be used in the <Location> directive or in
    an .htaccess file.

= head1 DESCRIPTION

For starters, this module could just as well be named Apache::AuthzGroup,
since it has nothing to do with /etc/passwd, but rather works with
/etc/group.  However, I prefer this name in order to maintain the
association with Apache::AuthenPasswd, since chances are they will be used
together.

(SPEEVES NOTE:  This module does not seem to work without some sort of Authentication
module used in conjunction with it...  I haven't looked extensively, but my
testing always failed with a:

couldn't check user.  No user file?

error in the apache logs when I didn't have a module working at the authentication
level.)


This perl module is designed to work with mod_perl and the
Apache::AuthenPasswd module by Demetrios E. Paneras (B<dep@media.mit.edu>).
It is a direct adaptation (i.e. I modified the code) of Michael Parker's
(B<parker@austx.tandem.com>) Apache::AuthenSmb module (which also included
an authorization routine).

The module calls B<getgrnam> using each of the B<require group> elements as
keys, until a match with the (already authenticated) B<user> is found.

For completeness, the module also handles B<require user> and B<require
valid-user> directives.

= head2 PerlSetVar SetRemoteGroup

Set to "yes" to set the CGI env variable REMOTE_GROUP to the group of the
authorized user. Defaults to "no".

= head2 Apache::AuthenPasswd vs. Apache::AuthzPasswd

I've taken "authentication" to be meaningful only in terms of a user and
password combination, not group membership.  This means that you can use
Apache::AuthenPasswd with the B<require user> and B<require valid-user>
directives.  In the /etc/passwd and /etc/group context I consider B<require
group> to be an "authorization" concern.  I.e., group authorization
consists of establishing whether the already authenticated user is a member
of one of the indicated groups in the B<require group> directive.  This
process may be handled by B<Apache::AuthzPasswd>.  Admittedly, AuthzPasswd
is a misnomer, but I wanted to keep AuthenPasswd and AuthzPasswd related,
if only by name.

I welcome any feedback on this module, esp. code improvements, given
that it was written hastily, to say the least.

=head1 AUTHOR

Demetrios E. Paneras <dep@media.mit.edu> 
and Shannon Eric Peevey <speeves@unt.edu>

=head1 COPYRIGHT

Copyright (c) 1998,2003 Demetrios E. Paneras, MIT Media Laboratory.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
