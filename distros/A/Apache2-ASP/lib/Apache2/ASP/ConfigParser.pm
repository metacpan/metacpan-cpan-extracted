
package Apache2::ASP::ConfigParser;

use strict;
use warnings 'all';
use Apache2::ASP::Config;


#==============================================================================
sub new
{
  my ($class) = @_;
  
  return bless { }, $class;
}# end new()


#==============================================================================
sub parse
{
  my ($s, $doc, $root) = @_;
  
  # Start out with the <system>
  SYSTEM: {
    $doc->{system}->{libs} ||= { };
    if( $doc->{system}->{libs}->{lib} )
    {
      $doc->{system}->{libs}->{lib} = [ $doc->{system}->{libs}->{lib} ]
        unless ref($doc->{system}->{libs}->{lib}) eq 'ARRAY';
    }
    else
    {
      $doc->{system}->{libs}->{lib} = [ ];
    }# end if()
    
    $doc->{system}->{load_modules} ||= { };
    if( $doc->{system}->{load_modules}->{module} )
    {
      $doc->{system}->{load_modules}->{module} = [ $doc->{system}->{load_modules}->{module} ]
        unless ref($doc->{system}->{load_modules}->{module}) eq 'ARRAY';
    }
    else
    {
      $doc->{system}->{load_modules}->{module} = [ ];
    }# end if()

    $doc->{system}->{env_vars} ||= { };
    if( $doc->{system}->{env_vars}->{var} )
    {
      $doc->{system}->{env_vars}->{var} = [ delete($doc->{system}->{env_vars}->{var}) ]
        unless ref($doc->{system}->{env_vars}->{var}) eq 'ARRAY';
      my $ref = delete($doc->{system}->{env_vars}->{var});
      $doc->{system}->{env_vars}->{var} = [ ];
      foreach my $item ( grep { $_->{name} } @$ref )
      {
        push @{$doc->{system}->{env_vars}->{var}}, { $item->{name} => $item->{value} };
      }# end foreach()
    }
    else
    {
      $doc->{system}->{env_vars}->{var} = [ ];
    }# end if()
    
    # Post-processor:
    $doc->{system}->{post_processors} ||= { };
    if( $doc->{system}->{post_processors}->{class} )
    {
      $doc->{system}->{post_processors}->{class} = [ $doc->{system}->{post_processors}->{class} ]
        unless ref($doc->{system}->{post_processors}->{class}) eq 'ARRAY';
    }
    else
    {
      $doc->{system}->{post_processors}->{class} = [ ];
    }# end if()
  };
  
  WEB: {
    $doc->{web}->{request_filters} ||= { };
    if( $doc->{web}->{request_filters}->{filter} )
    {
      $doc->{web}->{request_filters}->{filter} = [ delete($doc->{web}->{request_filters}->{filter}) ]
        unless ref($doc->{web}->{request_filters}->{filter}) eq 'ARRAY';
    }
    else
    {
      $doc->{web}->{request_filters}->{filter} = [ ];
    }# end if()

    $doc->{web}->{disable_persistence} ||= { };
    if( $doc->{web}->{disable_persistence}->{location} )
    {
      $doc->{web}->{disable_persistence}->{location} = [ delete($doc->{web}->{disable_persistence}->{location}) ]
        unless ref($doc->{web}->{disable_persistence}->{location}) eq 'ARRAY';
    }
    else
    {
      $doc->{web}->{disable_persistence}->{location} = [ ];
    }# end if()
  };
  
  DATA_CONNECTIONS: {
    $doc->{data_connections} ||= { };
    $doc->{data_connections}->{session} ||= { };
    $doc->{data_connections}->{application} ||= { };
    $doc->{data_connections}->{main} ||= { };
  };
  
  my $config = Apache2::ASP::Config->new( $doc, $root );
  
  # Now do any post-processing:
  foreach my $class ( $config->system->post_processors )
  {
    (my $file = "$class.pm") =~ s/::/\//;
    require $file unless $INC{$file};
    $config = $class->new()->post_process( $config );
  }# end foreach()
  
  return $config;
}# end parse()

1;# return true:

=pod

=head1 NAME

Apache2::ASP::ConfigParser - Initial Configuration parser

=head1 SYNOPSIS

  # You will never use this module.

=head1 DESCRIPTION

This package handles the transformation of the configuration data from a simple hashref
into a nicely standardized, blessed hashref.

=head1 PUBLIC METHODS

=head2 parse( \%doc, $application_root )

Returns an instance of L<Apache2::ASP::Config>.

Converts a specially-constructed hashref into an instance of L<Apache2::ASP::Config>.

Any L<Apache2::ASP::ConfigPostProcessor> classes listed in the C<system.post_processors>
section of the configuration will be called be called at the last moment, just before
returning the configuration object.

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

