package Test2AndUtils;
use v5.26;
use warnings;
use Test2::V0 '!subtest';
use Test2::Tools::Subtest 'subtest_streamed';
use Test2::Tools::Compare 0.000156;
use Test2::Tools::Compare 'number_gt';
use experimental qw( signatures );
use parent 'Test2::V0';
use File::Temp;
use IO::Handle;
eval q{use Log::Any::Adapter 'TAP'; 1}
or eval q{use Log::Any::Adapter 'Stderr', log_level => 'info'; 1}
or note "Failed to setup Log::Any::Adapter: $@";

our @EXPORT= (
   @Test2::V0::EXPORT,
   qw( number_gt explain unindent mkfile slurp escape_nonprintable hexdump )
);

# Test2 runs async by default, which messes up the relation between warnings and the test
# that generated them.  Streamed generates output sequentially.
*subtest= \&subtest_streamed;

# Use Data::Printer if available, but fall back to Data::Dumper
eval q{
   use Data::Printer;
   sub explain { Data::Printer::np(@_) }
   1
} or eval q{
   use Data::Dumper;
   sub explain { Data::Dumper->new(\@_)->Terse(1)->Indent(1)->Sortkeys(1)->Dump }
   1
} or die $@;

# Perl didn't get <<~'x' until 5.28, so this lets you write an indented here-block and
# then remove the common indent from all lines.
sub unindent {
   my ($indent)= ($_[0] =~ /^(\s+)/);
   (my $x= $_[0]) =~ s/^$indent//mg;
   $x;
}

# Convert data strings to and from C / Perl backslash notation.
# Not exhaustive, just hit the most common cases and hex-escape the rest.

my %escape_to_char = ( "\\" => "\\", r => "\r", n => "\n", t => "\t" );
my %char_to_escape = reverse %escape_to_char;

sub escape_nonprintable($str) {
   $str =~ s/([^\x21-\x7E])/ defined $char_to_escape{$1}? "\\".$char_to_escape{$1} : sprintf("\\x%02X", ord $1) /ge;
   return $str;
}

sub unescape_nonprintable($str) {
   $str =~ s/\\(x([0-9A-F]{2})|.)/ defined $2? chr hex $2 : $escape_to_char{$1} /ge;
   return $str;
}

sub mkfile($name, $data, $mode=undef) {
   open my $fh, '>:raw', $name or die "open(>$name): $!";
   $fh->print($data) or die "write($name): $!";
   $fh->close or die "close($name): $!";
   chmod $mode, $name or die "chmod($name, $mode): $!"
      if defined $mode;
   1;
}

sub slurp($name) {
   open my $fh, '<:raw', $name or die "open(<$name): $!";
   local $/;
   my $ret= scalar <$fh>;
   close $fh or die "close($name): $!";
   $ret;
}

# Equivalent of unix command 'hexdump -C'
# https://www.perlmonks.org/?node_id=11166492
sub hexdump($data) {
   $data =~ s/\G(.{1,16})(\1+)?/
      sprintf "%08x  %-50s|%s|\n%s", $-[0], "@{[unpack q{(H2)8a0(H2)8},$1]}",
         $1 =~ y{ -~}{.}cr, "*\n"x!!$+[2]
   /segr . sprintf "%08x", $+[0]
}

1;
