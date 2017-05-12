#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use LWP;
use Data::Dumper;
use File::Slurp;
use App::Chart::Suffix::FQ;

use FindBin;
my $progname = $FindBin::Script;


{
  require Module::Find;
  require Module::Load;
  require Data::Dumper;

  my %method_to_modules;
  foreach my $module (Module::Find::findsubmod ('Finance::Quote')) {
    say $module;
    next if ($module =~ /UserAgent$/);

    Module::Load::load ($module);
    my %method_to_func = $module->methods;
    my @methods = keys %method_to_func;
    print "  ", Data::Dumper->Dump([\@methods],['sources']);

    $module =~ s/^Finance::Quote:://;
    foreach my $method (@methods) {
      push @{$method_to_modules{$method}}, $module;
    }
  }
  print Data::Dumper->new([\%method_to_modules],['method_to_modules'])
    ->Sortkeys(1)->Dump;

  require Array::Compare;
  my $comp = Array::Compare->new;

  foreach my $method (keys %method_to_modules) {
    my @func = App::Chart::Suffix::FQ::method_to_modules ($method);
    my @grep = @{$method_to_modules{$method}};

    @func = sort @func;
    @grep = sort @grep;
    my $func = join (', ', @func);
    my $grep = join (', ', @grep);
    if ($func ne $grep) {
      # if ($comp->compare (\@func, \@grep)) {
      print "different $method\n",
        Data::Dumper->new([\@func,\@grep],['func','grep'])->Dump;
    }
  }

  exit 0;
}

{
#   require Finance::Quote;
#   my $q = Finance::Quote->new ('-defaults', 'MLC');
#   my $sources = $q->sources;
#   print Data::Dumper->new([$sources],['sources'])->Sortkeys(1)->Dump;

  say "$progname: ", App::Chart::Suffix::FQ::quoter_for_method('tsp');
  exit 0;
}

{
  say "$progname: ", App::Chart::Suffix::FQ::method_to_modules('asx');
}


{
  require Finance::Quote;
  my $q = Finance::Quote->new;
  my %rates = $q->fetch ('xyz','BHP');

  print Data::Dumper->new([\%rates],['rates'])->Sortkeys(1)->Dump;
  exit 0;
}
{
  require Finance::Quote;
  my $q = Finance::Quote->new ('-defaults');
  my %rates = $q->fetch ('asx','BHP');

  print Data::Dumper->new([\%rates],['rates'])->Sortkeys(1)->Dump;
  exit 0;
}
{
  require Finance::Quote;
  my $q = Finance::Quote->new ('-defaults');
  my %rates = $q->fetch ('tsp','C','L');

  require Data::Dumper;
  { no warnings; $Data::Dumper::Sortkeys = 1; }
  print Data::Dumper::Dumper(\%rates);

  exit 0;
}
{
  my $resp = HTTP::Response->new();
  my $content = File::Slurp::slurp ($ENV{'HOME'}.'/chart/samples/athex/dividends.asp.html');
  $resp->content($content);
  $resp->{'_rc'} = 200;
  my $h = App::Chart::Suffix::ATH::dividends_parse ($resp);
  print Dumper ($h);
  exit 0;
}




{
  my $tdate = App::Chart::Float::available_tdate();
  print "$tdate\n";
  print App::Chart::tdate_to_ymd ($tdate);
  exit 0;
}
