#!/usr/bin/perl -w
package CGI::ToXML;

#=============================================================================
#
# $Id: ToXML.pm,v 0.02 2002/02/05 01:09:18 mneylon Exp $
# $Revision: 0.02 $
# $Author: mneylon $
# $Date: 2002/02/05 01:09:18 $
# $Log: ToXML.pm,v $
# Revision 0.02  2002/02/05 01:09:18  mneylon
# Slight fix in POD docs
#
# Revision 0.01  2002/02/03 17:11:44  mneylon
# Initial release to Perlmonks
#
#
#=============================================================================

use strict;
use XML::Simple;

BEGIN {
  use Exporter   ();
  use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
  $VERSION     = sprintf( "%d.%02d", q( $Revision: 0.02 $ ) =~ /\s(\d+)\.(\d+)/ );
  @ISA         = qw(Exporter);
  @EXPORT      = qw();
  @EXPORT_OK   = qw( CGItoXML );
  %EXPORT_TAGS = (  );
}

sub CGItoXML {
  my ( $cgi, %options ) = @_;
  if ( ! $cgi->isa( "CGI" ) ) {
    warn "CGItoXML: Object isn't a CGI object, cannot convert";
    return undef;
  }

  # Determine which parameters we keep or not
  my @paramlist = $cgi->param;

  # Exclude what we can first...
  if ( exists $options{ exclude } ) {
    my %exclude_hash; $exclude_hash{ $_ }++ foreach @{ $options{ exclude } };
    @paramlist = grep { !exists( $exclude_hash{ $_ } ) } @paramlist;
  }

  # Include what we can...
  if ( exists $options{ include } ) {
    my %include_hash; $include_hash{ $_ }++ foreach @{ $options{ include } };
    @paramlist = grep { exists( $include_hash{ $_ } ) } @paramlist;
  }

  # Set up the hashes to be used for conversion

  my @params;
  foreach my $param ( @paramlist ) {
    my @values;
    # Ensure we get values as an array
    foreach my $value ( $cgi->param( $param ) ) {
      push @values, $value;
    }
    push @params, { parameter => { name => $param,
				   value => \@values } };
  }

  my %cgi_hash = ( cgi => {
			   generator => "CGI::toXML",
			   version => $VERSION,
			   parameter => \@params } );

  return XMLout( \%cgi_hash, rootname => undef ) ;
}


1;
__END__

=head1 NAME

CGI::ToXML - Converts CGI to an XML structure

=head1 SYNOPSIS

  use CGI::ToXML qw( CGItoXML );
  use CGI;

  my $q = new CGI;
  my $xml = CGItoXML( $q );
  my $xml2 = CGItoXML( $q, exclude => [ qw( password username sessionid ) ] );

=head1 DESCRIPTION

Converts a CGI variable (from CGI.pm) to an XML data structure.  While 
there is currently a similar module, CGI::XML, by Jonathan Eisenzopf,
the outputted XML is not in a very usable format, given the newer advances
in XML (such as XSLT, XPath, etc).  CGI::ToXML aims to correct this by
providing a cleaner XML structure that will be more useful.  The XML is
generated from XML::Simple, keeping this a 'lightweight' function.

The module consists of a single function:

  $xml = CGItoXML( $cgi, %options )

$cgi must be a valid CGI.pm object, and if not, a warning will be issued
and the function will return undef.  Otherwise, the function will return
the XML as a string.  The XML structure will be similar to the following:

  <cgi version="0.01" generator="CGI::toXML">
    <parameter name="dinosaur">
      <value>barney</value>
      <value>godzilla</value>
    </parameter>
    <parameter name="color">
      <value>purple</value>
    </parameter>
  </cgi>

as generated from the query string:

  "dinosaur=barney&dinosaur=godzilla&color=purple"

The order of parameters and multivalued entries, as returned by CGI, is
maintained in the XML.

The options hash can be used to customize the behavior a bit more:

=over 4

=item include => [ list ]

Only include the parameters and their values specified in the given list;
all other parameters are not included.  Note that this does not affect the
CGI object storage.

=item exclude => [ list ]

Do not include the parameters and their values specified in the given list; 
all other parameters are included.  Note that this does not affect the
CGI object storage.

=back

=head1 EXPORT

No functions are exported by default, but CGItoXML can be exported by
the user.

=head1 AUTHOR

Michael K. Neylon, E<lt>mneylon-pm@masemware.comE<gt>

=head1 SEE ALSO

L<perl>, L<CGI::XML>, L<XML::Simple>.

=cut
