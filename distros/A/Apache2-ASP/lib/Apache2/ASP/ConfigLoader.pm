
package Apache2::ASP::ConfigLoader;

use strict;
use warnings 'all';
use Carp 'confess';
use Apache2::ASP::ConfigFinder;
use Apache2::ASP::ConfigParser;
use XML::Simple ();
$XML::Simple::PREFERRED_PARSER = 'XML::Parser';

our $Configs = { };


#==============================================================================
sub load
{
  my ($s) = @_;
  
  my $path = Apache2::ASP::ConfigFinder->config_path;
  return $Configs->{$path} if $Configs->{$path};
  
  my $doc = XML::Simple::XMLin( $path,
    SuppressEmpty => '',
    ForceArray => [qw/ var setting location /],
    KeyAttr => { },
  );
  
  (my $where = $path) =~ s/\/conf\/[^\/]+$//;
  return $Configs->{$path} = Apache2::ASP::ConfigParser->new->parse( $doc, $where );
}# end parse()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::ConfigLoader - Universal access to the configuration.

=head1 SYNOPSIS

  use Apache2::ASP::ConfigLoader;
  
  my $Config = Apache2::ASP::ConfigLoader->load();
  
  # $Config is a Apache2::ASP::Config object.

=head1 DESCRIPTION

This package solves the "How do I get my config?" problem most web applications
end up with at some point.

Config data is cached on a per-path basis.  Paths are full - i.e. C</usr/local/projects/mysite.com/conf/apache2-asp-config.xml> - 
so there should never be a clash between two different configurations on the
same web server, even if it is running multiple websites as VirtualHosts.

=head1 PUBLIC METHODS

=head2 load( )

Returns a L<Apache2::ASP::Config> object.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut

