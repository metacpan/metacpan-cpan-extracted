package Apache::DBILogin;

use strict;

use vars qw($VERSION);
$VERSION = '2.06';

# setting the constants to help identify which version of mod_perl
# is installed
use constant MP2 => eval { require mod_perl2; 1 } || 0;

# test for the version of mod_perl, and use the appropriate libraries
BEGIN {
    if (MP2) {
        require Apache2::Access;
        require Apache2::Connection;
        require Apache2::Const;
        require Apache2::Log;
        require Apache2::RequestRec;
        require Apache2::RequestUtil;
        require APR::Table;
        Apache2::Const->import(-compile => 'HTTP_FORBIDDEN', 'HTTP_UNAUTHORIZED',
                                          'HTTP_INTERNAL_SERVER_ERROR', 'OK');
    } else {
        require mod_perl;
        require Apache::Constants;
        Apache::Constants->import('HTTP_FORBIDDEN', 'HTTP_UNAUTHORIZED',
                                  'HTTP_INTERNAL_SERVER_ERROR', 'OK');
    }
}

use DBI;

my(%Config) = (
    'Auth_DBI_data_source' => '',
    'Auth_DBI_authz_command' => '',
    'DBILogin_Oracle_authz_command' => '',
);
my $prefix = "Apache::DBILogin";

sub authen {
    my $r = shift @_;
 
    my ($res, $sent_pwd) = $r->get_basic_auth_pw;
    return $res if ( $res ); #decline if not Basic

    return (MP2 ? Apache2::Const::OK : Apache::Constants::OK)
        unless $r->is_initial_req;

    my($key,$val);
    my $attr = {};
    while(($key,$val) = each %Config) {
        $val = $r->dir_config($key) || $val;
        $key =~ s/^Auth_DBI_//;
        $attr->{$key} = $val;
    }
    
    return test_authen($r, $attr, $sent_pwd);
}
 
sub test_authen {
    my($r, $attr, $sent_pwd) = @_;

    my $user = MP2 ? $r->user : $r->connection->user;

    unless ( $attr->{data_source} ) {
        $r->log_reason("$prefix is missing the source parameter for database connect", $r->uri);
        return MP2 ? Apache2::Const::HTTP_INTERNAL_SERVER_ERROR : Apache::Constants::HTTP_INTERNAL_SERVER_ERROR;
    }

    my $dbh = DBI->connect($attr->{data_source}, $user, $sent_pwd, { AutoCommit=>0, RaiseError=>0 });
    unless( defined $dbh ) {
        $r->log_reason("user $user: $DBI::errstr", $r->uri);
        $r->note_basic_auth_failure;
        return MP2 ? Apache2::Const::HTTP_UNAUTHORIZED : Apache::Constants::HTTP_UNAUTHORIZED;
    }

    # to be removed in next version
    if ( $attr->{authz_command} ) {
        unless( defined ($dbh->do($attr->{authz_command})) ) {
            $r->log_reason("user $user: $DBI::errstr", $r->uri);
            $r->note_basic_auth_failure;
            return MP2 ? Apache2::Const::HTTP_UNAUTHORIZED : Apache::Constants::HTTP_UNAUTHORIZED;
        }
    }
           
    $dbh->disconnect;
    $r->headers_in->{'Modperl_DBILogin_Password'} = $sent_pwd;
    $r->headers_in->{'Modperl_Password'} = $sent_pwd;
    $r->headers_in->{'Modperl_DBILogin_data_source'} = $attr->{data_source};
    return MP2 ? Apache2::Const::OK : Apache::Constants::OK;
}

sub authz {
    my $r = shift @_;

    my ($res, $sent_pwd) = $r->get_basic_auth_pw;
    return $res if ( $res ); #decline if not Basic

    return (MP2 ? Apache2::Const::OK : Apache::Constants::OK)
        unless $r->is_initial_req;

    my $user = MP2 ? $r->user : $r->connection->user;

    my($key,$val);
    my $attr = {};
    while(($key,$val) = each %Config) {
        $val = $r->dir_config($key) || $val;
        $key =~ s/^Auth_DBI_//;
        $attr->{$key} = $val;
    }
    
    return test_authz($r, $attr, $sent_pwd);
}

