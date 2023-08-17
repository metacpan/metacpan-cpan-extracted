# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2023 Kevin Ryde

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

package App::Chart;
use 5.010;
use strict;
use warnings;
use Carp;
use Date::Calc;
use File::Spec;
use List::Util qw(min max);
use POSIX qw(floor ceil);
use Regexp::Common 'whitespace';
use Scalar::Util;
use Locale::TextDomain;
use Locale::TextDomain ('App-Chart');
use Glib;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 271;

use Locale::Messages 1.16; # version 1.16 for turn_utf_8_on()
BEGIN {
  Locale::Messages::bind_textdomain_codeset ('App-Chart','UTF-8');
  Locale::Messages::bind_textdomain_filter ('App-Chart',
                                            \&Locale::Messages::turn_utf_8_on);
}
# sub chart_gettext_filter {
#   my ($str) = @_;
#   Locale::Messages::turn_utf_8_on ($str);
#   $str =~ s/^CONTEXT\(.*?\): *//;
#   return $str;
# }

# Return the user's ~/Chart directory, as an absolute path in filesystem
# charset encoding.
# Note not using Glib::get_home_dir() here, since it wrongly prefers 
# /etc/passwd file over $HOME.
use constant::defer chart_directory => sub {
  if (defined $ENV{'CHART_DIRECTORY'}) {
    return $ENV{'CHART_DIRECTORY'}
  } else {
    require File::HomeDir;
    my $home = File::HomeDir->my_home
      // die "No home directory can be found by File::HomeDir\n";
    return File::Spec->catdir($home, 'Chart');
  }
};

use constant::defer chart_dirbroadcast => sub {
  require App::Chart::Glib::Ex::DirBroadcast;
  return App::Chart::Glib::Ex::DirBroadcast->new
    (File::Spec->catdir(chart_directory(), 'broadcast'));
};

# force LC_NUMERIC to the locale, whereas perl normally runs with "C"
use constant::defer number_formatter => sub {
  require Number::Format;
  my $oldlocale = POSIX::setlocale(POSIX::LC_NUMERIC());
  POSIX::setlocale (POSIX::LC_NUMERIC(), "");
  my $nf = Number::Format->new;
  POSIX::setlocale (POSIX::LC_NUMERIC(), $oldlocale);
  return $nf;
};

use constant { UP_COLOUR   => 'light green',
                 DOWN_COLOUR => 'pink',
                 BAND_COLOUR => 'blue',
                 GREY_COLOUR => 'grey' };

#------------------------------------------------------------------------------

our %option
  = (verbose => 0,
     d_fmt   => do {
       # langinfo D_FMT if available, otherwise fallback to a neutral YYYY-MM-DD
       eval {
         require I18N::Langinfo;
         require I18N::Langinfo::Wide;
         I18N::Langinfo::Wide::langinfo(I18N::Langinfo::D_FMT())
         }
         || '%Y-%m-%d'
       },
     http_get_cost => 3000,
    );
$option{'wd_fmt'} = __x('%a {d_fmt}', d_fmt => $option{'d_fmt'});



#------------------------------------------------------------------------------

sub symbol_sans_suffix {
  my ($symbol) = @_;
  return ($symbol =~ /(.*)\./ ? $1 : $symbol);
}

sub symbol_suffix {
  my ($symbol) = @_;
  if ($symbol =~ /([.=][^.=]+)$/) {
    return $1;
  } else {
    return '';
  }
}

