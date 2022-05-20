#!/usr/bin/env perl

use v5.30;
use strict;
use warnings;
use FindBin qw/ $RealBin /;
use lib ".", "$RealBin/Pod-Query/lib";
use Module::Functions qw/ get_public_functions get_full_functions /;
use Module::CoreList;
use Pod::Query;
use File::Basename qw/ basename        /;
use List::Util qw/ max             /;
use Getopt::Long;
use Mojo::Base qw/ -strict -signatures /;
use Mojo::ByteStream qw/ b /;
use Mojo::File qw/ path/;
use Mojo::JSON qw/ j /;
use Mojo::Util qw/ dumper /;
use Term::ANSIColor qw( colored colorstrip );
use subs qw/ r sayt /;

use constant DEBUG_POD => 0;


#--------------------------------------------
#                    MAIN
#--------------------------------------------

my $opts = get_opts();
my $NULL_FH;

list_tool_options( $opts ) if $opts->{list_tool_options};
show_help()                if not @ARGV or $opts->{help};

my ( $class, @args ) = @ARGV;
my ( $method ) = @args;
list_class_options( $class ) if $opts->{list_class_options};

import_class( $class ) or exit;

debug_pod( $class ) if DEBUG_POD;

if ( $opts->{edit} ) {
   edit_file( $class, $method );
}
elsif ( $opts->{doc} ) {
   doc_class( $class, @args );
}

print_header( $class );
if ( $method ) {
   show_method_doc( $class, $method );
}
else {
   show_inheritance( $class );
   my $save = {
      class   => $class,
      options => [ show_events( $class ), show_methods( $class, $opts ), ],
   };
   save_last_class_and_options( $save );
   list_class_options( $class ) if $opts->{list_class_options};
}


#--------------------------------------------
#                    SUBS
#--------------------------------------------

sub define_spec {
   <<~SPEC;

      all|a              - Show all class functions.
      doc|d              - View the class documentation.
      edit|e             - Edit the source code.
      help|h             - Show this help section.
      list_tool_options  - List tool options.
      list_class_options - List class events and methods.

   SPEC
}

sub _build_spec_list {
   map    { [ split / \s+ - \s+ /x, $_, 2 ] }   # Split into: opts - description
     map  { b( $_ )->trim }                     # Trim leading/trailing spaces
     grep { not /^ \s* $/x }                    # Blank lines
     split "\n", define_spec();
}

sub get_spec_list {
   map { $_->[0] } _build_spec_list();
}

sub get_optios_list {
   sort
     map { length( $_ ) == 1 ? "-$_" : "--$_"; }
     map { split /\|/ } get_spec_list();
}

sub get_opts {
   my $opts = {};

   GetOptions( $opts, get_spec_list ) or die $!;

   $opts;
}

sub list_tool_options ( $opts ) {
   say for get_optios_list();
   exit unless $opts->{list_class_options};
}

=head2 list_class_options

   Use last saved data if available since this is the typical usage.

=cut

sub list_class_options ( $class ) {
   my $last_data = get_last_class_and_options();
   if ( $last_data->{class} eq $class ) {
      select STDOUT;
      say for $last_data->{options}->@*;
      exit;
   }

   # Ignore the output.
   open $NULL_FH, '>', '/dev/null' or die $!;
   select $NULL_FH;
}

sub show_help {
   my $YELLOW  = "\e[33m";
   my $RESTORE = "\e[0m";
   my $self    = basename( $0 );
   $self =~ s/ \.\w+ $ //x;
   $self = "$YELLOW$self$RESTORE";

   my @all = map {
      my ( $opt, $desc ) = @$_;
      $opt =~ s/\|/, /g;
      $opt =~ s/ (?=\b\w{2}) /--/gx;    # Long opts
      $opt =~ s/ (?=\b\w\b)  /-/gx;     # Short opts
      my $colored_opt = _green( $opt );
      [ $colored_opt, _grey( $desc ), length $colored_opt ];
   } _build_spec_list();

   my $max = max map { $_->[2] } @all;

   my $options =
     join "\n   ",
     map { sprintf "%-${max}s - %s", @$_[ 0, 1 ] } @all;

   say <<~HELP;

   @{[ _grey("Shows available class methods and documentation") ]}

   @{[ _neon("Syntax:") ]}
      $self module_name [method_name]

   @{[ _neon("Options::") ]}
      $options

   @{[ _neon("Examples:") ]}
      @{[ _grey("# Methods") ]}
      $self Mojo::UserAgent
      $self Mojo::UserAgent -a

      @{[ _grey("# Method") ]}
      $self Mojo::UserAgent prepare

      @{[ _grey("# Documentation") ]}tion
      $self Mojo::UserAgent -d

      @{[ _grey("# Edit") ]}
      $self Mojo::UserAgent -e
      $self Mojo::UserAgent prepare -e

      @{[ _grey("# List all methods") ]}
      $self Mojo::UserAgent --list_class_options
   HELP

   exit;
}

