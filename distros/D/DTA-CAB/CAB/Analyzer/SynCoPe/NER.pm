## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::SynCoPe::NER
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA chain: RPC-XML query of an existing SynCoPe server: named-entity recogniztion

##==============================================================================
## Package
##==============================================================================
package DTA::CAB::Analyzer::SynCoPe::NER;
use DTA::CAB::Analyzer::SynCoPe;
use strict;

our @ISA = qw(DTA::CAB::Analyzer::SynCoPe);

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure, %args:
##     server => $url,		##-- xml-rpc server url (default: http://lal.dwds.de:8089/RPC2)
##     label  => $label,        ##-- analysis label (default: 'syncope')
##     method => $method,       ##-- xml-rpc analysis method (default: 'syncop.ne.analyse')
##     useragent => \@args,	##-- args for LWP::UserAgent behind RPC::XML::Client; default: [timeout=>60]
##
##  + low-level object data:
##     client => $cli,          ##-- XML::RPC client for this object
##     xp     => $xp,           ##-- XML::Parser for parsing responses
sub new {
  my $that = shift;
  my $asub = $that->SUPER::new(
			       ##-- analysis selection
			       label => 'ner',
			       server => 'http://lal.dwds.de:8089/RPC2',
			       method => 'syncop.ne.analyse',
			       useragent=>[timeout=>60],

			       ##-- low-level data
			       client => undef,
			       xp     => undef,

			       ##-- user args
			       @_
			      );
  return $asub;
}


1; ##-- be happy

__END__
