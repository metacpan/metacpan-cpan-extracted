package App::Sets;
$App::Sets::VERSION = '0.976';


use strict;
use warnings;

# ABSTRACT: set operations in Perl

use English qw( -no_match_vars );
use 5.010;
use Getopt::Long
  qw< GetOptionsFromArray :config pass_through no_ignore_case bundling >;
use Pod::Usage qw< pod2usage >;
use Log::Log4perl::Tiny qw< :easy :dead_if_first LOGLEVEL >;
use App::Sets::Parser;
use App::Sets::Iterator;
use App::Sets::Operations;
use App::Sets::Sort qw< sort_filehandle >;

my %config = (
   binmode => ':raw:encoding(UTF-8)',
   loglevel => 'INFO',
   parsedebug => 0,
);

sub populate_config {
   my (@args) = @_;

   $config{sorted} = 1                if $ENV{SETS_SORTED};
   $config{trim}   = 1                if $ENV{SETS_TRIM};
   $config{cache}  = $ENV{SETS_CACHE} if exists $ENV{SETS_CACHE};
   $config{loglevel}  = $ENV{SETS_LOGLEVEL}
      if exists $ENV{SETS_LOGLEVEL};
   $config{parsedebug}  = $ENV{SETS_PARSEDEBUG}
      if exists $ENV{SETS_PARSEDEBUG};
   $config{internal_sort} = $ENV{SETS_INTERNAL_SORT}
      if exists $ENV{SETS_INTERNAL_SORT};
   $config{binmode} = $ENV{SETS_BINMODE} if $ENV{SETS_BINMODE};
   GetOptionsFromArray(
      \@args, \%config, qw< man help usage version
        binmode|b=s
        cache|cache-sorted|S=s
        internal_sort|internal-sort|I!
        loglevel|l=s
        sorted|s!
        trim|t!
        >
     )
     or pod2usage(
      -verbose  => 99,
      -sections => 'USAGE',
     );
   $App::Sets::VERSION
        //= '0.972' unless defined $App::Sets::VERSION;
   pod2usage(message => "$0 $App::Sets::VERSION", -verbose => 99,
       -sections => ' ')
     if $config{version};
   pod2usage(
      -verbose  => 99,
      -sections => 'USAGE'
   ) if $config{usage};
   pod2usage(
      -verbose  => 99,
      -sections => 'USAGE|EXAMPLES|OPTIONS'
   ) if $config{help};
   pod2usage(-verbose => 2) if $config{man};

   LOGLEVEL $config{loglevel};

   $config{cache} = '.sorted'
     if exists $config{cache}
        && !(defined($config{cache}) && length($config{cache}));
   $config{sorted} = 1 if exists $config{cache};

   if (exists $config{cache}) {
      INFO "using sort cache or generating it when not available";
   }
   elsif ($config{sorted}) {
      INFO "assuming input files are sorted";
   }
   INFO "trimming away leading/trailing whitespaces"
     if $config{trim};

   pod2usage(
      -verbose  => 99,
      -sections => 'USAGE',
   ) unless @args;

   return @args;
} ## end sub populate_config

sub run {
   my $package = shift;
   my @args    = populate_config(@_);

   my $input;
   if (@args > 1) {
      shift @args if $args[0] eq '--';
      LOGDIE "only file op file [op file...] "
        . "with multiple parameters (@args)...\n"
        unless @args % 2;
      my @chunks;
      while (@args) {
         push @chunks, escape(shift @args);
         push @chunks, shift @args if @args;
      }
      $input = join ' ', @chunks;
   } ## end if (@args > 1)
   else {
      $input = shift @args;
   }

   LOGLEVEL('DEBUG') if $config{parsedebug};
   DEBUG "parsing >$input<";
   my $expression = App::Sets::Parser::parse($input, 0);
   LOGLEVEL($config{loglevel});

   binmode STDOUT, $config{binmode};

   my $it = expression($expression);
   while (defined(my $item = $it->drop())) {
      print {*STDOUT} $item;
      print {*STDOUT} "\n" if $config{trim};
   }
   return;
} ## end sub run

sub escape {
   my ($text) = @_;
   $text =~ s{(\W)}{\\$1}gmxs;
   return $text;
}

sub expression {
   my ($expression) = @_;
   if (ref $expression) {    # operation
      my ($op, $l, $r) = @$expression;
      my $sub = App::Sets::Operations->can($op);
      return $sub->(expression($l), expression($r));
   }
   else {                    # plain file
      return file($expression);
   }
} ## end sub expression

sub file {
   my ($filename) = @_;
   LOGDIE "invalid file '$filename'\n"
     unless -r $filename && !-d $filename;

   if ($config{cache}) {
      my $cache_filename = $filename . $config{cache};
      if (!-e $cache_filename) {    # generate cache file
         WARN "generating cached sorted file "
           . "'$cache_filename', might wait a bit...";
         my $ifh = sort_filehandle($filename, \%config);
         open my $ofh, '>', $cache_filename
           or LOGDIE "open('$cache_filename') for output: $OS_ERROR";
         while (<$ifh>) {
            print {$ofh} $_;
         }
         close $ofh or LOGDIE "close('$cache_filename'): $OS_ERROR";
      } ## end if (!-e $cache_filename)
      INFO "using '$cache_filename' (assumed to be sorted) "
        . "instead of '$filename'";
      $filename = $cache_filename;
   } ## end if ($config{cache})

   my $fh;
   if ($config{sorted}) {
      INFO "opening '$filename', assuming it is already sorted"
        unless $config{cache};
      open $fh, '<', $filename
        or LOGDIE "open('$filename'): $OS_ERROR";
   } ## end if ($config{sorted})
   else {
      INFO "opening '$filename' and sorting on the fly";
      $fh = sort_filehandle($filename, \%config);
   }
   return App::Sets::Iterator->new(
      sub {
         my $retval = <$fh>;
         return unless defined $retval;
         $retval =~ s{\A\s+|\s+\z}{}gmxs
           if $config{trim};
         return $retval;
      }
   );
} ## end sub file

1;

__END__

=pod

=head1 NAME

App::Sets - set operations in Perl

=head1 VERSION

version 0.976

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
