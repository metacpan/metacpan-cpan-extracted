# $Id$
package Apache::PHLogin;
use strict;
use Apache();
use Apache::Constants qw(OK SERVER_ERROR AUTH_REQUIRED);
use Net::PH;
use vars qw($VERSION);

$VERSION = '0.5';
my(%Config) = (
    'PHLogin_host' => '',
    'PHLogin_port' => '105',
    'PHLogin_timeout' => '5',
);
my $prefix = "Apache::PHLogin";

sub handler {
    my($r) = @_;
    my($key,$val);
    my $attr = { };
    while(($key,$val) = each %Config) {
        $val = $r->dir_config($key) || $val;
        $key =~ s/^PHLogin_//;
        $attr->{$key} = $val;
    }
    
    return check($r, $attr);
}
 
sub check {
    my($r, $attr) = @_;
    my($res, $sent_pwd);
 
    ($res, $sent_pwd) = $r->get_basic_auth_pw;
    return $res if $res; #decline if not Basic

    my $user = $r->connection->user;

    unless ( $attr->{host} ) {
        $r->log_reason("$prefix is missing the CCSO host", $r->uri);
        return SERVER_ERROR;
    }

    my $ph = Net::PH->new($attr->{host},
			Port=>$attr->{port},
			Timeout=>$attr->{timeout});
    unless( $ph ) {
        $r->log_reason("PH failed to connect to CCSO host: " . $attr->{host} . $attr->{port} . $attr->{timeout}, $r->uri);
        return SERVER_ERROR;
    }
        
    my $ph_login = $ph->login($user, $sent_pwd);
    unless( $ph_login ) {
        $r->log_reason("user $user: " . $ph->message, $r->uri);
        $r->note_basic_auth_failure;
        return AUTH_REQUIRED;
    }

    $ph->quit;
    return OK;
}
1;
 
__END__

=head1 NAME

Apache::PHLogin - authenticates via a PH database

=head1 SYNOPSIS

 #in .htaccess
 AuthName MyPHLoginAuth
 AuthType Basic
 PerlAuthenHandler Apache::PHLogin::handler
 
 PerlSetVar PHLogin_host ph.psu.edu
 PerlSetVar PHLogin_port 105
 PerlSetVar PHLogin_timeout 5

 Options Indexes FollowSymLinks ExecCGI
  
 require valid-user

=head1 DESCRIPTION

The PH(CCSO) Nameserver is a database commonly used as an online phonebook
server for organizations. See http://people.qualcomm.com/ppomes/ph.html for
details. This module uses the Net::PH module by Graham Barr
E<lt>gbarr@pobox.comE<gt> and Alex Hristov E<lt>hristov@slb.comE<gt>.

=head1 SEE ALSO

mod_perl(1), Apache::AuthenCache(3), Net::PH(3)

=head1 AUTHOR

John Groenveld E<lt>groenveld@acm.orgE<gt>

=head1 COPYRIGHT

This package is Copyright (C) 1998 by John Groenveld. It may be
copied, used and redistributed under the same terms as perl itself.

=cut
