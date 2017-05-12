package Cikl::Smrt::Parsers;

use strict;
use warnings;

use Carp;
use Module::Pluggable search_path => "Cikl::Smrt::Parsers", 
      require => 1, sub_name => '_parsers', on_require_error => \&croak;


## time perl  cikl_smrt -C cikl.conf  -r rules/etc/00_alexa_whitelist.cfg -f top100 -v2
#use Cikl::Smrt::Parsers::ParseDelim;
#
## time perl  cikl_smrt -C cikl.conf  -r rules/etc/malwaredomainlist.cfg -f malwaredomainlist -v2
#use Cikl::Smrt::Parsers::ParseCsv;
#
## time perl  cikl_smrt -C cikl.conf  -r rules/etc/phishtank.cfg -f urls -v2 
#use Cikl::Smrt::Parsers::ParseJson;
#
## time perl  cikl_smrt -C cikl.conf  -r rules/etc/zeustracker.cfg -f binaries -g 90
#use Cikl::Smrt::Parsers::ParseRss;
#
## time perl  cikl_smrt -C cikl.conf  -r rules/etc/misc.cfg -f sshbl.org
#use Cikl::Smrt::Parsers::ParseTxt;
#
## time perl  cikl_smrt -C cikl.conf  -r rules/etc/cleanmx.cfg -f malware 
#use Cikl::Smrt::Parsers::ParseXml;

sub new {
  my $class = shift;

  my $self = {};

  bless $self, $class;
  $self->{parser_map} = $self->_init_parsers();

  return $self;
}

sub _init_parsers {
  my $self = shift;
  my $ret = {};
  foreach my $parser (__PACKAGE__->_parsers()) {
    my $parser_name = $parser->name();
    if (my $existing = $ret->{$parser_name}) {
      die("Cannot associate $parser with $parser_name. Already registered with $existing.");
    }
    $ret->{$parser_name} = $parser;
  }
  return $ret;
}

sub valid_parser_names {
  my $self = shift;
  return(keys(%{$self->{parser_map}}));
}

sub valid_parser_names_string {
  my $self = shift;
  return(join(", ", $self->valid_parser_names()));
}

sub get {
  my $self = shift;
  my $parser_name = shift;
  return $self->{parser_map}->{$parser_name};
}

1;