sub import_class ( $class ) {

   # Since ojo imports its DSL into the current package
   eval { eval "package $class; use $class"; };

   my $import_ok = do {
      if ( $@ ) { warn $@; 0 }
      else      { 1 }
   };

   $import_ok;
}

sub debug_pod ( $class ) {
   my $pod = Pod::Query->new( $class );
   my $doc = $pod->find_method_summary( $class );
   say dumper $pod;
   say $doc;

   say Pod::Query->new( "ojo" )->find_title;

   exit;
}

sub edit_file ( $class, $method ) {
   my $path = Pod::Query->new( $class, "path" )->path;
   my $cmd  = "vim $path";

   if ( $method ) {
      my $m      = "<\\zs$method\\ze>";
      my $sub    = "<sub $m";
      my $monkey = "<monkey_patch>.+$m";
      my $list   = "^ +$m +\\=\\>";
      my $qw     = "<qw>.+$m";
      my $emit   = "<(emit|on)\\($m";
      $cmd .= " '+/\\v$sub|$monkey|$list|$qw|$emit'";
   }

   # say $cmd;
   # exit;
   exec $cmd;
}

sub doc_class ( $class, @args ) {
   my $cmd = "perldoc @args $class";

   # say $cmd;
   exec $cmd;
}

sub print_header ( $class ) {
   my $pod           = Pod::Query->new( $class );
   my $version       = $class->VERSION;
   my $first_release = Module::CoreList->first_release( $class );

   my @package_line = (
      _grey( "Package:" ),
      sprintf(
         "%s%s%s",
         _yellow( $class ),
         ( $version ? _green( " $version" ) : "" ),
         (
            $first_release
            ? _grey( " (since perl " ) . _green( $first_release ) . _grey( ")" )
            : ""
         ),
      ),
   );
   my @path_line = ( _grey( "Path:" ), _grey( $pod->path ), );

   my $max    = max map { length } $package_line[0], $path_line[0];
   my $format = "%-${max}s %s";

   say "";
   sayt sprintf( $format, @package_line );
   sayt sprintf( $format, @path_line );

   say "";
   my ( $name, $summary ) = split /\s*-\s*/, $pod->find_title, 2;
   return unless $name and $summary;

   sayt _yellow( $name ) . " - " . _green( $summary );
   say "";
}

