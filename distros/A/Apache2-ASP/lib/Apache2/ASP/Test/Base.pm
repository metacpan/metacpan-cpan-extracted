
package Apache2::ASP::Test::Base;

use strict;
use warnings 'all';
use Apache2::ASP::ConfigLoader;
use Apache2::ASP::Test::UserAgent;
use Apache2::ASP::Test::Fixtures;
use Data::Properties::YAML;


#==============================================================================
sub new
{
  my $class = shift;
  
  my $config = Apache2::ASP::ConfigLoader->load();
  
  # Our test fixtures:
  my $data = Apache2::ASP::Test::Fixtures->new(
    properties_file => $config->web->application_root . '/etc/test_fixtures.yaml'
  ) if -f $config->web->application_root . '/etc/test_fixtures.yaml';
  
  # Our diagnostic messages:
  my $properties = Data::Properties::YAML->new(
    properties_file => $config->web->application_root . '/etc/properties.yaml'
  ) if -f $config->web->application_root . '/etc/properties.yaml';
  
  my $s = bless {
    # TBD:
    ua     => Apache2::ASP::Test::UserAgent->new( config => $config ),
    config => $config,
    data   => $data,
    properties  => $properties,
  }, $class;
  
  return $s;
}# end new()


#==============================================================================
sub ua { $_[0]->{ua} }
sub config { $_[0]->{config} }
sub data { $_[0]->{data} }  # Deprecated
sub test_fixtures { $_[0]->{data} }
sub diags { $_[0]->{properties} } # Deprecated
sub properties { $_[0]->{properties} }
sub session { $_[0]->{ua}->context->session }

1;# return true:

=head1 NAME

Apache2::ASP::Test::Base  - base class for all test helper objects.

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  
  use strict;
  use warnings 'all';
  use Test::More 'no_plan';
  use Apache2::ASP::Test::Base;
  
  ok( my $t = Apache2::ASP::Test::Base->new() );
  
  my $res = $t->ua->get("/index.asp");
  ok( $res->is_success );
  is( $res->header('location') => undef );

=head1 DESCRIPTION

The whole point of writing Apache2::ASP was to enable command-line testing
of entire websites - and to gather statistics via L<Devel::Cover> and L<Devel::NYTProf>.

Somehow the test-driven-development world completely missed the point:

B<YOU HAVE GOT TO TEST YOUR WEB PAGES SOMEHOW!!>

Apache2::ASP and this class provide an excellent means of doing that.

See the C</t> folder in this distribution for several examples of testing different
kinds of functionality with C<Apache2::ASP::Test::Base>.

=head1 PUBLIC PROPERTIES

=head2 ua

Returns the current L<Apache2::ASP::Test::UserAgent> object.

=head2 config

Shortcut method to the current L<Apache2::ASP::Config> object.

=head2 test_fixtures

Shortcut method to the current L<Data::Properties::YAML> object
representing the test fixtures found in C</etc/test_fixtures.yaml>

=head2 properties

Shortcut method to the current L<Data::Properties::YAML> object
representing the properties found in C</etc/properties.yaml>

=head2 session

Shortcut method to the current L<Apache2::ASP::SessionStateManager> object.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut

