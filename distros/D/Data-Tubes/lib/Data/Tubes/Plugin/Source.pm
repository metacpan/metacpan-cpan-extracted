package Data::Tubes::Plugin::Source;

# vim: ts=3 sts=3 sw=3 et ai :

use strict;
use warnings;
use English qw< -no_match_vars >;
use Log::Log4perl::Tiny qw< :easy :dead_if_first LOGLEVEL >;
our $VERSION = '0.740';

use Data::Tubes::Util
  qw< normalize_args normalize_filename args_array_with_options >;
use Data::Tubes::Plugin::Util qw< identify log_helper >;
my %global_defaults = (
   input  => 'source',
   output => 'raw',
);

sub iterate_array {
   my %args = normalize_args(@_,
      [{name => 'array iterator', array => []}, 'array']);
   identify(\%args);
   my $logger       = log_helper(\%args);
   my $global_array = $args{array};
   LOGDIE 'undefined global array, omit or pass empty one instead'
     unless defined $global_array;
   my $n_global = @$global_array;
   return sub {
      my $local_array = shift || [];
      my $n_local     = @$local_array;
      my $i           = 0;
      return (
         iterator => sub {
            return if $i >= $n_global + $n_local;
            my $element =
              ($i < $n_global)
              ? $global_array->[$i++]
              : $local_array->[($i++) - $n_global];
            $logger->($element, \%args) if $logger;
            return $element;
         },
      );
   };
} ## end sub iterate_array

sub open_file {
   my %args = normalize_args(
      @_,
      [
         {
            binmode => ':encoding(UTF-8)',
            output  => 'source',
            name    => 'open file',
         },
         'binmode'
      ],
   );
   identify(\%args);

   # valid "output" sub-fields must be defined and at least one char long
   # otherwise output will be ignored
   my $binmode   = $args{binmode};
   my $output    = $args{output};
   my $input     = $args{input};
   my $has_input = defined($input) && length($input);

   return sub {
      my ($record, $file) =
        $has_input ? ($_[0], $_[0]{$input}) : ({}, $_[0]);
      $file = normalize_filename($file);

      if (ref($file) eq 'GLOB') {
         my $is_stdin = fileno($file) == fileno(\*STDIN);
         my $name = $is_stdin ? 'STDIN' : "$file";
         $record->{$output} = {
            fh    => $file,
            input => $file,
            type  => 'handle',
            name  => "handle\:$name",
         };
      } ## end if (ref($file) eq 'GLOB')
      else {
         open my $fh, '<', $file
           or die "open('$file'): $OS_ERROR";
         binmode $fh, $binmode;
         my $type = (ref($file) eq 'SCALAR') ? 'scalar' : 'file';
         $record->{$output} = {
            fh    => $fh,
            input => $file,
            type  => $type,
            name  => "$type\:$file",
         };
      } ## end else [ if (ref($file) eq 'GLOB')]

      return $record;
   };
} ## end sub open_file

sub iterate_files {
   my ($files, $args) = args_array_with_options(
      @_,
      {    # these are the default options
         name => 'files',

         # options specific for sub-tubes
         iterate_array_args => {},
         open_file_args     => {},
         logger_args        => {
            target => sub {
               my $record = shift;
               return 'reading from ' . $record->{source}{name},;
            },
         },
      }
   );
   identify($args);

   use Data::Tubes::Plugin::Plumbing;
   return Data::Tubes::Plugin::Plumbing::sequence(
      tubes => [
         iterate_array(
            %{$args->{iterate_array_args}}, array => $files,
         ),
         open_file(%{$args->{open_file_args}}),
         Data::Tubes::Plugin::Plumbing::logger(%{$args->{logger_args}}),
      ]
   );
} ## end sub iterate_files

1;
