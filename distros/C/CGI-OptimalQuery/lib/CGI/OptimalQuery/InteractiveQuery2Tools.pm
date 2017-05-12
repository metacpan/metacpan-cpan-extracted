package CGI::OptimalQuery::InteractiveQuery2Tools;

use strict;
use warnings;
no warnings qw( uninitialized );
use base 'CGI::OptimalQuery::Base';

sub output {
  my $o = shift;

  # if request to open tool panel, execute tool on_open function
  if ($$o{q}->param('tool') ne '') {
    my $openedtool = $$o{q}->param('tool');
    my $tool = $$o{schema}{tools}{$openedtool};
    if (! $tool || ! $$tool{on_open}) {
      $$o{output_handler}->(CGI::header('text/html')."<!DOCTYPE html>\n<html><body>could not find tool</body></html>");
    } else {
      my $buf = $$tool{on_open}->($o);
      $$o{output_handler}->(CGI::header('text/html')."<!DOCTYPE html>\n<html><body>$buf</body></html>") if $buf;
    }
  }

  # else noop, trust that a tool on_init function has already responded

  return undef;
}

1;
