package App::Pod;

use v5.24;    # Postfix deref :)
use strict;
use warnings;
use Pod::Query;
use Module::CoreList();
use Getopt::Long          qw( GetOptions );
use Module::Functions     qw( get_full_functions );
use File::HomeDir         qw( home );
use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile  );
use List::Util            qw( first max );
use Mojo::File            qw( path );
use Mojo::JSON            qw( j );
use Perl::OSType          qw( os_type );
use Term::ANSIColor       qw( colored );
use Carp                  qw( cluck );
use open                  qw( :std :utf8 );
use subs                  qw( _sayt uniq );

# Catch eval warnings better.
$SIG{__WARN__} = sub { cluck shift };

=head1 LOGO

 ~                      __ ~
 ~     ____  ____  ____/ / ~
 ~    / __ \/ __ \/ __  /  ~
 ~   / /_/ / /_/ / /_/ /   ~
 ~  / .___/\____/\__,_/    ~
 ~ /_/                     ~

=head1 NAME

App::Pod - Quickly show available class methods and documentation.

=cut

our $VERSION = '0.35';


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

Run perldoc on the module (for convenience).

 % pod Mojo::UserAgent -d

List all available methods.
If no methods are found normally, then this will automatically be enabled.
(pod was made to work with Mojo pod styling).

 % pod Mojo::UserAgent -a

List all Module::Build actions.

 % pod Module::Build --query head1=ACTIONS/item-text

Can do the same stuff with a file

 % pod my.pod --query head1

Show help.

 % pod
 % pod -h


=head1 DESCRIPTION

Basically, this is a tool that can quickly summarize the contents of a perl module.

=head1 SUBROUTINES/METHODS

=cut

#
# Method maker
#

=head2 _has

Generates class accessor methods (like Mojo::Base::attr)

=cut

sub _has {
    no strict 'refs';
    for my $attr ( @_ ) {
        *$attr = sub {
            return $_[0]{$attr} if @_ == 1;    # Get: return $self-<{$attr}
            $_[0]{$attr} = $_[1];              # Set: $self->{$attr} = $val
            $_[0];                             # return $self
          }
          if not defined &$attr;
    }
}

sub import {
    _has qw(
      _class
      _args
      _method
      _opts
      _core_flags
      _non_main_flags
      _cache_from_file
      _cache_pod
      _cache_path
      _cache_name_and_summary
      _cache_version
      _cache_isa
      _cache_events
      _cache_methods
      _cache_method_and_doc
      _dirty_cache
    );
}

#
# Debug
#

sub _dumper {
    require Data::Dumper;
    my $data = Data::Dumper
      ->new( [@_] )
      ->Indent( 1 )
      ->Sortkeys( 1 )
      ->Terse( 1 )
      ->Useqq( 1 )
      ->Dump;
    return $data if defined wantarray;
    say $data;
}

#
# Run
#

=head2 run

Run the main program.

   use App::Pod;
   App::Pod->run;

Or just use the included script:

    % pod

=cut

sub run {
    my $self = __PACKAGE__->_new;

    return if $self->_process_core_flags;
    return if $self->_abort;

    if ( $self->_non_main_flags->@* ) {
        $self->_process_non_main;
    }
    else {
        $self->_process_main;
    }

    $self->_dump();
    $self->store_cache if $self->_dirty_cache;
}

sub _new {
    my ( $class ) = @_;
    my $self      = bless {}, $class;

    $self->_init;

    $self;
}

sub _init {
    my ( $self ) = @_;

    # Show help when no input.
    @ARGV = ( "--help" ) if not @ARGV;

    my $o = _get_opts();
    my ( $class, @args ) = @ARGV;

    $self->_opts( $o );
    $self->_class( $class );
    $self->_args( \@args );
    $self->_method( $args[0] );

    my @core_flags;
    my @non_main_flags;

    for ( $self->_define_spec() ) {

        # We are using the option and it has a handler.
        next unless $o->{ $_->{name} } and $_->{handler};

        if ( $_->{core} ) {
            push @core_flags, $_;
        }
        else {
            push @non_main_flags, $_;
        }
    }

    # Core flags.
    # These do not need any error checks
    # and will be processed early.
    $self->_core_flags( \@core_flags );

    # Non main flags.
    # These are features separate from the main program.
    $self->_non_main_flags( \@non_main_flags );

    # Explicitly force getting the real data.
    $self->_dirty_cache( 1 ) if $o->{flush_cache};

    # Not sure how to handle colors in windows.
    $self->_no_colors() if $self->_opts->{no_colors} or os_type eq "Windows";
}

