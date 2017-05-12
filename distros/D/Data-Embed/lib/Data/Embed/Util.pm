package Data::Embed::Util;

use strict;
use warnings;
use English qw< -no_match_vars >;
use Log::Log4perl::Tiny qw< :easy :dead_if_first >;

our $VERSION = '0.32'; # make indexer happy

use Exporter qw< import >;
our @EXPORT_OK = qw< STARTER TERMINATOR escape unescape transfer >;
our @EXPORT      = ();    # export nothing by default
our %EXPORT_TAGS = (
   all       => \@EXPORT_OK,
   escaping  => [qw< escape unescape >],
   constants => [qw< STARTER TERMINATOR >],
);

use constant STARTER    => "Data::Embed/index/begin\n";
use constant TERMINATOR => "Data::Embed/index/end\n";

sub escape {
   my $text = shift;
   $text =~ s{([^\w.-])}{'%' . sprintf('%02x', ord $1)}egmxs;
   return $text;
}

sub unescape {
   my $text = shift;
   $text =~ s{%(..)}{chr(hex($1))}egmxs;
   return $text;
}

sub transfer {
   my ($infh, $outfh) = @_;
   while ('necessary') {
      my $buffer;
      my $n = sysread $infh, $buffer, 0, 4096;
      LOGCROAK "sysread(): $OS_ERROR" unless defined $n;
      last unless $n;
      print {$outfh} $buffer;
   } ## end while ('necessary')
   return;
} ## end sub transfer

1;
