use strict;
use warnings;

my $Line;
my $Version;
my $Author = "Abdul al Hazred";

while (defined($Line = <>)) {
  print($Line);
  if ($Line =~ /^\s*
                (?:use\s+version(?:\s+\d+\.\d+)?\s*;\s*)?
                our\s+\$VERSION\s*=\s*
                (?:version->declare\()?
                ['"]
                (v?\d+(?:\.\d+)+)
                ['"]
                \)?
                \s*;\s*$
               /x) {
    $Version = $1;
    last;
  }
}
die("No version found") if !defined($Version);


#
# We assume that there is a '__END__' line followed by a '=pod'.
#
while (defined($Line = <>)) {
  print($Line);
  last if $Line =~ /^\s*__END__\s*$/;
}
die("No __END__ found") if !defined($Line);
while (defined($Line = <>)) {
    print($Line);
  last if $Line =~ /^=pod\s*$/;
}
die("No =pod found") if !defined($Line);

#
# Now we are in the POD section and do our replacements!
#
while (defined($Line = <>)) {
  if ($Line =~ /^\S/) {
    $Line =~ s/#AUTHOR#/$Author/g;
    $Line =~ s/#VERSION#/$Version/g;
  }
  print($Line);
}



__END__


=pod


=head1 NAME

pm_simple_filter.pl - Filter for Perl module


=head1 SYNOPSIS

  pm_simple_filter.pl < LIB_PM > BLIB_PM

=head1 DESCRIPTION

To be autmatically called via C<PM_FILTER> during the uild process.

Reads from C<STDIN> and writes to C<STDOUT>. Input must be code of a Perl
module. It reads the VERSION (must be present!) and in the POD section, it
replaces C<#VERSION#> with that version and C<#AUTHOR#> with the name of the
author (hard coded in this script). It does not replace in verbatim lines.

The script assumes that the POD is located at the bottom of the file, after an
C<__END__> followed by optional empty lines followed by a C<=pod>.

=cut