my $symbol_re = qr{
                   ((\ (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\ |
                       \^?[^^]([FGHJKMNQUVXZ]))  # $4 M code
                     ([0-9]+)                    # $5 year
                   | ([0-9]+))?                  # $6 number like LME
                   (\.[^.]+)?$                   # $7 suffix
                }ix;

# return commodity part of SYMBOL, or whole symbol (sans suffix) if no
# month/year
# eg. "GC" for "GCH05.CMX"
#     "TIN 3" for "TIN 3.LME"  -- ?????
sub symbol_commodity {
  my ($symbol) = @_;
  $symbol =~ $symbol_re or die 'Oops, symbol_re didn\'t match';
  my $end = ($+[6]        # "TIN 3" num right up to suffix
             // $-[4]     # "X08" M-code stop there
             // $-[0]);   # " JAN 06" named stop there, or whole lot
  return substr ($symbol, 0, $end);
}
sub symbol_is_front {
  my ($symbol) = @_;
  return symbol_commodity($symbol) eq symbol_sans_suffix($symbol);
}


#------------------------------------------------------------------------------

sub symbol_cmp {
  my ($s1, $s2) = @_;
  # transform "." so that it comes before a space, so that "ZINC.LME" sorts
  # before "ZINC 3.LME", etc
  $s1 =~ tr/^./\000\001/;
  $s2 =~ tr/^./\000\001/;
  return (lc($s1) cmp lc($s2)) || ($s1 cmp $s2);
}


#------------------------------------------------------------------------------

my %symbol_setups_done;
sub symbol_setups {
  my ($symbol) = @_;
  my $suffix = symbol_suffix ($symbol);
  if ($suffix eq '') {
    if ($symbol_setups_done{$symbol}) { return; }
    $symbol_setups_done{$symbol} = 1;
    ### symbol_setups() NoSuffix\n: $symbol
    require App::Chart::Suffix::NoSuffix;
    App::Chart::Suffix::NoSuffix::symbol_setups ($symbol);
    return;
  }
  if ($symbol_setups_done{$suffix}) { return; }
  $symbol_setups_done{$suffix} = 1;

  ### symbol_setups() suffix: $suffix
  if ($symbol =~ /[.=]..?$/) {
    require App::Chart::Yahoo;
  }

  # '.AX' or '=X' becomes 'AX' or 'X'
  $suffix =~ s/[.=]//;

  # load App::Chart::Suffix::XX and also any App::Chart::Suffix::XX::Foo, the
  # latter being meant as pluggable add-ons
  require Module::Util;
  require Module::Load;
  require Module::Find;

  my $top_module = "App::Chart::Suffix::$suffix";
  if (Module::Util::find_installed($top_module)) {
    ### load top: $top_module
    Module::Load::load ($top_module);
  }
  foreach my $sub_module (Module::Find::findsubmod($top_module)) {
    ### load sub_module: $sub_module
    Module::Load::load ($sub_module);
  }
}

#------------------------------------------------------------------------------

# =item C<< App::Chart::symbol_source_help ($symbol) >>
# 
# Return the name of the node (or anchor) in the manual for help on the data
# source for C<$symbol>.
# 
# =item App::Chart::setup_source_help ($pred, $node)
# 
# =cut

my @source_help_list = ();

sub symbol_source_help {
  my ($symbol) = @_;
  symbol_setups ($symbol);
  foreach my $elem (@source_help_list) {
    if ($elem->[0]->match ($symbol)) {
      return $elem->[1];
    }
  }
  return undef;
}
sub setup_source_help {
  my ($pred, $node) = @_;
  require App::Chart::Sympred;
  App::Chart::Sympred::validate ($pred);
  # newer get higher priority
  unshift @source_help_list, [ $pred, $node ];
}


#------------------------------------------------------------------------------

sub hms_to_seconds {
  my ($hour, $minute, $seconds) = @_;
  return $hour * 60*60 + $minute * 60 + ($seconds || 0);
}

#------------------------------------------------------------------------------

sub seconds_to_hms {
  my ($seconds) = @_;
  return (floor ($seconds/3600) % 60,
          floor ($seconds/60) % 60,
          $seconds % 60);
}

#------------------------------------------------------------------------------

sub ymd_to_iso {
  my ($year, $month, $day) = @_;
  return sprintf ('%04d-%02d-%02d', $year, $month, $day);
}

sub iso_to_ymd {
  my ($iso) = @_;
  return split /-/, $iso;
}

sub adate_to_ymd {
  my ($adate) = @_;
  return Date::Calc::Add_Delta_Days(1970,1,5, $adate);
}
my $adate_days_base = Date::Calc::Date_to_Days (1970, 1, 5);
sub ymd_to_adate {
  my ($year, $month, $day) = @_;
  return Date::Calc::Date_to_Days($year, $month, $day) - $adate_days_base;
}
sub adate_to_iso {
  my ($tdate) = @_;
  return App::Chart::ymd_to_iso (App::Chart::adate_to_ymd ($tdate));
}

sub tdate_to_ymd {
  my ($tdate) = @_;
  return adate_to_ymd (tdate_to_adate ($tdate));
}
sub tdate_to_iso {
  my ($tdate) = @_;
  return adate_to_iso (tdate_to_adate ($tdate));
}
sub tdate_to_adate {
  my ($tdate) = @_;
  return $tdate + floor ($tdate/5)*2;
}
sub adate_to_tdate_floor {
  my ($adate) = @_;
  return floor ($adate / 7) * 5 + min ($adate % 7, 4);
}
sub adate_to_tdate_ceil {
  my ($adate) = @_;
  return floor ($adate / 7) * 5 + min ($adate % 7, 5);
}
sub ymd_to_tdate_floor {
  my ($year, $month, $day) = @_;
  return adate_to_tdate_floor (ymd_to_adate ($year, $month, $day));
}
sub ymd_to_tdate_ceil {
  my ($year, $month, $day) = @_;
  return adate_to_tdate_ceil (ymd_to_adate ($year, $month, $day));
}


#------------------------------------------------------------------------------

sub collapse_whitespace {
  my ($str) = @_;
  $str =~ s/\x{A0}+/ /g;       # latin1/unicode non-breaking space
  $str =~ s/$RE{ws}{crop}//g;  # leading and trailing whitespace
  $str =~ s/\s+/ /g;           # middle whitespace
  return $str;
}

#------------------------------------------------------------------------------

sub decimal_sub {
  my ($x, $y) = @_;
  # would prefer an actual decimal-arithmetic subtract here
  my $decimals = max (count_decimals($x), count_decimals($y));
  return sprintf ('%.*f', $decimals, $x - $y);
}

#------------------------------------------------------------------------------

sub count_decimals {
  my ($str) = @_;
  my $pos = index ($str, '.');
  if ($pos >= 0) {
    return length($str) - $pos - 1;
  } else {
    return 0;
  }
}

#------------------------------------------------------------------------------

# Return min or max of the arguments, ignoring any undefs.
# If no args (no undefs that is) then return undef.
# List::Util min() and max() return undef for no args, but they want all args
# to be numeric.
#
sub min_maybe {
  return min (grep {defined} @_);
}
sub max_maybe {
  return max (grep {defined} @_);
}

#------------------------------------------------------------------------------

# App::Chart::datafilename ($filename)
# App::Chart::datafilename ($dir,...,$dir, $filename)
#
# Return an absolute path like /usr/share/perl5/App/Chart/$filename,
# wherever App/Chart/$filename is found in @INC.  $dir arguments specify a
# subdirectory like App/Chart/$dir1/$dir2/$filename.  All args and the
# return are in filesystem charset bytes.
#
# Module::Find and Module::Util have similar @INC searches, but only for .pm
# files it seems.
#
sub datafilename {
  foreach my $inc (@INC) {
    my $filename = File::Spec->catfile ($inc, 'App', 'Chart', @_);
    if (-e $filename) { return $filename; }
  }
  require File::Basename;
  return File::Spec->catfile (File::Basename::dirname($INC{'App/Chart.pm'}),
                              'Chart', @_);
}

# return true if range ($alo,$ahi) overlaps range ($blo,$bhi)
# each endpoint is taken as inclusive, so say (1,4) and (4,7) do overlap
#
sub overlap_inclusive_p {
  my ($alo, $ahi, $blo, $bhi) = @_;
  return ! ($ahi < $blo || $alo > $bhi);
}

1;
__END__

=head1 NAME

App::Chart -- various shared Chart things

=head1 SYMBOL FUNCTIONS

=over 4

=cut

=item C<< %App::Chart::option >>

Various program options.

=over 4

=item C<verbose> (default false)

Print more things (mainly during downloads).  This is the C<--verbose>
command line option.

=item C<d_fmt> (default from C<langinfo()>)

C<strftime> format string for a date.  Non-ASCII can be included as Perl
wide-chars.

The default is from C<langinfo(D_FMT)> if the L<I18N::Langinfo> and
L<I18N::Langinfo::Wide> modules are available.  Otherwise the default is
C<%Y-%m-%d> which gives an ISO style YYYY-MM-DD.

=item C<wd_fmt> (default C<%a> and C<d_fmt>)

C<strftime> format string for a weekday name and date.

=item C<http_get_cost> (default 3000)

Byte cost reckoned for each separate HTTP request.  This is used when
choosing between an individual download per symbol or a whole-day download
of everything at the exchange.

If your connection is badly lagged you could increase this to prefer the
single big file.  If you want to minimize downloaded bytes then reduce this
to roughly HTTP per-request overhead (packet and headers each way), which
might be a few hundred bytes.

=back

=item C<< App::Chart::symbol_sans_suffix ($symbol) >>

Return C<$symbol> without its suffix.  Eg.

    App::Chart::symbol_sans_suffix ('BHP.AX')   # gives 'BHP'
    App::Chart::symbol_sans_suffix ('GM')       # gives 'GM'

=item App::Chart::symbol_suffix ($symbol)

Return the suffix part of C<$symbol>, or an empty string if no suffix.  Eg.

    App::Chart::symbol_suffix ('BHP.AX')   # gives '.AX'
    App::Chart::symbol_suffix ('GM')       # gives ''

=item C<< $cmp = App::Chart::symbol_cmp ($s1, $s2) >>

Return -1, 0 or 1 according to C<$s1> less than, equal to, or greater than
C<$s2>.

Symbols are compared alphabetically, except "^" index symbols come before
ordinary symbols.

=back

=head1 DATE/TIME FUNCTIONS

=over 4

=item App::Chart::hms_to_seconds ($hour, $minute, [$second])

Return a count of seconds since midnight for the given C<$hour>, C<$minute>
and C<$seconds>.  C<$seconds> is optional and defaults to 0.  C<$hour> is in
24-hour format, so for instance 16 for 4pm.

=item App::Chart::seconds_to_hms ($seconds)

Return three values C<($hour, $minute, $seconds)> split from C<$seconds>
which is a count of seconds since midnight.  C<$hour> is in 24-hour format,
so for instance 16 for 4pm.

=cut

# =item C<< App::Chart::ymd_to_iso ($year, $month, $day) >>
# 
# ...

=back

=head1 MISC FUNCTIONS

=over 4

=item App::Chart::collapse_whitespace ($str)

Return C<$str> with leading and trailing whitespace stripped, and any runs
of whitespace within the string collapsed down to a single space character
each.

=item App::Chart::decimal_sub ($x, $y)

Calculate the difference C<$x - $y> of two decimal number strings C<$x> and
C<$y> and return such a string.  For example,

    App::Chart::decimal_sub ('2.55', '1.15')  # gives '1.40'
    App::Chart::decimal_sub ('60.5', '1.05')  # gives '59.45'

The number of decimal places used and returned is whichever of the two
values has the most places.

=item C<< App::Chart::count_decimals ($str) >>

Return the number of decimal places in the number string C<$str>, ie. how
many digits after the decimal point, or 0 if no decimal point.  Eg.

    App::Chart::count_decimals ('123')    # is 0
    App::Chart::count_decimals ('123.')   # is 0
    App::Chart::count_decimals ('123.5')  # is 1
    App::Chart::count_decimals ('2.500')  # is 3

=item App::Chart::max_maybe ($num, $num, ...)

=item App::Chart::min_maybe ($num, $num, ...)

Return the maximum or minimum (respectively) among the given numbers.
C<undef>s in the arguments are ignored and if there's no arguments, or only
C<undef> arguments, the return is C<undef>.

=back

=head1 SEE ALSO

L<chart>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2023 Kevin Ryde

Chart is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Chart; see the file F<COPYING>.  Failing that, see
L<http://www.gnu.org/licenses/>.

=cut
