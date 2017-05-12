#!/usr/bin/perl -w

# Copyright  (c)  2015-2017  T.v.Dein <tlinden  |AT|  cpan.org>.   All
# Rights Reserved. Std. disclaimer applies.  Artistic License, same as
# perl itself. Have fun.

# This  script  can   be  used  to  interactively   browse  perl  data
# structures, which it reads from STDIN or a file. You can use it, for
# instance, by printing some data  structure in your application using
# Data::Dumper and piping this output into this scripts input.

# However,  if the  argument is  a file  and has  a known  suffix, the
# script  automatically converts  it into  a perl  data structure  and
# drops  you into  an interactive  shell on  that.  That  way you  can
# interactively browse XML or YAML files. Supported suffixes are: xml,
# json, csv, yml, ini, conf.

# If the data structure evaulates, you'll be dropped into an interactive
# prompt. Enter '?' to get help.

# The script also demonstrates how to use different serializers.

use Data::Interactive::Inspect;
use Data::Dumper;
use YAML; # needs to be installed anyway
use strict;


sub usage {
  print STDERR qq(
Usage: $0 <file|-h>

Reads a  perl data structure  from <file>. If  <file> is -,  read from
STDIN. Evaluates  and start an  interactive Data::Interactive::Inspect
shell, which can be used to analyze the data.
);
  exit 1;
}


my $arg  = shift;
my $perl = 1;
my ($code);

if (! $arg) {
  usage;
}

if ($arg ne '-' && ! -e $arg) {
  print STDERR "$arg not found or not readable!\n";
  usage;
}

if ($arg eq '-') {
   loaddumper(join '', <>);
}
else {
  if ($arg =~ /\.xml$/i) {
    eval { require XML::Simple; };
    die "Sorry, XML::Simple is not installed, XML not supported!\n" if($@);
    my $xml = new XML::Simple;
    $code = $xml->XMLin($arg);
    $perl = 0;
  }
  elsif ($arg =~ /\.(yaml|yml)$/i) {
    $code = YAML::LoadFile($arg);
    $perl = 0;
  }
  elsif ($arg =~ /\.ini$/i) {
    eval { require Config::INI::Reader; };
    die "Sorry, Config::INI is not installed, INI not supported!\n" if($@);
    $code = Config::INI::Reader->read_file($arg);
    $perl = 0;
  }
  elsif ($arg =~ /\.conf$/i) {
    eval { require Config::General; };
    die "Sorry, Config::General is not installed, CONF not supported!\n" if($@);
    %{$code} = Config::General::ParseConfig(-ConfigFile => $arg, -InterPolateVars => 1, -UTF8 => 1);
    $perl = 0;
  }
  elsif ($arg =~ /\.json$/i) {
    eval { require JSON; };
    die "Sorry, JSON is not installed, JSON not supported!\n" if($@);
    my $json = JSON->new->utf8();
    $code = $json->decode(slurp($arg));
  }
  elsif ($arg =~ /\.csv$/i) {
    eval { require Text::CSV::Slurp; };
    die "Sorry, Text::CSV::Slurp is not installed, CSV not supported!\n" if($@);
    $code = Text::CSV::Slurp->load(file => $arg);
  }
  else {
    loaddumper(slurp($arg));
  }
}

if ($@) {
  print STDERR "Parser or Eval error: $@!\n";
  exit 1;
}
else {
  if ($perl) {
    Data::Interactive::Inspect->new(struct      => $code,
                                    serialize   => sub { my $db = shift;
                                                         my $c = Dumper($db);
                                                         $c =~ s/^\s*\$[a-zA-Z0-9_]*\s*=\s*/        /;
                                                         return $c;
                                                       },
                                    deserialze  => sub { my $code = shift;
                                                         $code = "\$code = $code";
                                                         eval $code;
                                                         return $code;
                                                       },
                                   )->inspect;
  }
  else {
    # no perl struct, stay with default
    Data::Interactive::Inspect->new(struct => $code)->inspect;
  }
}


sub slurp {
  my $arg = shift;
  open CODE, "<$arg" or die "Could not open data file $arg: $!\n";
  my $code = join '', <CODE>;
  close CODE;
  return $code;
}

sub loaddumper {
  my $dump = shift;
  $dump =~ s/^\s*\$[a-zA-Z0-9_]*\s*=\s*/\$code = /;
  eval $dump; # fills global $code
}







