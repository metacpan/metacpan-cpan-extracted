
package Apache2::ASP::ConfigNode::System::Settings;

use strict;
use warnings 'all';
use base 'Apache2::ASP::ConfigNode';


#==============================================================================
sub new
{
  my $class = shift;
  
  my $s = $class->SUPER::new( @_ );
  
  return $s;
}# end new()


#==============================================================================
sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  
  my ($name) = $AUTOLOAD =~ m/([^:]+)$/;
  
  my ($val) = grep {
    $_->{name} eq $name
  } @{ $s->{setting} };
  
#  defined($val) or return;
  return $val->{value};
}# end AUTOLOAD()

1;# return true:

=pod

=head1 NAME

Apache2::ASP::ConfigNode::System::Settings - The $Config->system->settings collection

=head1 SYNOPSIS

Given an XML config file like this:

  <?xml version="1.0"?>
  <config>
    ...
    <system>
      ...
      <settings>
        ...
        <setting>
          <name>encryption_key</name>
          <value>k23j4hkj234hkj23h4kj2h34kj2h34</value>
        </setting>
        ...
      </settings>
      ...
    </system>
    ...
  </config>

You would access the data like this:

  my $encryption_key = $Config->system->settings->encryption_key;

=head1 DESCRIPTION

Settings are an eventual fact of life in any sufficiently complex web application.

This package provides read-only access to the settings you describe in your XML
config file.

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

