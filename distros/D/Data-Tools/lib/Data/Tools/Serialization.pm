##############################################################################
#
#  Data::Tools::Serialization perl module
#  Copyright (c) 2013-2024 Vladi Belperchinov-Shabanski "Cade" 
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/  
#
#  GPL
#
##############################################################################
package Data::Tools::Serialization;
use strict;
use Exporter;
use Carp;
use Data::Tools;
use Math::BigFloat;

our $VERSION = '1.47';

our @ISA    = qw( Exporter );
our @EXPORT = qw(

                  xml2perl
                  perl2xml
                  
                  json2perl
                  perl2json

                );

our %EXPORT_TAGS = (
                   
                   'all'  => \@EXPORT,
                   'none' => [],
                   
                   );

##############################################################################

BEGIN
{
  require XML::Bare;
  require JSON;
}

sub xml2perl
{
  my $ob = new XML::Bare( text => shift() );
  return $ob->parse();
}

sub perl2xml
{
  return XML::Bare::obj2xml( shift() );
}
                  
sub json2perl
{
  return JSON::decode_json( shift );
}

sub perl2json
{
  return JSON::encode_json( shift );
}

##############################################################################

=pod


=head1 NAME

  Data::Tools::Serialization provides set of high-level serialization 
  and deserialization wrapper functions.

=head1 SYNOPSIS

  use Data::Tools::Serialization qw( :all );  # import all functions
  use Data::Tools::Serialization;             # the same as :all :) 
  use Data::Tools::Serialization qw( :none ); # do not import anything

  # --------------------------------------------------------------------------

  my $perl_hoh = xml2perl( $xml_text );
  my $xml_text = perl2xml( $perl_hoh );

  my $perl_hoh  = json2perl( $json_text );
  my $json_text = perl2json( $perl_hoh  );

  # --------------------------------------------------------------------------

=head1 FUNCTIONS

=head2 xml2perl( $xml_text )

Returns perl hash of hashes reference representing the XML data text.

=head2 perl2xml( $perl_hoh )

Returns xml text representing the in-memory perl hash of hashes structure.

=head2 json2perl( $xml_text )

Returns perl hash of hashes reference representing the JSON data text.

=head2 perl2json( $perl_hoh )

Returns JSON text representing the in-memory perl hash of hashes structure.

=head1 REQUIRED MODULES

Data::Tools::Serialization uses:

  * XML::Bare
  * JSON
  
all are loaded on demand and are not initial requirement nor if just other
parts of the Data::Tools are used.

=head1 GITHUB REPOSITORY

  git@github.com:cade-vs/perl-data-tools.git
  
  git clone git://github.com/cade-vs/perl-data-tools.git
  
=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
  http://cade.noxrun.com/  


=cut

##############################################################################
1;
