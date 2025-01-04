use strict;
use warnings;
use autodie;

use File::Find;


my $AUTHOR = "Abdul al Hazred";

main();

sub main {
  my $input;
  my $outfile;
  my $result;
  if (@ARGV) {
    die("Too many arguments") if @ARGV > 2;
    $input = shift(@ARGV);
    if (@ARGV == 1) {
      write_result(filter_file($input), shift(@ARGV));
    } else {
      if (-d $input) {
        find({no_chdir => 1,
              #wanted   => sub { if (/\.pm$/ && -f $_) { push(@files, $_) } }
              wanted   => sub { if (/\.pm$/ && -f $_) { write_result(filter_file($_), $_) } }
             },
             $input);
      } else {
        write_result(filter_file($input), $input);
      }
    }
  } else {
    write_result(filter_hndl(\*STDIN));
  }
}


sub write_result {
  my ($result, $outfile) = @_;
  if (defined($outfile)) {
    open(my $out_hndl, '>', $outfile);
    print $out_hndl (@$result);
    close($out_hndl);
  } else {
    print(@$result);
  }
}


sub filter_file {
  my $file = shift;
  open(my $hndl, '<', $file);
  my $result = filter_hndl($hndl);
  close($hndl);
  return $result;
}


sub filter_hndl {
  my $hndl = shift;
  my ($line, $version);
  my @filtered;
  while (defined($line = <$hndl>)) {
    push(@filtered, $line);
    if ($line =~ /^\s*
                  (?:use\s+version(?:\s+\d+\.\d+)?\s*;\s*)?
                  our\s+\$VERSION\s*=\s*
                  (?:version->declare\()?
                  ['"]
                  (v?\d+(?:\.\d+)+)
                  ['"]
                  \)?
                  \s*;\s*$
                 /x) {
      $version = $1;
      last;
    }
  }
  die("No version found") if !defined($version);
  #
  # We assume that there is a '__END__' line followed by a '=pod'.
  #
  while (defined($line = <$hndl>)) {
    push(@filtered, $line);
    last if $line =~ /^\s*__END__\s*$/;
  }
  die("No __END__ found") if !defined($line);
  while (defined($line = <$hndl>)) {
    push(@filtered, $line);;
    last if $line =~ /^=pod\s*$/;
  }
  die("No =pod found") if !defined($line);

  #
  # Now we are in the POD section and do our replacements!
  #
  while (defined($line = <$hndl>)) {
    if ($line =~ /^\S/) {
      $line =~ s/#AUTHOR#/$AUTHOR/g;
      $line =~ s/#VERSION#/$version/g;
    }
    push(@filtered, $line);
  }
  return \@filtered;
}

__END__


=pod


=head1 NAME

pm_simple_filter.pl - Filter for Perl module


=head1 SYNOPSIS

  pm_simple_filter.pl [[INFILE] OUTFILE]
  pm_simple_filter.pl DIR

=head1 DESCRIPTION

To be autmatically called via C<PM_FILTER> during the build process.

Input must be code of a Perl module. It reads the VERSION (must be present!)
and in the POD section, it replaces C<#VERSION#> with that version and
C<#AUTHOR#> with the name of the author (hard coded in this script). It does
not replace in verbatim lines.

Alternatively, the script can also be called with a single directory name
C<DIR>. In this case, the script searches the C<DIR> tree and replaces all
F<*.pm> files that it finds.

The script reads from C<INFILE> and writes to C<OUTFILE>. If only C<INFILE> is
specified, this file is changed. Without arguments, the script reads from
C<STDIN> and writed to C<STDOUT>.

The script assumes that the POD is located at the bottom of the file, after an
C<__END__> followed by optional empty lines followed by a C<=pod>.

=cut