sub _no_colors {
    my @colors = qw(
      _red
      _yellow
      _green
      _grey
      _neon
      _reset
    );

    no strict 'refs';
    no warnings 'redefine';

    # Pass through the args.
    for my $color ( @colors ) {
        *$color = sub { "@_" };
    }
}

sub _dump {
    my ( $self ) = @_;
    my $dump = $self->_opts->{dump} or return;
    my $data;

    if ( $dump >= 2 ) {    # Dump all.
        $data = $self;
    }
    elsif ( $dump >= 1 ) {    # Skip lol and tree.
        $data = {%$self};        # Shallow copy.
        for ( keys %$data ) {    # Keep the dump simple.
            delete $data->{$_} if /^_cache_/ and !/path/;
        }
    }

    say "self=" . _dumper $data;
}

# Spec

sub _define_spec {
    my @spec = (

        # If given a handler, will be auto processed.
        # Core options will be processed early.

        # Core.
        {
            spec        => "help|h",
            description => "Show this help section.",
            handler     => "_show_help",
            core        => 1,
        },
        {
            spec        => "version|v",
            description => "Show this tool version.",
            handler     => "_show_version",
            core        => 1,
        },
        {
            spec        => "tool_options|to",
            description => "List tool options.",
            handler     => "list_tool_options",
            core        => 1,
        },

        # Non main.
        {
            spec        => "class_options|co",
            description => "Class events and methods.",
            handler     => "list_class_options",
        },
        {
            spec        => "doc|d",
            description => "View class documentation.",
            handler     => "doc_class",
        },
        {
            spec        => "edit|e",
            description => "Edit the source code.",
            handler     => "edit_class",
        },
        {
            spec        => "query|q=s",
            description => "Run a pod query.",
            handler     => "query_class",
        },
        {
            spec        => "dump|dd+",
            description => "Dump extra info (adds up).",
            core        => 1,
        },
        {
            spec        => "all|a",
            description => "Show all class functions.",
        },
        {
            spec        => "no_colors",
            description => "Do not output colors.",
        },
        {
            spec        => "no_error",
            description => "Suppress some error message.",
        },
        {
            spec        => "flush_cache|f",
            description => "Flush cache file(s).",
        },
    );

    # Add the name.
    for ( @spec ) {
        $_->{name} = $_->{spec} =~ s/\|.+//r;
    }

    @spec;
}

sub _get_spec_list {
    map { $_->{spec} } _define_spec();
}

sub _get_opts {
    my $opts = {};

    GetOptions( $opts, _get_spec_list() ) or die "$!\n";

    $opts;
}

sub _get_pod {
    my ( $self ) = @_;

    # Use in-memory cache if present.
    my $pod = $self->_cache_pod;
    return $pod if $pod;

    # Otherwise, make a new Pod::Query object.
    $pod = Pod::Query->new( $self->_class );

    # Cache it in-memory.
    $self->_cache_pod( $pod );

    $pod;
}

#
# Core
#

sub _process_core_flags {
    my ( $self ) = @_;

    for ( $self->_core_flags->@* ) {
        say "Processing: $_->{name}" if $self->_opts->{dump};
        my $handler = $_->{handler};
        return 1 if $self->$handler;
    }

    return 0;
}

# Help

sub _show_help {
    my ( $self ) = @_;

    say $self->_process_template(
        $self->_define_help_template,
        $self->_build_help_options,
    );

    return 1;
}

sub _define_help_template {
    <<"HELP";

##_neon:Syntax:
  <SCRIPT> module_name [method_name] [options]

##_neon:Options:
  <OPTIONS>

##_neon:Examples:
  ##_grey:# All or a method
  <SCRIPT> Mojo::UserAgent
  <SCRIPT> Mojo::UserAgent prepare

  ##_grey:# Documentation
  <SCRIPT> Mojo::UserAgent -d

  ##_grey:# Edit class or method
  <SCRIPT> Mojo::UserAgent -e
  <SCRIPT> Mojo::UserAgent prepare -e

  ##_grey:# List all methods
  <SCRIPT> Mojo::UserAgent --class_options

  ##_grey:# List all Module::Build actions.
  <SCRIPT> Module::Build --query head1=ACTIONS/item-text
HELP
}

