#! /usr/bin/perl
#---------------------------------------------------------------------
# Convert a codepage table from http://www.tachyonsoft.com/cpindex.htm
# to a Convert::IBM390 codepage module
#---------------------------------------------------------------------

use strict;

use HTML::TreeBuilder;

my $version = '0.23';

my $filename = $ARGV[0];

sub doCP
{
  my $filename = $_[0];
  print "$filename...\n";

  my $tree = HTML::TreeBuilder->new_from_file($filename);

  my $title = $tree->find('title');

  $title = $title->as_trimmed_text;

  my $short_title = $title;
  $short_title =~ s/^Code Page \w+:\s*//;

  my $tbl = $tree->find('table') or die;

  my @chars = $tbl->look_down(_tag => 'a', href => qr/^uc\d/);

  die sprintf("Found %d chars", scalar @chars) unless @chars == 256;

  my @codes = map { hex $_->as_trimmed_text } @chars;

  my $e2a_table = '';
  my $i = 0;

  foreach my $code (@codes) {
    die sprintf("%02X -> %02X", $i, $code) if $code > 0xFF;

    $e2a_table .= sprintf("%02X%s", $code, (++$i % 16 ? ' ' : "\n"));
  }

  chomp $e2a_table;

  my $chart = $e2a_table;

  $i = 0;

  $chart =~ s/^/sprintf('  %X- ', $i++)/gem;
  $chart = (' ' x ((52 - length($title)) / 2) . $title .
            "\n\n     -0 -1 -2 -3 -4 -5 -6 -7 -8 -9 -A -B -C -D -E -F\n$chart");

  $filename =~ /^(cp[0-9A-F]{5})\.htm/ or die;
  my $module = uc $1;

  open(OUT, '>', "$module.pm") or die;

  print OUT <<"END MODULE";
package Convert::IBM390::$module;

use Convert::IBM390 'set_translation';

use vars qw(\$VERSION);

\$VERSION = '$version';

sub import {
  set_translation(undef, <<'END EBCDIC');
$e2a_table
END EBCDIC
} # end import

\__END__

=head1 NAME

Convert::IBM390::$module - $short_title

=head1 SYNOPSIS

$chart
END MODULE
} # end doCP

eval "require Wild;";           # Wildcard expansion on Win32
foreach my $page (@ARGV) { doCP($page) }
