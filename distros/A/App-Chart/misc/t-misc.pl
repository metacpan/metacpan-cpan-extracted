#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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

use locale;
use strict;
use warnings;
use List::Util;
use Data::Dumper;
use POSIX;
use Encode qw(:fallback_all);
use I18N::Langinfo qw(langinfo CODESET);

{
  require Data::Dumper;
  print Data::Dumper->new([\@INC],['@INC'])->Dump;

  print $INC{'App/Chart.pm'},"\n";

  require App::Chart;
  print App::Chart::datafilename('chart.xpm'),"\n";
  print App::Chart::datafilename('nosuchfile'),"\n";
  exit 0;
}

{
  require POSIX;
  print "numeric ", POSIX::setlocale(&POSIX::LC_NUMERIC),"\n";
  print "monetar ", POSIX::setlocale(&POSIX::LC_MONETARY),"\n";

  my $loc = POSIX::setlocale( &POSIX::LC_ALL); # , "el_GR" );
  print "Locale = $loc\n";
  my $lconv = POSIX::localeconv();
  print "decimal_point     = ", $lconv->{decimal_point},   "\n";
  print "thousands_sep     = ", $lconv->{thousands_sep},   "\n";
  print "grouping          = ", $lconv->{grouping},        "\n";
  print "int_curr_symbol   = ", $lconv->{int_curr_symbol}, "\n";
  print "currency_symbol   = ", $lconv->{currency_symbol}, "\n";
  print "mon_decimal_point = ", $lconv->{mon_decimal_point}, "\n";
  print "mon_thousands_sep = ", $lconv->{mon_thousands_sep}, "\n";
  print "mon_grouping      = ", $lconv->{mon_grouping},    "\n";
  print "positive_sign     = ", $lconv->{positive_sign},   "\n";
  print "negative_sign     = ", $lconv->{negative_sign},   "\n";
  print "int_frac_digits   = ", $lconv->{int_frac_digits}, "\n";
  print "frac_digits       = ", $lconv->{frac_digits},     "\n";
  print "p_cs_precedes     = ", $lconv->{p_cs_precedes},   "\n";
  print "p_sep_by_space    = ", $lconv->{p_sep_by_space},  "\n";
  print "n_cs_precedes     = ", $lconv->{n_cs_precedes},   "\n";
  print "n_sep_by_space    = ", $lconv->{n_sep_by_space},  "\n";
  print "p_sign_posn       = ", $lconv->{p_sign_posn},     "\n";
  print "n_sign_posn       = ", $lconv->{n_sign_posn},     "\n";

  require Number::Format;
  my $nf = Number::Format->new;
  print Dumper ($nf);
  print $nf->format_number (1235.56, 2, 1),"\n";

  require App::Chart;
  $nf = App::Chart::number_formatter();
  print $nf->format_number (1235.56, 2, 1),"\n";

  exit 0;
}

{
  my $p = \&print;
  open (my $fh, ">", "/dev/stdout") or die;
  $p->($fh,"hello") or die;
  exit 0;
}

{
  my $h = { x => 0};
  eval {
    local $h->{'x'} = 1;
    print $h->{'x'},"\n";
    die;
  };
  print $h->{'x'},"\n";
  exit 0;
}

{
  my @a;
  my $y = pop @a;
  print Dumper(\$y);
  exit 0;

  my $x = undef;
  print Dumper(\$x);
  print $x+0;
  print $^X,"
";
  print $0,"
";
  exit 0;
}
{
  my @a;
  my $x = \@a;
  my $y = \@a;
  print "$x $y\n";
  print $x+0," ",$y+0,"\n";
  exit 0;
}

# package ZZ;
# use strict;
# use warnings;
# use Data::Dumper;
# 
# sub new {
#   return bless {}, 'ZZ';
# }
# sub DESTROY {
#   my ($self) = @_;
#   print Dumper ($self);
#   print Dumper (\$main::x);
# }
# 
# package main;
# my $x = ZZ->new;
# Scalar::Util::weaken ($x);
# exit 0;



