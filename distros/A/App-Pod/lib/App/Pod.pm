package App::Pod;

use v5.24;    # Postfix defef :)
use strict;
use warnings;
use Module::Functions qw/ get_public_functions get_full_functions /;
use Module::CoreList;
use File::Basename qw/ basename /;
use File::Spec::Functions qw/ catfile  /;
use List::Util qw/ max /;
use Getopt::Long;
use Mojo::Base qw/ -strict /;
use Mojo::ByteStream qw/ b /;
use Mojo::File qw/ path/;
use Mojo::JSON qw/ j /;
use Mojo::Util qw/ dumper /;
use Term::ANSIColor qw( colored colorstrip );
use Pod::Query;
use subs qw/ r sayt /;


=head1 NAME

 ~                      __   __              __ ~
 ~     ____  ____  ____/ /  / /_____  ____  / / ~
 ~    / __ \/ __ \/ __  /  / __/ __ \/ __ \/ /  ~
 ~   / /_/ / /_/ / /_/ /  / /_/ /_/ / /_/ / /   ~
 ~  / .___/\____/\__,_/   \__/\____/\____/_/    ~
 ~ /_/                                          ~

App::Pod - Quickly show available class methods and documentation.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

View summary of Mojo::UserAgent:

 % pod Mojo::UserAgent

View summary of a specific method.

 % pod Mojo::UserAgent get

Edit the module

 % pod Mojo::UserAgent -e

Edit the module and jump to the specific method definition right away.
(Press "n" to next match if neeeded).

 % pod Mojo::UserAgent get -e

Run perldoc on the module (for convience).

 % pod Mojo::UserAgent -d

List all available methods.
If no methods are found normally, then this will automatically be enabled.
(pod was made to work with Mojo pod styling).

 % pod Mojo::UserAgent -a

Show help.

 % pod
 % pod -h


=head1 DESCRIPTION


=head1 SUBROUTINES/METHODS

=head2 run

Run the main program.

   use App::Pod;
   App::Pod->run;

=cut

sub run {
   my $self = __PACKAGE__->new;
   my $opts = get_opts();

   if ( $opts->{list_tool_options} ) {
      list_tool_options();
      return unless $opts->{list_class_options};
   }

   if ( not @ARGV or $opts->{help} ) {
      show_help();
      return;
   }

   my ( $class, @args ) = @ARGV;
   my ( $method ) = @args;

   if ( $opts->{list_class_options} ) {
      return if $self->list_class_options( $class );
   }

   import_class( $class ) or return;

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
      if ( $opts->{list_class_options} ) {
         return if $self->list_class_options( $class );
      }
   }
}

=head2 new

Create a new object.

=cut

sub new {
   my ( $class ) = @_;
   my $null_fh;

   bless {
      null_fh => \$null_fh,    # TODO: WHY?
   }, $class;
}

=head2 define_spec

Define the command line argument specificaiton.

=cut

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

=head2 list_tool_options

Returns a list of the possible command line options
to this tool.

=cut

sub list_tool_options {
   say for get_optios_list();
}

=head2 list_class_options

   Use last saved data if available since this is the typical usage.

=cut

sub list_class_options {
   my ( $self, $class ) = @_;
   my $last_data = get_last_class_and_options();
   if ( $last_data->{class} eq $class ) {
      select STDOUT;
      say for $last_data->{options}->@*;
      return 1;
   }

   # Ignore the output.
   open $self->{null_fh}, '>', '/dev/null' or die $!;
   $self->{stdout_fh} = select $self->{null_fh};
}

sub show_help {
   my $scipt = _yellow( "pod" );

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
      $scipt module_name [method_name]

   @{[ _neon("Options::") ]}
      $options

   @{[ _neon("Examples:") ]}
      @{[ _grey("# Methods") ]}
      $scipt Mojo::UserAgent
      $scipt Mojo::UserAgent -a

      @{[ _grey("# Method") ]}
      $scipt Mojo::UserAgent prepare

      @{[ _grey("# Documentation") ]}
      $scipt Mojo::UserAgent -d

      @{[ _grey("# Edit") ]}
      $scipt Mojo::UserAgent -e
      $scipt Mojo::UserAgent prepare -e

      @{[ _grey("# List all methods") ]}
      $scipt Mojo::UserAgent --list_class_options
   HELP
}

sub import_class {
   my ( $class ) = @_;

   # Since ojo imports its DSL into the current package
   eval { eval "package $class; use $class"; };

   my $import_ok = do {
      if ( $@ ) { warn $@; 0 }
      else      { 1 }
   };

   $import_ok;
}

sub edit_file {
   my ( $class, $method ) = @_;
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

sub doc_class {
   my ( $class, @args ) = @_;
   my $cmd = "perldoc @args $class";

   # say $cmd;
   exec $cmd;
}

sub print_header {
   my ( $class )     = @_;
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

sub show_method_doc {
   my ( $class, $method ) = @_;
   my $doc = Pod::Query->new( $class )->find_method( $method );

   for ( $doc ) {

      # Headings.
      s/ ^ \s* \K (\S+:) (?= \s* $ ) / _green($1) /xgem;

      # Comments.
      s/ (\#.+) / _grey($1) /xge;
   }

   say $doc;
}

sub show_inheritance {
   my ( @classes ) = @_;
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

sub show_events {
   my ( $class ) = @_;
   my %events    = Pod::Query->new( $class )->find_events;
   my @names     = sort keys %events;
   my $size      = @names;
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

sub show_methods {
   my ( $class, $opts ) = @_;

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

sub _trim {
   my ( $line )    = @_;
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
   catfile( $ENV{HOME}, ".cache", "my_pod_last_run.cache" );

}

sub save_last_class_and_options {
   my ( $save ) = @_;
   my $file     = define_last_run_cache_file();
   my $path     = path( $file );

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

# pod version 0

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

=head1 ENVIRONMENT

Install bash completion support.

 % apt install bash-completion

Install tab completion.

 % source bashrc_pod

=head1 SEE ALSO

L<Pod::Query>

L<Pod::LOL>

L<Module::Functions>


=head1 AUTHOR

Tim Potapov, C<< <tim.potapov[AT]gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/poti1/app-pod/issues>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Pod

You can also look for information at:

L<https://metacpan.org/pod/App::Pod>
L<https://github.com/poti1/app-pod>


=head1 ACKNOWLEDGEMENTS

TBD


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Tim Potapov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of App::Pod