sub test_authz {
    my($r, $attr, $sent_pwd) = @_;

    my $user = MP2 ? $r->user : $r->connection->user;

    unless ( $attr->{data_source} ) {
        $r->log_reason("$prefix is missing the source parameter for database connect", $r->uri);
        return MP2 ? Apache2::Const::HTTP_INTERNAL_SERVER_ERROR : Apache::Constants::HTTP_INTERNAL_SERVER_ERROR;
    }

    my $dbh = DBI->connect($attr->{data_source}, $user, $sent_pwd, {AutoCommit=>0, RaiseError=>0});
    unless( defined $dbh ) {
        $r->log_reason("user $user: $DBI::errstr", $r->uri);
        return MP2 ? Apache2::Const::HTTP_INTERNAL_SERVER_ERROR : Apache::Constants::HTTP_INTERNAL_SERVER_ERROR;
    }

    my $authz_result = MP2 ? Apache2::Const::HTTP_FORBIDDEN : Apache::Constants::HTTP_FORBIDDEN;
    my $sth;
    foreach my $requirement ( @{$r->requires} ) {
        my $require = $requirement->{requirement};
        if ( $require eq "valid-user" ) {
            $authz_result = MP2 ? Apache2::Const::OK : Apache::Constants::OK;
        } elsif ( $require =~ s/^user\s+// ) { 
                foreach my $valid_user (split /\s+/, $require) {
                    if ( $user eq $valid_user ) {
                        $authz_result = MP2 ? Apache2::Const::OK : Apache::Constants::OK;
                        last;
                    }
                }
                if ( $authz_result != (MP2 ? Apache2::Const::OK : Apache::Constants::OK) ) {
                    my $explaination = <<END;
<HTML>
<HEAD><TITLE>Unauthorized</TITLE></HEAD>
<BODY>
<H1>Unauthorized</H1>
User must be one of these required users: $require
</BODY>
</HTML>
END
                    $r->custom_response(MP2 ? Apache2::Const::HTTP_FORBIDDEN : Apache::Constants::HTTP_FORBIDDEN, $explaination);
                    $r->log_reason("user $user: not authorized", $r->uri);
                }
            } elsif ( $require =~ s/^group\s+// ) {
                    foreach my $group (split /\s+/, $require) {
                        $authz_result = is_member($r, $dbh, $group);
                        last if ( $authz_result == (MP2 ? Apache2::Const::OK : Apache::Constants::OK) );
                        if ( $authz_result == (MP2 ? Apache2::Const::HTTP_INTERNAL_SERVER_ERROR : Apache::Constants::HTTP_INTERNAL_SERVER_ERROR) ) {
                            $r->log_reason("user $user: $@", $r->uri);
                            return MP2 ? Apache2::Const::HTTP_INTERNAL_SERVER_ERROR : Apache::Constants::HTTP_INTERNAL_SERVER_ERROR;
                        }
                    }
                    if ( $authz_result == (MP2 ? Apache2::Const::HTTP_FORBIDDEN : Apache::Constants::HTTP_FORBIDDEN) ) {
                        my $explaination = <<END;
<HTML>
<HEAD><TITLE>Unauthorized</TITLE></HEAD>
<BODY>
<H1>Unauthorized</H1>
User must be member of one of these required groups: $require
</BODY>
</HTML>
END
                        $r->custom_response(MP2 ? Apache2::Const::HTTP_FORBIDDEN : Apache::Constants::HTTP_FORBIDDEN, $explaination);
                        $r->log_reason("user $user: not authorized", $r->uri);
                    }
                }
    }

    $dbh->disconnect;
    return $authz_result;
}

1;
 
__END__

=head1 NAME

Apache::DBILogin - authenticates and authorizes via a DBI connection

=head1 SYNOPSIS

 #in .htaccess
 AuthName MyAuth
 AuthType Basic
 PerlAuthenHandler Apache::DBILogin::authen
 PerlSetVar Auth_DBI_data_source dbi:Oracle:SQLNetAlias
 PerlAuthzHandler Apache::DBILogin::authz
 
 allow from all
 require group connect resource dba
 satisfy all

 #in startup.pl
 package Apache::DBILogin;
 
 # is_member function for authz handler
 #  expects request object, database handle, and group for which to test
 #  returns valid response code
 sub is_member {
     my ($r, $dbh, $group) = @_;
 
     my $sth;
     eval {
         # no, Oracle doesn't support binding in SET ROLE statement
         $sth = $dbh->prepare("SET ROLE $group") or die $DBI::errstr;
     };
     return ( MP2 ? Apache2::Const::HTTP_INTERNAL_SERVER_ERROR
                  : Apache::Constants::HTTP_INTERNAL_SERVER_ERROR ) if ( $@ );
        
     return ( defined $sth->execute() ) ? (MP2 ? Apache2::Const::OK
                                               : Apache::Constants::OK)
                                        : (MP2 ? Apache2::Const::HTTP_FORBIDDEN
                                               : Apache::Constants::HTTP_FORBIDDEN);
 }

=head1 DESCRIPTION

Apache::DBILogin allows authentication and authorization against a
multi-user database.

It is intended to facilitate web-based transactions against a database server
as a particular database user. If you wish authenticate against a passwd
table instead, please see Edmund Mergl's Apache::AuthDBI module.

Group authorization is handled by your Apache::DBILogin::is_member()
function which you must define if you enable the authz handler.

The above example uses Oracle roles to assign group membership. A role is a
set of database privileges which can be assigned to users. Unfortunately,
roles are vendor specific. Under Oracle you can test membership with
"SET ROLE role_name" statement. You could also query the data dictionary,
DBA_ROLE_PRIVS, but under Oracle that requires explicit privilege.
Documentation patches for other databases are welcome.

=head1 ENVIRONMENT

Applications may access the clear text password as well as the data_source
via the environment variables B<HTTP_MODPERL_DBILOGIN_PASSWORD> and
B<HTTP_MODPERL_DBILOGIN_DATA_SOURCE>.

 #!/usr/bin/perl -wT
 
 use strict;
 use CGI;
 use DBI;
 my $name = $ENV{REMOTE_USER};
 my $password = $ENV{HTTP_MODPERL_DBILOGIN_PASSWORD};
 my $data_source = $ENV{HTTP_MODPERL_DBILOGIN_DATA_SOURCE};
 my $dbh = DBI->connect($data_source, $name, $password)
 	or die "$DBI::err: $DBI::errstr\n";
 ...

=head1 SECURITY

The database user's clear text passwd is made available in the
server's environment. Do you trust your developers?

=head1 BUGS

Probably lots, I'm not the best programmer in the world.

=head1 NOTES

Feel free to email me with comments, suggestions, flames. Its the
only way I'll become a better programmer.

=head1 SEE ALSO

mod_perl(1), Apache::DBI(3), and Apache::AuthDBI(3)

=head1 AUTHOR

John Groenveld E<lt>groenveld@acm.orgE<gt>

=cut