{
  open (my $fh, "/nosuchfile");
  my $err = "$!";
  print utf8::is_utf8($err)?"yes":"no","\n";
  print $!;
  exit 0;
}
{
  my $x = 'down';
  if (! $x) {
    print "yes\n";
  } else {
    print "no\n";
  }
  exit 0;
}
{
  my $x = '(?:\/|^)(?:CVS|.svn)\/';

  if ('xsvn/foo' =~ /$x/) {
    print "yes\n";
  } else {
    print "no\n";
  }
  exit 0;
}


{
  my $aref = ref (undef);
  print Dumper ($aref);
  exit 0;
}
{
  my $charset = langinfo (CODESET);
  print "charset $charset\n";

  foreach my $name (@Encode::FB_FLAGS) {
    my $value = eval "$name";
    printf "%-20s %#05X\n", $name, $value;
  }
  require PerlIO::encoding;
  local $PerlIO::encoding::fallback = 0; # FB_DEFAULT, substitute quietly
  local $PerlIO::encoding::fallback = Encode::PERLQQ;
  printf "fallback %#x\n",$PerlIO::encoding::fallback;

  binmode (STDOUT, ":encoding(latin-1)");
  my $str = "\b\x{263a}\n";
  print "len ", length($str),"\n";
  $| = 1;
  print $str;

  $str = "\r\r\r\n";
  print "len ", length($str),"\n";
  $| = 1;
  print $str;
  exit 0;
}

{
  my $loc = setlocale (LC_ALL);
  print "loc ", defined $loc ? $loc : 'undef', "\n";
  exit 0;
}



{
  my $x = \0;
  print Dumper ($x);
  exit 0;
}
#noop(1);
{
  my @a = ();
  my $r = \@a;
  print $r+0,"\n";
  push @a, ('x' x 10000);
  print $r+0,"\n";
  bless $r, ('x' x 100000);
  print $r+0,"\n";
  exit 0;
}
{
  my $x = 1;
  my $y = \$x;
  print $y->can('foo') ? 1 : 0;
  exit 0;
}
{
  my $aref = undef;
  print scalar $#$aref,"\n";
  print scalar @{$aref},"\n";
  print Dumper ($aref);
  exit 0;
}
{
  my $aref = undef;
  foreach (0 .. $#$aref) {
    print $#$aref;
  }
  exit 0;
}
{
  my $self = {};
  foreach my $a (@{$self->{'x'}}) {
    print 'x';
  }

  List::Util::first {print $_} @{$self->{'x'}};
  exit 0;
}

{
  my $ahash = undef;
  if (%$ahash) {
    print "yes\n";
  } else {
    print "no\n";
  }
  exit 0;
}

{
  print ref undef,"\n";

  print "argc=",scalar @ARGV,"\n";
  print "argv0=",$ARGV[0],"\n";
  print "argv1=",$ARGV[1],"\n";
  print "\$0=",$0,"\n";
  exit 0;
}

use Data::Dumper;
my %self = ();
my $self = \%self;
$self->{__PACKAGE__.'.y'} = 123;
print Dumper ($self);

my $sub = $self->{__PACKAGE__};
print Dumper ($sub);

{
  my @a = (undef);
  if ($a[0]->{'active'}) { print "hi\n";}
}
{
  my $a = undef;
  if ($a->{'active'}) { print "hi\n"; } else { print "bye\n";}
}

# use Glib;

# my $spec = Glib::ParamSpec->int ('name', 'nick', 'blurb', 99, 888, 150,
#                                  Glib::G_PARAM_READWRITE);
# print $spec->get_minimum;
# print $spec->get_maximum;
# exit 0;

# use Data::Dumper;
# use Set::IntSpan::Fast 1.10;
# {
#   use Set::Object::Weak;
#   my $set = Set::Object::Weak->new;

#   {
#     my $x = { 123 => 456 };
#     $set->insert ($x);
#     my @a = $set->members;
#     print Dumper (\@a);
#   }
  
#   my @a = $set->members;
#   print Dumper (\@a);
#   exit 0;
# }

# #my $x = undef;
# #bless $x,'Foo';

# if (0 eq undef) {
#   print "true\n";
# }

# {
#   my $ret = do 'undef.pl';
#   my $at = $@;
#   my $bang = $!;
#   print Dumper (\$at);
#   print Dumper (\$bang);
#   print Dumper (\$ret);
# }


# # eval
