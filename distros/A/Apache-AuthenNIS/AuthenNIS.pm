package Apache::AuthenNIS;

use strict;
# use Apache::Constants ':common';
use Net::NIS;

$Apache::AuthenNIS::VERSION = '0.13';

############################################
# here is where we start the new code....
############################################
use mod_perl ;

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
                Apache::Const->import(-compile => 'HTTP_UNAUTHORIZED','OK', 'HTTP_INTERNAL_SERVER_ERROR', 'DECLINED');
        } else {
                require Apache::Constants;
                Apache::Constants->import('HTTP_UNAUTHORIZED','OK', 'HTTP_INTERNAL_SERVER_ERROR', 'DECLINED');
        }
}
##################### end modperl code ######################

sub handler {
    my $r = shift;
    my($res, $sent_pwd) = $r->get_basic_auth_pw;
    return $res if $res; #decline if not Basic

    my $name = MP2 ? $r->user : $r->connection->user;

    my $allowaltauth = $r->dir_config('AllowAlternateAuth') || "no";

    my $domain = Net::NIS::yp_get_default_domain();
    unless($domain) {
	$r->note_basic_auth_failure;
        MP2 ?  $r->log_error("Apache::AuthenNIS - cannot obtain NIS domain", $r->uri) : $r->log_reason("Apache::AuthenNIS - cannot obtain NIS domain", $r->uri);
	return MP2 ? Apache::HTTP_INTERNAL_SERVER_ERROR : Apache::Constants::HTTP_INTERNAL_SERVER_ERROR;
    }

    if ($name eq "") {
	$r->note_basic_auth_failure;
        MP2 ? $r->log_error("Apache::AuthenNIS - no username given", $r->uri) : $r->log_reason("Apache::AuthenNIS - no username given", $r->uri);
       return MP2 ? Apache::HTTP_UNAUTHORIZED : Apache::Constants::HTTP_UNAUTHORIZED;
    }

    my ($status, $entry) = Net::NIS::yp_match($domain, "passwd.byname", $name);

    if($status) {
        if (lc($allowaltauth) eq "yes" && $status == 5)
        {
            return MP2 ? Apache::DECLINED : Apache::Constants::DECLINED;
        }
        else
        {
            my $error_msg = Net::NIS::yperr_string($status);
            $r->note_basic_auth_failure;
            MP2 ? $r->log_error("Apache::AuthenNIS - user $name: yp_match: status $status, $error_msg", $r->uri) : $r->log_reason("Apache::AuthenNIS - user $name: yp_match: status $status, $error_msg", $r->uri);
            return MP2 ? Apache::HTTP_UNAUTHORIZED : Apache::Constants::HTTP_UNAUTHORIZED;
        }
    }

    my ($user, $hash, $uid, $gid, $gecos, $dir, $shell) = split(/:/, $entry);

    if(crypt($sent_pwd, $hash) eq $hash) {
        return MP2 ? Apache::OK : Apache::Constants::OK;
    } else {
        if (lc($allowaltauth) eq "yes")
        {
           return MP2 ? Apache::DECLINED : Apache::Constants::DECLINED;
        }
        else
        {
	         $r->note_basic_auth_failure;
	         MP2 ? $r->log_error("Apache::AuthenNIS - user $name: bad password", $r->uri) : $r->log_reason("Apache::AuthenNIS - user $name: bad password", $r->uri);
	         return MP2 ? Apache::HTTP_UNAUTHORIZED : Apache::Constants::HTTP_UNAUTHORIZED;
	      }
    }

    return MP2 ? Apache::OK : Apache::Constants::OK;
}

1;

__END__

=head1 NAME

Apache::AuthenNIS - mod_perl NIS Authentication module

=head1 SYNOPSIS

    <Directory /foo/bar>
    # This is the standard authentication stuff
    AuthName "Foo Bar Authentication"
    AuthType Basic

    PerlAuthenHandler Apache::AuthenNIS

    # Set if you want to allow an alternate method of authentication
    PerlSetVar AllowAlternateAuth yes | no

    # Standard require stuff, NIS users or groups, and
    # "valid-user" all work OK
    require user username1 username2 ...
    require group groupname1 groupname2 ... # [Need Apache::AuthzNIS]
    require valid-user

    # The following is actually only needed when authorizing
    # against NIS groups. This is a separate module.
    PerlAuthzHandler Apache::AuthzNIS

    </Directory>

    These directives can also be used in the <Location> directive or in
    an .htaccess file.

= head1 DESCRIPTION

This perl module is designed to work with mod_perl and the Net::NIS
module by Rik Haris (B<rik.harris@fulcrum.com.au>).  It is a direct
adaptation (i.e. I modified the code) of Michael Parker's
(B<parker@austx.tandem.com>) Apache::AuthenSmb module.

The module uses Net::NIS::yp_match to retrieve the "passwd" entry from the
passwd.byname map, using the supplied username as the search key.  It then
uses crypt() to verify that the supplied password matches the retrieved
hashed password.

= head2 Apache::AuthenNIS vs. Apache::AuthzNIS

I've taken "authentication" to be meaningful only in terms of a user and
password combination, not group membership.  This means that you can use
Apache::AuthenNIS with the B<require user> and B<require valid-user>
directives.  In the NIS context I consider B<require group> to be an
"authorization" concern.  I.e., Group authorization consists of
establishing whether the already authenticated user is a member of one of
the indicated groups in the B<require group> directive.  This process may
be handled by B<Apache::AuthzNIS>.

I welcome any feedback on this module, esp. code improvements, given
that it was written hastily, to say the least.

= head3 Parameters

=over 4

=item PerlSetVar AllowAlternateAuth

This attribute allows you to set an alternative method of authentication
(Basically, this allows you to mix authentication methods, if you don't have
 all users in the NIS database). It does this by returning a DECLINE and checking
 for the next handler, which could be another authentication, such as
Apache-AuthenNTLM or basic authentication.

=head1 AUTHOR

Demetrios E. Paneras <dep@media.mit.edu>
Ported by Shannon Eric Peevey <speeves@unt.edu>

=head1 COPYRIGHT

Copyright (c) 1998 Demetrios E. Paneras, MIT Media Laboratory.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
