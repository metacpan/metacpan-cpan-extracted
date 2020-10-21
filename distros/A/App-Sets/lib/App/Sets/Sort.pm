package App::Sets::Sort;
$App::Sets::Sort::VERSION = '0.978';


use strict;
use warnings;

# ABSTRACT: sort handling

use English qw( -no_match_vars );
use 5.010;
use File::Temp qw< tempfile >;
use Fcntl qw< :seek >;
use Log::Log4perl::Tiny qw< :easy :dead_if_first >;
use base 'Exporter';

our @EXPORT_OK = qw< sort_filehandle internal_sort_filehandle >;
our @EXPORT = qw< sort_filehandle >;
our %EXPORT_TAGS = (
   default => [ @EXPORT ],
   all => [ @EXPORT_OK ],
);

sub _test_external_sort {
   my $filename;

   eval {
      (my $fh, $filename) = tempfile(); # might croak
      binmode $fh, ':raw';
      print {$fh} "one\ntwo\nthree\nfour\n" or die 'whatever';
      close $fh or die 'whatever';
   } or return;

   my $fh = eval {
      open my $tfh, '-|', 'sort', '-u', $filename;
      $tfh;
   } or return;
   my @lines = <$fh>;
   return unless scalar(@lines) == 4;
   return unless defined $lines[3];
   $lines[3] =~ s{\s+}{}gmxs;
   return unless $lines[3] eq 'two';

   return 1;
}

sub sort_filehandle {
   my ($filename, $config) = @_;
   $config ||= {};
   state $has_sort = (!$config->{internal_sort}) && _test_external_sort();

   if ($has_sort) {
      my $fh;
      eval { open $fh, '-|', 'sort', '-u', $filename } and return $fh;
      WARN 'cannot use system sort, falling back to internal implementation';
      $has_sort = 0; # from now on, use internal sort
   }

   return internal_sort_filehandle($filename);
}

sub internal_sort_filehandle {
   my ($filename) = @_;

   # Open input stream
   open my $ifh, '<', $filename
      or LOGDIE "open('$filename'): $OS_ERROR";

   # Maximum values hints taken from Perl Power Tools' sort
   my $max_records = $ENV{SETS_MAX_RECORDS} || 200_000;
   my $max_files = $ENV{SETS_MAX_FILES} || 40;
   my (@records, @fhs);
   while (<$ifh>) {
      chomp;
      push @records, $_;
      if (@records >= $max_records) {
         push @fhs, _flush_to_temp(\@records);
         _compact(\@fhs) if @fhs >= $max_files - 1;
      }
   }

   push @fhs, _flush_to_temp(\@records) if @records;
   _compact(\@fhs);
   return $fhs[0] if @fhs;

   # seems like the file was empty... so it's sorted
   seek $ifh, 0, SEEK_SET;
   return $ifh;
}

sub _flush_to_temp {
   my ($records) = @_;
   my $tfh = tempfile(UNLINK => 1);
   my $previous;
   for my $item (sort @$records) {
      next if defined($previous) && $previous eq $item;
      print {$tfh} $item, $INPUT_RECORD_SEPARATOR;
   }
   @$records = ();
   seek $tfh, 0, SEEK_SET;
   return $tfh;
}

sub _compact {
   my ($fhs) = @_;
   return if @$fhs == 1;

   # where the output will end up
   my $ofh = tempfile(UNLINK => 1);

   # convenience hash for tracking all contributors
   my %its = map {
      my $fh = $fhs->[$_];
      my $head = <$fh>;
      if (defined $head) {
         chomp($head);
         $_ => [ $fh, $head ];
      }
      else { () }
   } 0 .. $#$fhs;

   # iterate until all contributors are exhausted
   while (scalar keys %its) {

      # select the best (i.e. "lower"), cleanup on the way
      my ($fk, @keys) = keys %its;
      my $best = $its{$fk}[1];
      for my $key (@keys) {
         my $head = $its{$key}[1];
         $best = $head if $best gt $head;
      }
      print {$ofh} $best, $INPUT_RECORD_SEPARATOR;

      # get rid of the best in all iterators, cleanup on the way
      KEY:
      for my $key ($fk, @keys) {
         my $head = $its{$key}[1];
         while ($head eq $best) {
            $head = readline $its{$key}[0];
            if (defined $head) {
               chomp($its{$key}[1] = $head);
            }
            else {
               delete $its{$key};
               next KEY;
            }
         }
      }
   }

   # rewind, finalize compacting, return
   seek $ofh, 0, SEEK_SET;
   @$fhs = ($ofh);
   return;
}

1;

__END__

=pod

=head1 NAME

App::Sets::Sort - sort handling

=head1 VERSION

version 0.978

=head1 AUTHOR

Flavio Poletti <polettix@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2016 by Flavio Poletti polettix@cpan.org.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
