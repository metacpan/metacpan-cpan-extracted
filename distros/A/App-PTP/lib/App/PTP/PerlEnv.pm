# This package is the one that provides the symbol accessible to the user
# supplied Perl code. The global variables are manipulated and set by the
# App::PTP::Commands package.
 
package App::PTP::PerlEnv;

use strict;
use warnings;

use Exporter 'import';

my @all_symbols = qw($f $F $n $N $m $. @m $I ss pf spf $PerlEnv_LOADED);
our @EXPORT = ();
# This array is read directly to share all these symbols with the Safe.
our @EXPORT_OK = @all_symbols;
our %EXPORT_TAGS = (all => \@all_symbols);
# Marker that can be checked to know if the module is loaded.
our $PerlEnv_LOADED = 1;

our $f;  # This will be the name of the processed file, shared with the safe.
our $F;  # The absolute path to the input file.
our $n;  # This will be the current line number, shared with the safe.
our $N;  # This will be the total number of lines of the input.
our $m;  # The marker of the current line.
our $.;  # The standard name for the $n variable.
our @m;  # The read-only version of @markers (with read relative).
our $I;  # The index of the file being processed.

sub ss ($;$$) {
  my ($start, $len, $str) = @_;
  $str = $_ unless defined $str;
  $len = length($str) unless $len;
  # print "start=${start}; len=${len}; str=${str}\n";
  # substr returns undef for sub-strings outside the original string. This would
  # remove the input line, so instead we're keeping an empty string.
  substr($str, $start, $len) // '';
}

sub pf($@) {
  my ($format, @args) = @_;
  # print "format=${format} args=(".join(', ', @args).")\n";
  $_ = sprintf $format, @args;
}

sub spf($@) {
  my ($format, @args) = @_;
  # print "format=${format} args=(".join(', ', @args).")\n";
  sprintf $format, @args;
}

1;