sub _process_template {
    my ( $self, $template, $options ) = @_;
    my $script = _yellow( "pod" );

    for ( $template ) {

        # Color.
        s/ ^ \s* \K \#\#([\w_]+): (.*) / qq($1("$2")) /gmxee;

        # Expand <SCRIPT> tags.
        s/<SCRIPT>/$script/g;

        # Expand <OPTIONS> tags.
        s/<OPTIONS>/$options/g;
    }

    $template;
}

sub _build_help_options {
    my @all = map {
        my $opt  = $_->{spec};
        my $desc = $_->{description};
        $opt =~ s/\+$//;                  # Trailing plus in option.
        $opt =~ s/=\w+$//g;               # Option parameter.
        $opt =~ s/\|/, /g;
        $opt =~ s/ (?=\b\w{2}) /--/gx;    # Long opts
        $opt =~ s/ (?=\b\w\b)  /-/gx;     # Short opts
        my $colored_opt = _green( $opt );
        [ $colored_opt, _grey( $desc ), length $colored_opt ];
    } _define_spec();

    my $max    = max map { $_->[2] } @all;
    my $indent = " " x 2;

    my $options =
      join "\n$indent",
      map { sprintf "%-${max}s - %s", @$_[ 0, 1 ] } @all;

    $options;
}

# Version

sub _show_version {
    my ( $self ) = @_;
    my $version = $self->VERSION;

    say "pod (App::Pod) $version";

    return 1;
}

# List

=head2 list_tool_options

Returns a list of the possible command line options
to this tool.

=cut

