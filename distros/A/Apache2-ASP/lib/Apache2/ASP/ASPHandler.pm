
package Apache2::ASP::ASPHandler;

use strict;
use warnings 'all';
use base 'Apache2::ASP::HTTPHandler';
use Carp 'confess';
use vars __PACKAGE__->VARS;

use Data::Dumper;

#==============================================================================
sub run
{
  my ($s, $context, $args) = @_;
  
  $s->init_asp_objects( $context );

  # Find the page:
  $ENV{SCRIPT_FILENAME} .= 'index.asp'
    unless $ENV{SCRIPT_FILENAME} =~ m/\.asp$/;
  $ENV{SCRIPT_NAME} .= 'index.asp'
    unless $ENV{SCRIPT_NAME} =~ m/\.asp$/;
  my $asp_filename = $Request->ServerVariables('SCRIPT_FILENAME')
    or return;
  my $cache_root = $Config->web->page_cache_root;
  my $web_root = $Config->web->www_root;
  (my $pm_filename = $asp_filename) =~ s/^\Q$web_root\E\///; # =~ m/([^\/]+)$/;
  $pm_filename =~ s/[^a-z0-9_]/_/ig;
  $pm_filename .= ".pm";
  my $pm_folder = $cache_root . '/' . $Config->web->application_name;
  my $pm_path = $pm_folder . '/' . $pm_filename;
  mkdir( $pm_folder ) unless -d $pm_folder;
  my $pkg_path = $Config->web->application_name . '/' . $pm_filename;
  
  push @INC, $cache_root unless grep { $_ eq $cache_root } @INC;
  if( -f $asp_filename )
  {
    (my $pkg_name = $pkg_path) =~ s/\//::/g;
    $pkg_name =~ s/\.pm$//;
    if( ( ! -f $pm_path ) || ((stat($asp_filename))[9] > (stat($pm_path))[9] ) )
    {
      require Apache2::ASP::ASPPage;
      Apache2::ASP::ASPPage->init_asp_objects( $context );
      Apache2::ASP::ASPPage->new( virtual_path => $ENV{SCRIPT_NAME} );
    }# end if()
    
    # Now load and execute the compiled ASP:
#    eval {
      delete($INC{$pkg_path});
      require $pkg_path;
      my $page = $pkg_name->new( virtual_path => $ENV{SCRIPT_NAME} );
      $page->run( $context, $args );
      return $context->response->Status == 200 ? 0 : $context->response->Status;
#    };
    if( $@ )
    {
      $context->response->Status( 500 );
      confess $@;
    }# end if()
  }
  else
  {
    return $context->response->Status( 404 );
  }# end if()
}# end run()

1;# return true:

=pod

=head1 NAME

Apache2::ASP::ASPHandler - handler for all *.asp requests

=head1 SYNOPSIS

Internal use only.

=head1 DESCRIPTION

This class is the L<Apache2::ASP::HTTPHandler> subclass responsible for handling
all requests to C<*.asp> scripts.

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

