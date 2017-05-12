package Apache::SiteControl::Radius;

use 5.008;
use strict;
use warnings;
use Carp;
use Authen::Radius;
#use Apache::Connection;
#use Apache::RequestRec;
#use APR::SockAddr;

our $VERSION = "1.0";

sub check_credentials
{
   my $r    = shift;  # Apache request object
   my $username = shift;
   my $password = shift;
   my $host = $r->dir_config("RadiusSiteControlHost") || "localhost";
   my $secret = $r->dir_config("RadiusSiteControlSecret") || "unknown";
   my $radius;

   # Get my IP address to pass as the
   # Source IP and NAS IP Address
   # TODO: Only works with apache 2...uncommented for now
   #my $c = $r->connection;
   #my $sockaddr = $c->local_addr if defined($c);
   my $nas_ip_address = undef; # $sockaddr->ip_get if defined($sockaddr);

   $r->log_error("WARNING: Shared secret is not set. Use RadiusSiteControlSecret in httpd.conf") if $secret eq "unknown";

   $radius = new Authen::Radius(Host => $host, Secret => $secret);
   if(!$radius) {
      $r->log_error("Could not contact radius server!");
      return 0;
   }
   if($radius->check_pwd($username, $password, $nas_ip_address)) {
      return 1;
   }
   $r->log_error("User $username failed authentication:" . $radius->strerror);
   return 0;
}

1;

__END__

=head1 NAME

Apache::SiteControl::Radius - Raduis authentication module for SiteControl

=head1 SYNOPSIS

In Apache/mod_perl's configuration:

=over 4

   PerlModule Apache::SiteControl

   <Location /sample>
   ...
      PerlSetVar SiteControlMethod Apache::SiteControl::Radius
   ...
   </Location>

   <FilesMatch "\.pl$">
    ...
    PerlSetVar RadiusSiteControlHost "localhost"
    PerlSetVar RadiusSiteControlSecret "mysecret"
    ...
   </FilesMatch>

   <Location /SampleLogin>
    ...
      PerlSetVar RadiusSiteControlHost "localhost"
      PerlSetVar RadiusSiteControlSecret "mysecret"
    ...
   </Location>

=back

=head1 DESCRIPTION

Apache::SiteControl::Radius uses Authen::Radius to do the actual authentication
of login attempts for the SiteControl system. See the SiteControl documentation
for a complete apache configuration example. The synopsis above shows the
configuration parameters for the radius module only, which is not a stand-alone
thing.

The proper variables for the apache configuration of this modules are shown in
the synopsis above. You must set the radius host and shared secret in all
sections that will use the SiteControl system for authentication.

=head1 SEE ALSO

Apache::SiteControl

=head1 AUTHOR

This module was written by Tony Kay, E<lt>tkay@uoregon.eduE<gt>.

=head1 COPYRIGHT AND LICENSE

=cut
