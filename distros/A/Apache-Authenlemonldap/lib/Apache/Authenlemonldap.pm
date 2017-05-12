package Apache::Authenlemonldap;
use Apache::Constants qw(:common);
use Apache2::Log;
our $VERSION = '1.0.0';
sub handler {
    my $r = shift;
    return OK unless $r->is_initial_req;
    my ( $res, $role ) = $r->get_basic_auth_pw;
    return $res if $res;
    my $user = $r->connection->user;
    if ( !$user ) {
        $r->note_basic_auth_failure;
        $r->log_reason( "no uid found", $r->uri );
        return AUTH_REQUIRED;
    }
    my @directives = @{ $r->requires };
    $r->subprocess_env( ROLE => $role );
    $r->log->info("$user with role $role EXPECTED");
    for $req (@directives) {
        my ( $require, @rest ) = split /\s+/, $req->{requirement};
        if ( lc($directive) eq 'valid-user' ) {
            $r->log->info("$user with role $role GRANTED");
            return OK;
        }

        if ( lc($require) eq "user" ) {
            if ( grep { $_ eq $user } @rest ) {
                $r->log->info("$user with role $role GRANTED");
                return OK;

            }
        }
    }
        return AUTH_REQUIRED;

}
1;
__END__


=head1 NAME

Apache::Authenlemonldap - Perl extension for Apache with lemonldap websso

=head1 SYNOPSIS

In httpd.conf 
  
 <location /doc>
   Authname "lemonldap web SSO"
   Authtype Basic
 # require valid-user  or 
   require user egerman-cp
   PerlAuthenHandler Apache::Authenlemonldap
   Options Indexes FollowSymLinks MultiViews
 </location>

  

=head1 DESCRIPTION

 This module can decode lemonldap header .
 Installing on your apache web server it can deal with a lemonldap frontend
 It puts user in    $r->connection->user and role in $ENV{ROLE}  

 A line in error.log is added when user get a connection .

 Note: this module works this apache2 , you can use it this apache-1.3nn with minor modifications (use Apache::Log instead use Apache2::Log )  

=head1 SEE ALSO

Lemonldap websso at http://lemonldap.sourceforge.net


=head1 AUTHOR

Eric German, E<lt>germanlinux@yahoo.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Eric German

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
