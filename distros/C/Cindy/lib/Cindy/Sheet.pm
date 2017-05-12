# $Id: Sheet.pm 125 2014-09-23 06:02:55Z jo $
# Cindy::Sheet - Parsing Content Injection Sheets
#
# Copyright (c) 2008 Joachim Zobel <jz-2008@heute-morgen.de>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
package Cindy::Sheet;

use strict;
use warnings;

use Cindy::CJSGrammar;
use Cindy::Injection;
use Cindy::Log;

#$::RD_TRACE = 1;
#$::RD_HINT = 1;
#$::RD_WARN = 1;

sub PARSER { 
  my $rtn = Cindy::CJSGrammar->new()
  or die "Failed to create CJSGrammar.";
  $rtn->{__error_collector} = [];
  return $rtn;
}

sub die_on_errors
{
  my ($errors) = @_;
  if ($errors and scalar(@{$errors})) {
    DEBUG "CJS: Dying on errors.";
    die join("\n", map {"line $_->[1]: $_->[0]"} @{$errors})."\n";
  }
  return 0; 
}

sub collect_errors
{
  my ($parser) = @_;
  my $errors = $parser->{errors};
  DEBUG "CJS: Appending errors:"
      . join("\n", map {"line $_->[1]: $_->[0]"} @{$errors});
  push(@{$parser->{__error_collector}}, @{$errors});
  return 0; 
}

#
# parse_cis
#
# file - The name of the file to read the injection sheet from
#
# return: A reference to a array of injections obtained from 
#         parsing. 
#
sub parse_cis($)
{
  my ($file) = @_;
  open(my $CIS, '<', $file) 
  or die "Failed to open $file:$!";
  my $text;
  read($CIS, $text, -s $CIS);
  close($CIS);
  my $parser = PARSER();
  my $rtn = $parser->complete_injection_list($text);
  die_on_errors($parser->{__error_collector});
  return $rtn;
}

#
# parse_cis_string
#
# $ - The injection sheet as a string
#
# return: A reference to a array of injections obtained from 
#         parsing. 
#
sub parse_cis_string($)
{
  my $parser = PARSER();
  my $rtn = $parser->complete_injection_list($_[0]);
  die_on_errors($parser->{__error_collector});
  return $rtn;
}

1;

