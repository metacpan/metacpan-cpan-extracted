
package ASP4::ConfigLoader;

use strict;
use warnings 'all';
use Carp 'confess';
use ASP4::ConfigFinder;
use ASP4::ConfigParser;
use JSON::XS;

our $Configs = { };


#==============================================================================
sub load
{
  my ($s) = @_;
  
  my $path = ASP4::ConfigFinder->config_path;
  my $file_time = (stat($path))[7];
  if( exists($Configs->{$path}) && ( $file_time <= $Configs->{$path}->{timestamp} ) )
  {
    return $Configs->{$path}->{data};
  }# end if()
  
  open my $ifh, '<', $path
    or die "Cannot open '$path' for reading: $!";
  local $/;
  my $doc = decode_json( scalar(<$ifh>) );
  close($ifh);
  
  (my $where = $path) =~ s/\/conf\/[^\/]+$//;
  $Configs->{$path} = {
    data      => ASP4::ConfigParser->new->parse( $doc, $where ),
    timestamp => $file_time,
  };
  return $Configs->{$path}->{data};
}# end parse()

1;# return true:

__END__

=pod

=head1 NAME

ASP4::ConfigLoader - Universal access to the configuration.

=head1 SYNOPSIS

  use ASP4::ConfigLoader;
  
  my $Config = ASP4::ConfigLoader->load();
  
  # $Config is a ASP4::Config object.

=head1 DESCRIPTION

This package solves the "How do I get my config?" problem most web applications
end up with at some point.

Config data is cached on a per-path basis.  Paths are full - i.e. C</usr/local/projects/mysite.com/conf/asp4-config.json> - 
so there should never be a clash between two different configurations on the
same web server, even if it is running multiple websites as VirtualHosts.

=head1 PUBLIC METHODS

=head2 load( )

Returns a L<ASP4::Config> object.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut

