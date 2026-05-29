# Copyright (C) 2016--2026 Karl Wette
#
# This file is part of App::PDFLibrarian.
#
# App::PDFLibrarian is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# App::PDFLibrarian is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with App::PDFLibrarian. If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

package App::PDFLibrarian::Util;
$App::PDFLibrarian::Util::VERSION = '6.0.2';
use parent 'Exporter';

use Carp;
use Cwd;
use File::Find;
use File::MimeInfo::Magic;
use File::Spec;
use FindBin qw($Script);
use PDF::API2;
use Parallel::Iterator;
use System::Info qw(sysinfo_hash);
use Text::Wrap;

use App::PDFLibrarian qw($pdflibrarydir);

our @EXPORT_OK = qw(unique_list is_in_dir get_file_list find_pdf_files keyword_display_str parallel_loop remove_tex_markup remove_tex_markup_undef remove_short_words run_async kill_async);

1;

sub unique_list {

  # return a list containing only unique elements
  my %seen;
  grep !$seen{$_}++, @_;

}

sub is_in_dir {
  my ($dir, $path) = @_;

  # return true if '$path' is in '$dir', false otherwise
  sub spliteverything {
    my $p = $_[0];
    $p = File::Spec->rel2abs($p);
    $p = Cwd::abs_path($p);
    my ($v, $d, $f) = File::Spec->splitpath($p);
    my @d = File::Spec->splitdir(File::Spec->catdir($d));
    ($v, @d, $f)
  }
  my @dir = spliteverything($dir);
  my @path = spliteverything($path);
  return 0 if @dir > @path;
  while (@dir) {
    return 0 if shift(@dir) ne shift(@path);
  }

  return 1;
}

sub get_file_list {

  # get list of files either from command line or from standard input
  if (@ARGV > 0) {
    return @ARGV;
  } else {
    chomp(my @stdin = <STDIN>);
    return @stdin;
  }

}

sub find_pdf_files {

  # return unique found PDF files
  my %pdffileorder;
  my $order = 0;
  my $wanted = sub {
    if (-l $_) {
      $_ = readlink($_) or croak "$Script: could not resolve '$_': %!";
    }
    return unless -f && mimetype($_) eq 'application/pdf';
    $pdffileorder{File::Spec->rel2abs($_)} = ++$order;
  };

  # find PDF files in the given list of search paths
  foreach (@_) {
    if (-d $_) {
      find({wanted => \&$wanted, no_chdir => 1}, $_);
    } elsif (-r $_) {
      &$wanted($_);
    } elsif (!File::Spec->file_name_is_absolute($_) && -d File::Spec->catdir($pdflibrarydir, $_)) {
      find({wanted => \&$wanted, no_chdir => 1}, File::Spec->catdir($pdflibrarydir, $_));
    } elsif (!File::Spec->file_name_is_absolute($_) && -r File::Spec->catfile($pdflibrarydir, $_)) {
      &$wanted(File::Spec->catfile($pdflibrarydir, $_));
    } else {
      croak "$Script: '$_' is neither a file nor a directory, either by itself or within '$pdflibrarydir'";
    }
  }

  return sort { $pdffileorder{$a} <=> $pdffileorder{$b} } keys %pdffileorder;
}

sub keyword_display_str {

  # build list of keyword directories in PDF library
  my $pdfkeyworddir = File::Spec->catdir($pdflibrarydir, 'Keywords');
  return "" unless -d $pdfkeyworddir;
  my %keywords;
  my $wanted = sub {

    # only act on files, to get full keyword specification
    return unless -f $_;

    # get path relative to base keywork directory
    my @kw = File::Spec->splitdir(File::Spec->abs2rel($_, $pdfkeyworddir));

    # remove filename
    pop @kw;

    # remove any "by author/title/year" directories
    pop @kw if grep { $kw[-1] =~ $_ } qw(Authors Titles Years);

    # format keywords
    foreach (@kw) {
      s/_/ /g;
    }

    # join all keywords apart from last one
    my $lastkw = pop @kw;
    my $kws = join(': ', @kw);

    # add to keyword hash
    if ($kws eq "") {
      $keywords{$lastkw}{""} = 1;
    } else {
      $keywords{$kws}{$lastkw} = 1;
    }

  };
  find({wanted => \&$wanted, no_chdir => 1}, $pdfkeyworddir);
  return "" unless scalar(%keywords) > 0;

  # format keyword display string
  my $str = "%% Currently defined keywords:\n";
  foreach my $kws (sort { $a cmp $b } keys(%keywords)) {
    my @lastkws = keys(%{$keywords{$kws}});
    @lastkws = grep { $_ ne "" } @lastkws;
    @lastkws = sort { $a cmp $b } @lastkws;
    my $lastkws = join(', ', @lastkws);
    if ($lastkws eq "") {
      $str .= "%%   $kws\n";
    } else {
      $str .= "%%   $kws:\n";
      my $prefix = "%%     ";
      $str .= wrap($prefix, $prefix, $lastkws) . "\n";
    }
  }

  return $str;
}

sub parallel_loop {
  my ($progfmt, $inarray, $body) = @_;
  die unless ref($inarray) eq 'ARRAY';
  die unless ref($body) eq 'CODE';

  # return if '@$inarray' is empty
  return () unless @$inarray > 0;

  # get number of CPUs
  my $sysinfo = sysinfo_hash();
  my $ncpus = $sysinfo->{"cpu_cores"};

  # run code '$body' over all elements of '@$inarray', return the results
  # in '@outarray', and print occasional progress messages using '$progfmt'
  my $total = scalar(@$inarray);
  my $worker = sub {
    my ($id, $in) = @_;
    if ($id % (3 * $ncpus) == 0) {
      printf STDERR "$Script: $progfmt\r", $id, $total;
      flush STDERR;
    }
    my $out = &$body($in);
    return $out;
  };
  my @outarray = Parallel::Iterator::iterate_as_array( { workers => $ncpus, batch => 1 }, \&$worker, $inarray );
  @outarray = grep { defined($_) } @outarray;
  printf STDERR "$Script: $progfmt\n", scalar(@outarray), $total;
  flush STDERR;

  return @outarray;
}

sub remove_tex_markup {
  my (@words) = @_;

  # save some TeX commands
  my %saveTeX = (
                 Gamma      => "Gamma",      Delta  => "Delta", Theta   => "Theta",   Lambda  => "Lambda",
                 Xi         => "Xi",         Pi     => "Pi",    Sigma   => "Sigma",   Upsilon => "Upsilon",
                 Phi        => "Phi",        Psi    => "Psi",   Omega   => "Omega",   alpha   => "alpha",
                 beta       => "beta",       gamma  => "gamma", delta   => "delta",   epsilon => "epsilon",
                 varepsilon => "varepsilon", zeta   => "zeta",  eta     => "eta",     theta   => "theta",
                 vartheta   => "vartheta",   iota   => "iota",  kappa   => "kappa",   lambda  => "lambda",
                 mu         => "mu",         nu     => "nu",    xi      => "xi",      pi      => "pi",
                 varpi      => "varpi",      rho    => "rho",   varrho  => "varrho",  sigma   => "sigma",
                 varsigma   => "varsigma",   tau    => "tau",   upsilon => "upsilon", phi     => "phi",
                 varphi     => "varphi",     chi    => "chi",   psi     => "psi",     omega   => "omega",
                 lt         => "<=",         gt     => ">=",    ll      => "<<",      gg      => ">>",
                 sim        => "~",          approx => "~=",
                );

  # remove TeX markup
  foreach (@words) {
    if (!defined($_)) {
      $_ = "";
    } else {
      s/~/ /g;
      foreach my $t (keys %saveTeX) {
        s/\\$t/$saveTeX{$t}/g;
      }
      s/\\_/_/g;
      s/{\s*\\(\w)\s*}/$1/g;
      s/\\(\w)\s+/$1/g;
      s/\\\w+//g;
      s/\\.//g;
      s/[{}]//g;
      s/\$//g;
    }
  }

  return wantarray ? @words : "@words";
}

sub remove_tex_markup_undef {
  my $words = remove_tex_markup(@_);

  # return undef if $words is empty, for use with // operator
  return $words ne "" ? $words : undef;

}

sub remove_short_words {
  my (@words) = @_;

  # remove short words
  my @short_words =
    qw(
        a
        an   as   at   by   if   in   is   of   on   or   so   to   up
        and  are  but  for  its  nor  now  off  per  the  via
        amid down from into like near once onto over past than than that upon when with
     );
  @words = grep { my $word = $_; ! scalar grep { $word =~ /^$_$/i } @short_words } @words;

  return wantarray ? @words : "@words";
}

sub run_async {

  # execute command in separate process group
  my $pid = fork();
  croak "$Script: could not fork: $!" unless defined($pid);
  if ($pid == 0) {
    setpgrp;
    open STDIN, "/dev/null" or croak "$Script: could not open STDIN: $!";
    open STDOUT, ">/dev/null" or croak "$Script: could not open STDOUT: $!";
    open STDERR, ">/dev/null" or croak "$Script: could not open STDERR: $!";
    exec(@_);
    exit 1;
  }

  # sleep for a while to allow process to start
  sleep(1.5);

  return $pid;
}

sub kill_async {

  # kill process group
  foreach my $pid (@_) {
    kill 'TERM', -$pid if defined($pid);
  }

}