sub list_tool_options {
    my ( $self ) = @_;

    say
      for sort
      map { length( $_ ) == 1 ? "-$_" : "--$_"; }
      map { s/\+$//r }                             # Options which are additive.
      map { s/=\w+$//r }                           # Options which take values.
      map { split /\|/ } _get_spec_list();

    # Abort if not using also --class_options.
    not $self->_opts->{class_options};
}

#
# Abort
#

sub _abort {
    my ( $self ) = @_;
    my $class = $self->_class;

    if ( not $class ) {
        if ( not $self->_opts->{no_error} ) {
            say "";
            say _red( "Class name not provided!" );
            say _reset( "" );
        }
        return 1;
    }

    # No wierd class names.
    if ( $class !~ m{ ^ [-~\w_:\\/. ]+ $ }x ) {
        if ( not $self->_opts->{no_error} ) {
            say "";
            say _red( "Invalid class name: $class" );
            say _reset( "" );
        }
        return 1;
    }

    # Make sure the path is not empty (error signal from Pod::Query).
    if ( not $self->_get_path ) {
        if ( not $self->_opts->{no_error} ) {
            say "";
            say _red( "Class not found: $class" );
            say _reset( "" );
        }
        return 1;
    }

    return 0;
}

sub _get_path {
    my ( $self ) = @_;

    # Use in-memory cache if present.
    my $mem_cache = $self->_cache_path;
    return $mem_cache if $mem_cache;

    # Use disk cache if present.
    my $disk_cache = $self->retrieve_cache;
    if ( $disk_cache and $disk_cache->{path} ) {
        $self->_cache_path( $disk_cache->{path} );
        return $disk_cache->{path};
    }

    # Otherwise, get the class path.
    local $Pod::Query::DEBUG_FIND_DUMP = 1 if $self->_opts->{dump};
    my $path = $self->_get_pod->path;

    # Cache it in-memory.
    $self->_cache_path( $path );

    # Flag that disk cache should be stored later.
    $self->_dirty_cache( 1 );

    $path;
}

#
# Non Main
#

sub _process_non_main {
    my ( $self ) = @_;
    say "_process_non_main()" if $self->_opts->{dump};

    for ( $self->_non_main_flags->@* ) {
        say "Processing: $_->{name}" if $self->_opts->{dump};
        my $handler = $_->{handler};
        return 1 if $self->$handler;
    }
}

# List

=head2 list_class_options

Shows a list of all the available class options
which may be methods, events, etc.

(This is handy for making tab completion based on
a class.)

=cut

sub list_class_options {
    my ( $self ) = @_;

    # Use cache if available.
    my $cache = $self->retrieve_cache();

    # Make class specific cache if missing.
    if ( $cache->{class} ne $self->_class ) {
        $cache = $self->store_cache;
    }

    # Show possible options
    say for $cache->{options}->@*;
}

# Edit

=head2 edit_class

Edit a class using vim.
Can optionally just to a specific keyword.

=cut

sub edit_class {
    my ( $self ) = @_;
    my $path     = $self->_get_path;
    my $method   = $self->_method;
    my $cmd      = "vim $path";

    if ( $method ) {
        my $m      = "<\\zs$method\\ze>";
        my $sub    = "<sub $m";
        my $monkey = "<monkey_patch>.+$m";
        my $list   = "^ +$m +\\=\\>";
        my $qw     = "<qw>.+$m";
        my $emit   = "<(emit|on)\\($m";
        $cmd .= " '+/\\v$sub|$monkey|$list|$qw|$emit'";
    }

    exec $cmd;
}

# Doc

=head2 doc_class

Show the documentation for a module using perldoc.

=cut

sub doc_class {
    my ( $self ) = @_;
    my $class    = $self->_class;
    my @args     = $self->_args->@*;

    exec "perldoc @args $class";
}

# Query

=head2 query_class

Run a pod query using Pod::Query.

Use --dump option to show the data structure.
(For debugging use).

=cut

sub query_class {
    my ( $self ) = @_;

    local $Pod::Query::DEBUG_FIND_DUMP = 1 if $self->_opts->{dump};

    say for $self->_get_pod->find( $self->_opts->{query} );
}

#
# Main
#

sub _process_main {
    my ( $self ) = @_;
    say "_process_main()" if $self->_opts->{dump};

    # Go on.
    $self->show_header;
    if ( $self->_method ) {
        $self->show_method_doc;
    }
    else {
        $self->show_inheritance;
        $self->show_events;
        $self->show_methods;
    }
}

# Header

sub _get_name_and_summary {
    my ( $self ) = @_;

    # Use in-memory cache if present.
    my $mem_cache = $self->_cache_name_and_summary;
    return $mem_cache if $mem_cache;

    # Use disk cache if present.
    my $disk_cache = $self->retrieve_cache;
    if ( $disk_cache and $disk_cache->{name_and_summary} ) {
        $self->_cache_name_and_summary( $disk_cache->{name_and_summary} );
        return $disk_cache->{name_and_summary};
    }

    # Otherwise, get all class events.
    local $Pod::Query::DEBUG_FIND_DUMP = 1 if $self->_opts->{dump};
    my $title            = $self->_get_pod->find_title;
    my $name_and_summary = [ split /\s*-\s*/, $title, 2 ];

    # Cache it in-memory.
    $self->_cache_name_and_summary( $name_and_summary );

    # Flag that disk cache should be stored later.
    $self->_dirty_cache( 1 );

    $name_and_summary;
}

sub _get_version {
    my ( $self ) = @_;

    # Use in-memory cache if present.
    my $version_cache = $self->_cache_version;
    return $version_cache if $version_cache;

    # Use disk cache if present.
    my $disk_cache = $self->retrieve_cache;
    if ( $disk_cache and $disk_cache->{version} ) {
        $self->_cache_version( $disk_cache->{version} );
        return $disk_cache->{version};
    }

    # Otherwise, get the package/class version.
    my $class = $self->_class;

    # TODO: Be able to get class from path
    if ( not $self->_get_pod->class_is_path ) {
        eval "require $class";
    }
    my $version = $class->VERSION // '';

    # Cache it in-memory.
    $self->_cache_version( $version );

    # Flag that disk cache should be stored later.
    $self->_dirty_cache( 1 );

    $version;
}

=head2 show_header

Prints a generic header for a module.

=cut

sub show_header {
    my ( $self )      = @_;
    my $class         = $self->_class;
    my $version       = $self->_get_version;
    my $class_is_path = $self->_get_pod->class_is_path;
    my $first_release =
      $class_is_path ? "" : Module::CoreList->first_release( $class );

    my @package_line = (
        _grey( "Package:" ),
        sprintf(
            "%s%s%s",
            _yellow( $class_is_path ? ""                    : $class ),
            ( $version              ? _green( " $version" ) : "" ),
            (
                $first_release
                ? _grey( " (since perl " )
                  . _green( $first_release )
                  . _grey( ")" )
                : ""
            ),
        ),
    );
    my @path_line = ( _grey( "Path:" ), _grey( $self->_get_path ), );

    my $max    = max map { length } $package_line[0], $path_line[0];
    my $format = "%-${max}s %s";

    say "";
    _sayt sprintf( $format, @package_line );
    _sayt sprintf( $format, @path_line );

    say "";
    my ( $name, $summary ) = $self->_get_name_and_summary->@*;
    return unless $name and $summary;

    _sayt _yellow( $name ) . " - " . _green( $summary );
    say _reset( "" );
}

# Inheritance

sub _get_isa {
    my ( $self ) = @_;

    # Use in-memory cache if present.
    my $isa_cache = $self->_cache_isa;
    return $isa_cache if $isa_cache;

    # Use disk cache if present.
    my $disk_cache = $self->retrieve_cache;
    if ( $disk_cache and $disk_cache->{isa} ) {
        $self->_cache_isa( $disk_cache->{isa} );
        return $disk_cache->{isa};
    }

    # Otherwise, get all class inheritance.
    my @classes = ( $self->_class );
    my @isa;
    my %seen;

    # TODO: Be able to get class from path
    if ( not $self->_get_pod->class_is_path ) {
        no strict 'refs';
        while ( my $class = shift @classes ) {
            next if $seen{$class}++;    # Already saw it
            push @isa, $class;          # Add to list.
            eval "require $class";
            push @classes, @{"${class}::ISA"};
        }
    }

    # Cache it in-memory.
    $self->_cache_isa( \@isa );

    # Flag that disk cache should be stored later.
    $self->_dirty_cache( 1 );

    \@isa;
}

=head2 show_inheritance

Show the Inheritance chain of a class/module.

=cut

sub show_inheritance {
    my ( $self ) = @_;
    my $isa      = $self->_get_isa;
    my $size     = @$isa;
    return if $size <= 1;
    say _neon( "Inheritance ($size):" );
    say _grey( " $_" ) for @$isa;
    say _reset( "" );
}

# Events

sub _get_events {
    my ( $self ) = @_;

    # Use in-memory cache if present.
    my $mem_cache = $self->_cache_events;
    return $mem_cache if $mem_cache;

    # Use disk cache if present.
    my $disk_cache = $self->retrieve_cache;
    if ( $disk_cache and $disk_cache->{events} ) {
        $self->_cache_events( $disk_cache->{events} );
        return $disk_cache->{events};
    }

    # Otherwise, get all class events.
    local $Pod::Query::DEBUG_FIND_DUMP = 1 if $self->_opts->{dump};
    my %events = $self->_get_pod->find_events;

    # Cache it in-memory.
    $self->_cache_events( \%events );

    # Flag that disk cache should be stored later.
    $self->_dirty_cache( 1 );

    \%events;
}

sub _get_event_names {
    my ( $self ) = @_;
    sort keys $self->_get_events->%*;
}

=head2 show_events

Show any declared class events.

=cut

sub show_events {
    my ( $self ) = @_;
    my $events   = $self->_get_events;
    my @names    = sort keys %$events;
    my $size     = @names;
    return unless $size;

    my $len    = max map { length( _green( $_ ) ) } @names;
    my $format = " %-${len}s - %s";

    say _neon( "Events ($size):" );
    for ( @names ) {
        _sayt sprintf $format, _green( $_ ), _grey( $events->{$_} );
    }
    say _reset( "" );
}

# Methods

sub _get_methods {
    my ( $self ) = @_;

    # Use in-memory cache if present.
    my $mem_cache = $self->_cache_methods;
    return $mem_cache if $mem_cache;

    # Use disk cache if present.
    my $disk_cache = $self->retrieve_cache;
    if ( $disk_cache and $disk_cache->{methods} ) {
        $self->_cache_methods( $disk_cache->{methods} );
        return $disk_cache->{methods};
    }

    # Otherwise, get all class methods.
    local $Pod::Query::DEBUG_FIND_DUMP = 1 if $self->_opts->{dump};
    my $pod = $self->_get_pod;
    my @method_names;

    # The provided class is really the path.
    {
        local *_PodHelper;
        if ( $pod->class_is_path ) {
            @method_names = $pod->find( "head2" );
        }
        elsif ( $self->_import_class ) {
            @method_names =
              sort { $a cmp $b }
              uniq get_full_functions( "_PodHelper" ),  # ojo would import here.
              get_full_functions( $self->_class );      # All else here

            # TODO: figure out why "local *_Pod" does
            # not remove the typeglob at the end.
            # Also "undef *_Pod" does nothing.
            delete @_PodHelper::{ keys %_PodHelper:: };
        }
    }

    my @methods =
      map { [ $_, scalar $pod->find_method_summary( $_ ) ] } @method_names;

    # Cache it in-memory.
    $self->_cache_methods( \@methods );

    # Flag that disk cache should be stored later.
    $self->_dirty_cache( 1 );

    \@methods;
}

sub _import_class {
    my ( $self ) = @_;
    my $class = $self->_class;

    # Try not to pollute main.
    # ojo imports its DSL into the current package by default.
    eval { eval "package _PodHelper; use $class"; };

    my $import_ok = do {
        if ( $@ ) { warn $@; 0 }
        else      { 1 }
    };

    $import_ok;
}

sub _get_method_names {
    my ( $self ) = @_;
    my $methods = $self->_get_methods;

    my @names =
      grep { / ^ [\w_-]+ $ /x }     # Normal looking names.
      map { $_->[0] } @$methods;
}

=head2 show_methods

Show all class methods.

=cut

sub show_methods {
    my ( $self ) = @_;

    my $all_method_names_and_docs = $self->_get_methods;    # 0: name, 1: doc.

    # Skip some methods unless using --all flag.
    my %skip_methods =
      map { $_ => 1 }
      qw(
      BEGIN
      VERSION
      ISA
      __ANON__
      );

    if ( not $self->_opts->{all} ) {
        @$all_method_names_and_docs =
          grep { not $skip_methods{ $_->[0] } } @$all_method_names_and_docs;
    }

    # Documented methods
    my @all_method_docs = grep { $_->[1] } @$all_method_names_and_docs;

    # If we have methods, but none are documented (or found).
    if ( @$all_method_names_and_docs and not @all_method_docs ) {
        say _grey(
            "Warning: All methods are undocumented! (reverting to --all)\n" );
        $self->_opts->{all} = 1;
    }

    my @methods =
      $self->_opts->{all} ? @$all_method_names_and_docs : @all_method_docs;
    my $max              = max 0, map { length _green( $_->[0] ) } @methods;
    my $format_with_desc = " %-${max}s%s";
    my $format_no_desc   = " %s%s";
    my $size             = @methods;
    say _neon( "Methods ($size):" );

    for my $list ( @methods ) {
        my ( $method, $doc_raw ) = @$list;
        my $doc = $doc_raw ? " - $doc_raw" : "";
        $doc =~ s/\n+/ /g;

        my $format = $doc_raw ? $format_with_desc : $format_no_desc;
        _sayt sprintf $format, _green( $method ), _grey( $doc );
    }

    say _grey( "\nUse --all (or -a) to see all methods." )
      unless $self->_opts->{all};
    say _reset( "" );
}

=head2 show_method_doc

Show documentation for a specific module method.

=cut

sub show_method_doc {
    my ( $self ) = @_;

    local $Pod::Query::DEBUG_FIND_DUMP = 1 if $self->_opts->{dump};
    my $doc = $self->_get_pod->find_method( $self->_method );

    # Color.
    for ( $doc ) {
        chomp;

        # Headings.
        s/ ^ \s* \K (\S+:) (?= \s* $ ) / _green($1) /xgem;

        # Comments.
        s/ (\#.+) / _grey($1) /xge;
    }

    say $doc;
    say _reset( "" );
}

#
# Caching
#

=head2 define_last_run_cache_file

Defined where to save the results from the last run.
This is done for performance reasons.

=cut

sub define_last_run_cache_file {
    my ( $self ) = @_;
    catfile( home(), ".cache", "my_pod_last_run.cache", );
}

sub _get_class_options {
    my ( $self ) = @_;

    [ sort $self->_get_event_names, $self->_get_method_names, ];
}

=head2 store_cache

Saves the last class name and its methods/options.

=cut

sub store_cache {
    my ( $self ) = @_;
    my $cache = {
        class            => $self->_class,
        path             => $self->_get_path,
        name_and_summary => $self->_get_name_and_summary,
        version          => $self->_get_version,
        isa              => $self->_get_isa,
        events           => $self->_get_events,
        methods          => $self->_get_methods,
        options          => $self->_get_class_options,
    };
    my $path = path( $self->define_last_run_cache_file );

    if ( not -e $path->dirname ) {
        mkdir $path->dirname or die $!;
    }

    $path->spurt( j $cache );

    # Reset the flag.
    $self->_dirty_cache( 0 );

    $cache;
}

=head2 retrieve_cache

Returns the last stored class cache and its options.

=cut

sub retrieve_cache {
    my ( $self ) = @_;
    my $empty = { class => "" };
    return $empty if $self->_dirty_cache;

    # Use in-memory cache if present.
    my $mem_cache = $self->_cache_from_file;
    return $mem_cache if $mem_cache;

    # Otherwise, go to the actual file.
    my $file = $self->define_last_run_cache_file;
    if ( not -e $file ) {
        $self->_dirty_cache( 1 );
        return $empty;
    }

    # Extract data from file.
    my $disk_cache = j path( $file )->slurp;

    # Wrong class.
    if ( $disk_cache->{class} ne $self->_class ) {
        $self->_dirty_cache( 1 );
        return $empty;
    }

    # Cache it locally
    $self->_cache_from_file( $disk_cache );

    $disk_cache;
}

#
# Output
#

=head2 trim

Trim a line to fit the terminal width.
Handles also escape codes within the line.

=cut

sub trim {
    my ( $line ) = @_;
    state $esc            = qr{ \033\[ [\d;]+ m    }x;
    state $data           = qr{ (?: (?!$esc) . )++ }x;
    state $data_or_escape = qr{ (?<data>$data) | (?<esc>$esc) }x;
    state $term_width     = Pod::Query::get_term_width();
    state $replacement    = " ...";
    state $width_raw      = $term_width - length( $replacement );
    state $base_width = $width_raw >= 0 ? $width_raw : 0;  # To avoid negatives.

    # Figure out the total len of the line (uncolored).
    my $total_chars = 0;
    my @detailed_line_parts;
    while ( $line =~ /$data_or_escape/g ) {
        my $part = {%+};
        $total_chars += $part->{len} = length( $part->{data} // "" );
        push @detailed_line_parts, $part;
    }

    # No need to trim.
    return $line if $total_chars <= $term_width;

    # Need to trim.
    my @parts;
    my $size_exceeded;
    my $so_far_len = 0;
    for my $part ( @detailed_line_parts ) {

        # Handle escape codes.
        if ( not $part->{len} ) {
            push @parts, $part->{esc};    # Add escapes back.
            last if $size_exceeded;       # Done.
            next;
        }

        # Handle trailing escapes.
        last if $size_exceeded;

        # Trim line if it would be too long.
        if ( $so_far_len + $part->{len} > $base_width ) {
            $size_exceeded = 1;  # Still need to possibly add a trailing escape.

            # Limit line to allowed width.
            $part->{data} = substr(
                $part->{data},
                0,
                $base_width - $so_far_len,    # How much space is left.
            ) . $replacement;
        }

        $so_far_len += $part->{len};
        push @parts, $part->{data};
    }

    join "", @parts;
}

sub _sayt {

    say trim( @_ );
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

sub _reset {

    colored( "@_", "RESET" );
}

#
# Misc Support
#

sub uniq(@) {
    my %h;
    grep { not $h{$_}++ } @_;
}

#
# Legacy
#

=for Legacy
-
- # pod version 0
-
- package UNIVERSAL;
-
- sub dir{
-    my ($s)   = @_;               # class or object
-    my $ref   = ref $s;
-    my $class = $ref ? $ref : $s; # myClass
-    my $pkg   = $class . "::";    # MyClass::
-    my @keys_raw;
-    my $is_special_block = qr/^ (?:BEGIN|UNITCHECK|INIT|CHECK|END|import|DESTROY) $/x;
-
-    no strict 'refs';
-
-    while( my($key,$stash) = each %$pkg){
- #     next if $key =~ /$is_special_block/;   # Not a special block
- #     next if $key =~ /^ _ /x;               # Not private method
-       next if ref $stash;                    # Stash name should not be a reference
-       next if not defined *$stash{CODE};     # Stash function should be defined
-       push @keys_raw, $key;
-    }
-
-    my @keys = sort @keys_raw;
-
-    return @keys if defined wantarray;
-
-    say join "\n  ", "\n$class", @keys;
- }

=head1 ENVIRONMENT

Install bash completion support.

 % apt install bash-completion

Install tab completion.

 % source bash_completion_pod

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
