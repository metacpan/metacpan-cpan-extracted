package Data::Tubes::Plugin::Reader;
use strict;
use warnings;
use English qw< -no_match_vars >;
our $VERSION = '0.738';

use Log::Log4perl::Tiny qw< :easy :dead_if_first LOGLEVEL >;

use Data::Tubes::Util qw< normalize_args shorter_sub_names >;
use Data::Tubes::Plugin::Util qw< identify >;
my %global_defaults = (
   input  => 'source',
   output => 'raw',
);

sub read_by_line {
   return read_by_separator(
      normalize_args(
         @_,
         {
            name           => 'read_by_line',
            identification => {caller => [caller(0)]},
         }
      ),
      separator => "\n",
   );
} ## end sub read_by_line

sub read_by_paragraph {
   return read_by_separator(
      normalize_args(
         @_,
         {
            name           => 'read_by_paragraph',
            identification => {caller => [caller(0)]},
         }
      ),
      separator => '',
   );
} ## end sub read_by_paragraph

sub read_by_record_reader {
   my %args = normalize_args(
      @_,
      [
         {
            %global_defaults,
            emit_eof       => 0,
            name           => 'read_by_record_reader',
            identification => {caller => [caller(0)]},
         },
         'record_reader'
      ],
   );
   identify(\%args);
   my $name = $args{name};

   my $record_reader = $args{record_reader};
   LOGDIE "$name undefined record_reader" unless defined $record_reader;
   LOGDIE "$name record_reader MUST be a sub reference"
     unless ref($record_reader) eq 'CODE';

   my $emit_eof  = $args{emit_eof};
   my $input     = $args{input};
   my $has_input = defined($input) && length($input);
   my $output    = $args{output};
   return sub {
      my $record = shift;
      my $source = $has_input ? $record->{$input} : $record;
      my $fh     = $source->{fh};

      return (
         iterator => sub {
            my $read = $record_reader->($fh);
            my $retval = {%$record, $output => $read};
            return $retval if defined $read;
            if ($emit_eof) {
               $emit_eof = 0;
               return $retval;
            }
            return;
         },
      );
   };
} ## end sub read_by_record_reader

sub read_by_separator {
   my %args = normalize_args(
      @_,
      [
         {
            name           => 'read_by_separator',
            chomp          => 1,
            identification => {caller => [caller(0)]},
         },
         'separator'
      ]
   );
   my $separator = $args{separator};
   my $chomp     = $args{chomp};
   return read_by_record_reader(
      %args,
      record_reader => sub {
         my $fh = shift;
         local $INPUT_RECORD_SEPARATOR = $separator;
         my $retval = <$fh>;
         chomp($retval) if defined($retval) && $chomp;
         return $retval;
      },
   );
} ## end sub read_by_separator

shorter_sub_names(__PACKAGE__, 'read_');

1;
