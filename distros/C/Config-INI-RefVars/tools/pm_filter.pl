use strict;
use warnings;
use autodie;

use File::Find;
use File::Spec;
use File::Temp qw(tempfile);

our $VERSION = '0.24';

my %REPLACE = (
  AUTHOR => 'Abdul al Hazred',
);

main();

sub main {
  die("Too many arguments\n") if @ARGV > 2;

  if (@ARGV == 0) {
    my $text = read_handle(\*STDIN);
    my $version = extract_version($text)
      or die("input: No version found\n");
    print filter_text($text, $version, 'input');
    return;
  }

  my $input = shift(@ARGV);

  if (@ARGV) {
    my $output = shift(@ARGV);
    my $text = read_file($input);
    my $version = extract_version($text)
      or die("$input: No version found\n");
    write_file($output, filter_text($text, $version, $input));
    return;
  }

  if (-d $input) {
    filter_dir($input);
    return;
  }

  my $text = read_file($input);
  my $version = extract_version($text)
    or die("$input: No version found\n");
  write_file_atomic($input, filter_text($text, $version, $input));
}

sub filter_dir {
  my ($dir) = @_;

  my $lib_dir = File::Spec->catdir($dir, 'lib');
  return if !-d $lib_dir;

  my $main_pm = File::Spec->catfile(
    $lib_dir, qw(Config INI RefVars.pm)
  );

  my $main_text = read_file($main_pm);
  my $version = extract_version($main_text)
    or die("$main_pm: No version found\n");

  find(
    {
      no_chdir => 1,
      wanted   => sub {
        return unless -f $_;
        return unless /\.pm\z/;
        filter_file_inplace($_, $version);
      },
    },
    $lib_dir,
  );
}

sub filter_file_inplace {
  my ($file, $version) = @_;

  my $text = read_file($file);
  write_file_atomic($file, filter_text($text, $version, $file));
}

sub read_file {
  my ($file) = @_;

  open(my $fh, '<', $file);
  my $text = read_handle($fh);
  close($fh);

  return $text;
}

sub read_handle {
  my ($fh) = @_;

  local $/;
  return <$fh>;
}

sub filter_text {
  my ($text, $version, $name) = @_;

  $name = defined($name) ? $name : 'input';

  my %replace = (
    %REPLACE,
    VERSION => $version,
  );

  my $in_pod = 0;
  my @out;
  my $is_main_module =
    defined($name) && $name =~ m{(?:^|[\\/])Config[\\/]INI[\\/]RefVars\.pm\z};

  for my $line (split(/^/, $text)) {

    if (!$is_main_module) {
      $line =~ s/
                  ^(\s*our\s+\$VERSION\s*=\s*)
                  ['"]\#VERSION\#['"]
                  (\s*;\s*)$
                /$1'$version'$2/x;
    }

    $in_pod = 1 if $line =~ /^=pod\s*$/;

    if ($in_pod && $line =~ /^\S/) {
      $line =~ s/#([A-Z][A-Z0-9_]*)#/replace_token($1, \%replace)/ge;
    }

    push(@out, $line);
  }

  return join('', @out);
}

sub replace_token {
  my ($key, $replace) = @_;

  return exists($replace->{$key}) ? $replace->{$key} : "#$key#";
}

sub extract_version {
  my ($text) = @_;

  for my $line (split(/^/, $text)) {
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
      return $1;
    }
  }

  return;
}

sub write_file {
  my ($file, $text) = @_;

  open(my $fh, '>', $file);
  print {$fh} $text;
  close($fh);
}

sub write_file_atomic {
  my ($file, $text) = @_;

  my ($volume, $directories) = File::Spec->splitpath($file);
  my $dir = File::Spec->catpath($volume, $directories, '');

  my ($fh, $tmp) = tempfile('.pm_filter_XXXXXX', DIR => $dir, UNLINK => 0);
  print {$fh} $text;
  close($fh);

  rename($tmp, $file);
}


__END__

=head1 NAME

pm_filter.pl - Filter Perl modules before distribution

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  pm_filter.pl
  pm_filter.pl INFILE
  pm_filter.pl INFILE OUTFILE
  pm_filter.pl DIR

=head1 DESCRIPTION

This utility is intended to be called automatically via C<PM_FILTER>
or C<PREOP> during the build process.

It reads the version number from the main module
F<Config/INI/RefVars.pm>. This version is then used for all processed
modules.

The following substitutions are performed:

=over

=item *

In POD, the placeholders C<#AUTHOR#> and C<#VERSION#> are replaced,
except in verbatim paragraphs.

=item *

In all modules except the main module, a line of the form

  our $VERSION = '#VERSION#';

is replaced by the actual version number.

=back

If a directory is specified, all F<*.pm> files below its F<lib/>
directory are processed in place.

Without arguments, the script reads from standard input and writes to
standard output.

=head1 AUTHOR

Abdul al Hazred

=head1 COPYRIGHT AND LICENSE

Copyright (C) Abdul al Hazred.
