package Apache::AuthzNIS;

use strict;
# use Apache::Constants ':common';
use Net::NIS;

$Apache::AuthzNIS::VERSION = '0.11';

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
                Apache::Const->import(-compile => 'HTTP_UNAUTHORIZED','OK', 'HTTP_INTERNAL_SERVER_ERROR');
        } else {
                require Apache::Constants;
                Apache::Constants->import('HTTP_UNAUTHORIZED','OK', 'HTTP_INTERNAL_SERVER_ERROR');
        }
}
##################### end modperl code ######################

sub handler {
    my $r = shift;
    my $requires = $r->requires;
    return (MP2 ? Apache::OK : Apache::Constants::OK) unless $requires;

    my $name = MP2 ? $r->user : $r->connection->user;

    for my $req (@$requires) {
        my($require, @list) = split /\s+/, $req->{requirement};

	#ok if user is one of these users
	if ($require eq "user") {
	    return (MP2 ? Apache::OK : Apache::Constants::OK) if grep $name eq $_, @list;
	}
	#ok if user is simply authenticated
	elsif ($require eq "valid-user") {
	    return MP2 ? Apache::OK : Apache::Constants::OK;
	}
	elsif ($require eq "group") {
	    my $domain = Net::NIS::yp_get_default_domain();
	    unless($domain) {
		$r->note_basic_auth_failure;
		MP2 ? $r->log_error("Apache::AuthenNIS - cannot obtain NIS domain", $r->uri) : $r->log_reason("Apache::AuthenNIS - cannot obtain NIS domain", $r->uri);
		return MP2 ? Apache::HTTP_INTERNAL_SERVER_ERROR : Apache::Constants::HTTP_INTERNAL_SERVER_ERROR;
	    }
	    foreach my $thisgroup (@list) {
		my ($status, $entry) = Net::NIS::yp_match($domain, "group.byname", $thisgroup);
		if($status) {
		    my $error_msg = Net::NIS::yperr_string($status);
		    $r->note_basic_auth_failure;
		    MP2 ? $r->log_error("Apache::AuthzNIS - group: $thisgroup: yp_match status $status, $error_msg", $r->uri) : $r->log_reason("Apache::AuthzNIS - group: $thisgroup: yp_match status $status, $error_msg", $r->uri);
			return MP2 ? Apache::HTTP_INTERNAL_SERVER_ERROR : Apache::Constants::HTTP_INTERNAL_SERVER_ERROR;
		}
		my @names = split /\,/, $entry;
		$names[0] =~ s/^.*:.*:.*://;
		foreach my $oneuser (@names) {
		    if ($oneuser eq $name) {
			    return MP2 ? Apache::OK : Apache::Constants::OK;
		    }
		}
	    }
	}
    }
    
    $r->note_basic_auth_failure;
    MP2 ? $r->log_error("Apache::AuthzNIS - user $name: not authorized", $r->uri) : $r->log_reason("Apache::AuthzNIS - user $name: not authorized", $r->uri);
    return MP2 ? Apache::HTTP_UNAUTHORIZED : Apache::Constants::HTTP_UNAUTHORIZED;
}

1;

__END__

=head1 NAME

Apache::AuthzNIS - mod_perl NIS Group Authorization module

=head1 SYNOPSIS

    <Directory /foo/bar>
    # This is the standard authentication stuff
    AuthName "Foo Bar Authentication"
    AuthType Basic

    # The following is actually only needed when you will authenticate
    # via NIS passwd as well as authorize via NIS group.
    # Apache::AuthenNIS is a separate module.
    PerlAuthenHandler Apache::AuthenNIS

    # Standard require stuff, NIS users or groups, and
    # "valid-user" all work OK
    require user username1 username2 ...
    require group groupname1 groupname2 ...
    require valid-user

    PerlAuthzHandler Apache::AuthzNIS

    </Directory>

    These directives can also be used in the <Location> directive or in
    an .htaccess file.

= head1 DESCRIPTION

This perl module is designed to work with mod_perl, the Net::NIS module by
Rik Haris (B<rik.harris@fulcrum.com.au>), and the Apache::AuthenNIS module
by Demetrios E. Paneras (B<dep@media.mit.edu>).  It is a direct adaptation
(i.e. I modified the code) of Michael Parker's (B<parker@austx.tandem.com>)
Apache::AuthenSmb module (which also included an authorization routine).

The module calls B<Net::NIS::yp_match> using each of the B<require group>
elements as keys to the the B<group.byname> map, until a match with the
(already authenticated) B<user> is found.

For completeness, the module also handles B<require user> and B<require
valid-user> directives.

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

=head1 AUTHOR

Demetrios E. Paneras <dep@media.mit.edu>
Ported by Shannon Eric Peevey <speeves@unt.edu>

=head1 COPYRIGHT

Copyright (c) 1998 Demetrios E. Paneras, MIT Media Laboratory.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