sub show_method_doc ( $class, $method ) {
   my $doc = Pod::Query->new( $class )->find_method( $method );

   for ( $doc ) {

      # Headings.
      s/ ^ \s* \K (\S+:) (?= \s* $ ) / _green($1) /xgem;

      # Comments.
      s/ (\#.+) / _grey($1) /xge;
   }

   say $doc;
}

sub show_inheritance ( @classes ) {
   my @tree;
   my %seen;
   no strict 'refs';

   while ( my $class = shift @classes ) {
      next if $seen{class};    # Already saw it
      $seen{$class}++;         # Otherwise, now we did
      push @tree, $class;      # Add to tree

      eval "require $class";
      my @isa = @{"${class}::ISA"};
      push @classes, @isa;
   }

   my $size = @tree;
   return if $size <= 1;
   say _neon( "Inheritance ($size):" );
   say _grey( " $_" ) for @tree;
   say "";
}

sub show_events ( $class ) {
   my %events = Pod::Query->new( $class )->find_events;
   my @names  = sort keys %events;
   my $size   = @names;
   return unless $size;

   my @save;
   my $len    = max map { length( _green( $_ ) ) } @names;
   my $format = " %-${len}s - %s";

   say _neon( "Events ($size):" );
   for ( @names ) {
      sayt sprintf $format, _green( $_ ), _grey( $events{$_} );
      push @save, $_;
   }

   say "";

   @save;
}

sub show_methods ( $class, $opts ) {

   #my @dirs = $class->dir;
   my @dirs = sort { $a cmp $b } get_full_functions( $class );
   my $pod  = Pod::Query->new( $class );
   my $doc  = "";

   my @meths_all = map {
      my $doc = $pod->find_method_summary( $_ );
      [ $_, $doc ];
   } @dirs;

   # Documented methods
   my @meths_doc = grep { $_->[1] } @meths_all;
   my @save =
     grep { / ^ [\w_-]+ $ /x }
     map { $_->[0] } @meths_all;

   # If we have methods, but none are documented
   if ( @meths_all and not @meths_doc ) {
      say _grey(
         "Warning: All methods are undocumented! (reverting to --all)\n" );
      $opts->{all} = 1;
   }

   my @meths = $opts->{all} ? @meths_all : @meths_doc;
   my $size  = @meths;
   my $max   = max map { length _green( $_->[0] ) } @meths;
   $max //= 0;

   my $format = " %-${max}s%s";
   say _neon( "Methods ($size):" );

   for my $list ( @meths ) {
      my ( $method, $doc_raw ) = @$list;
      my $doc = $doc_raw ? " - $doc_raw" : "";
      $doc =~ s/\n+/ /g;
      sayt sprintf $format, _green( $method ), _grey( $doc );
   }

   say _grey( "\nUse --all (or -a) to see all methods." )
     unless $opts->{all};
   say "";

   @save;
}

sub _trim ( $line ) {
   my $term_width  = Pod::Query::get_term_width();
   my $replacement = " ...";
   my $width = $term_width - length( $replacement ) - 1;    # "-1" for newline

   # Trim to terminal width
   my $colored_length   = length( $line );
   my $uncolored_length = length( colorstrip( $line ) );
   my $diff_length      = $colored_length - $uncolored_length;
   $diff_length = $diff_length - 3 if $diff_length;

   if ( $uncolored_length >= $term_width ) {    # "=" also for newline
      $line = substr( $line, 0, $width + $diff_length ) . $replacement;
   }

   $line;
}

sub r {

   say dumper \@_;
}

sub sayt {

   say _trim( @_ );
}

sub _red {

   colored( "@_", "RESET RED" );
}

sub _yellow {

   colored( "@_", "RESET YELLOW" );
}

sub _green {

   # Reset since last line may be trimmed.
   colored( "@_", "RESET GREEN" );
}

sub _grey {

   colored( "@_", "RESET DARK" );
}

sub _neon {

   colored( "@_", "RESET ON_BRIGHT_BLACK" );
}

sub define_last_run_cache_file {
   "$ENV{HOME}/.cache/my_pod_last_run.cache";

}

sub save_last_class_and_options ( $save ) {
   my $file = define_last_run_cache_file();
   my $path = path( $file );

   if ( not -e $path->dirname ) {
      mkdir $path->dirname or die $!;
   }

   $path->spurt( j $save );
}

sub get_last_class_and_options {
   my $file = define_last_run_cache_file();
   return { class => '' } unless -e $file;

   j path( $file )->slurp;
}

=for REMOVE

#--------------------------------------------
#               UNIVERSAL
#--------------------------------------------

package UNIVERSAL;

sub dir{
   my ($s)   = @_;               # class or object
   my $ref   = ref $s;
   my $class = $ref ? $ref : $s; # myClass
   my $pkg   = $class . "::";    # MyClass::
   my @keys_raw;
   my $is_special_block = qr/^ (?:BEGIN|UNITCHECK|INIT|CHECK|END|import|DESTROY) $/x;

   no strict 'refs';

   while( my($key,$stash) = each %$pkg){
#     next if $key =~ /$is_special_block/;   # Not a special block
#     next if $key =~ /^ _ /x;               # Not private method
      next if ref $stash;                    # Stash name should not be a reference
      next if not defined *$stash{CODE};     # Stash function should be defined
      push @keys_raw, $key;
   }

   my @keys = sort @keys_raw;

   return @keys if defined wantarray;

   say join "\n  ", "\n$class", @keys;
}

=cut
