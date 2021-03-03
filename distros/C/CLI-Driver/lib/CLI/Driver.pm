package CLI::Driver;

=head1 NAME

CLI::Driver - Drive your cli tool with YAML

=cut

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka 'method';
use Data::Printer alias => 'pdump';
use CLI::Driver::Action;
use Module::Load;

use Getopt::Long;
Getopt::Long::Configure('no_ignore_case');
Getopt::Long::Configure('pass_through');
Getopt::Long::Configure('no_auto_abbrev');

use YAML::Syck;

with 'CLI::Driver::CommonRole';

our $VERSION = 0.77;

=head1 SYNOPSIS

  use CLI::Driver;
   
  my $cli = CLI::Driver->new;
  $cli->run;

  - or - 
   
  my $cli = CLI::Driver->new(
      path => './etc:/etc',
      file => 'myconfig.yml'
  );
  $cli->run;
    
  - or - 

  my $cli = CLI::Driver->new(
      use_file_sharedir => 1,
      file_sharedir_dist_name => 'CLI-Driver',
  );
  $cli->run;
                       
  #################################
  # cli-driver.yml example
  ################################# 
  do-something:
    desc: "Action description"
    deprecated:
      status: false
      replaced-by: na
    class:
      name: My::App
      attr:
        required:
          hard:
            f: foo
          soft:
            h: home
            a: '@array_arg'
        optional:
        flags:
          dry-run: dry_run_flag
    method:
      name: my_method
      args:
        required: 
          hard: 
          soft:
        optional:
        flags:
    help:
     args:
        f: "Additional help info for argument 'f'"
     examples:
        - "-f foo -a val1 -a val2 --dry-run"
          
=cut

##############################################################################
### CONSTANTS
##############################################################################

use constant DEFAULT_CLI_DRIVER_PATH => ( '.', 'etc', '/etc' );
use constant DEFAULT_CLI_DRIVER_FILE => 'cli-driver.yml';

##############################################################################
### ATTRIBUTES
##############################################################################

=head1 ATTRIBUTES

=head2 path

Directory where your cli-driver.yml file is located.  You can specify
multiple directories by separating them with ':'.  For example, 
"etc:/etc".

isa: Str

defaults:  .:etc:/etc

=cut

has path => (
    is  => 'rw',
    isa => 'Str',
);

=head2 file

Name of your YAML driver file.

isa: Str

default: cli-driver.yml

=cut

has file => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_file'
);

=head2 use_file_sharedir

Flag indicating you want to use File::ShareDir to locate the driver file.
Requires the attribute 'file_sharedir_dist_name' to be provided.  Is mutually
exclusive with the 'path' attribute.

isa: Bool

default: 0

=cut

has use_file_sharedir => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

=head2 file_sharedir_dist_name

Your distro name.  For example: 'CLI-Driver'.

isa: Str

default: undef

=cut

has file_sharedir_dist_name => (
    is  => 'ro',
    isa => 'Str',
);

=head2 argv_map

A set of command line overrides for retrieving arguments.  This can be used
in-place of @ARGV args.

Example: 

  {
     classAttrName1 => 'abc',
     classAttrName2 => 'def',
     methodArgName1	=> 'ghi'
  }

isa: HashRef

default: undef

=cut

# notice the cli switches are not part of the map.
has argv_map => (
    is        => 'rw',
    isa       => 'HashRef',
    predicate => 'has_argv_map',
    writer    => '_set_argv_map',
);

=head2 actions

A list of actions parsed from the driver file.

isa: ArrayRef[CLI::Driver::Action]

=cut

has actions => (
    is      => 'rw',
    isa     => 'ArrayRef[CLI::Driver::Action]',
    lazy    => 1,
    builder => '_build_actions',
);

##############################################################################
### PUBLIC METHODS
##############################################################################

method BUILD (@argv) {

    if ( $self->has_argv_map ) {
        $self->_build_global_argv_map( $self->argv_map );
    }
}

method set_argv_map (HashRef $argv_map) {

    $self->_set_argv_map( {%$argv_map} );
    $self->_build_global_argv_map( $self->argv_map );
}

method get_action (Str :$name!) {

    my $actions = $self->get_actions;

    foreach my $action (@$actions) {
        if ( $action->name eq $name ) {
            return $action;
        }
    }
}

method get_actions (Bool :$want_hashref = 0) {

    my @ret = @{ $self->actions };

    if ($want_hashref) {

        my %actions;
        foreach my $action (@ret) {
            my $name = $action->name;
            next if $name =~ /dummy/i;
            $actions{$name} = $action;
        }

        return \%actions;
    }

    return \@ret;
}

method run {

    my $action = $self->parse_cmd_line();
    if ($action) {
        $action->do;
    }
    else {
        $self->fatal("failed to find action in config file");
    }
}

method parse_cmd_line {

    my $help;
    my $action_name;
    my $dump;

    GetOptions(    #
        "dump"   => \$dump,
        "help|?" => \$help
    );
    
    if ( !@ARGV ) {
        $self->usage;
    }
    elsif (@ARGV) {
        $action_name = shift @ARGV;
    }

    my $action;
    if ($action_name) {
        $action = $self->get_action( name => $action_name );
        
        if ($dump) {
            say $action->to_yaml;
            exit;                
        }
    }

    if ($help) {
        if ($action) {
            $action->usage;
        }
        else {
            $self->usage;
        }
    }

    return $action;
}

method usage (Str $errmsg?) {

    print STDERR "$errmsg\n" if $errmsg;
    print "\nusage: $0 <action> [opts] [-?] [--dump]\n\n";

    my @list;
    my $actions = $self->get_actions;

    foreach my $action (@$actions) {

        next if $action->name =~ /dummy/i;

        my @display;
        push @display, $action->name;

        if ( $action->is_deprecated ) {
            my $depr = $action->deprecated;
            push @display, sprintf '(%s)', $depr->get_usage_modifier;
        }

        push @list, join( ' ', @display );
    }

    say "\tACTIONS:";

    foreach my $action ( sort @list ) {
        print "\t\t$action\n";
    }

    print "\n";
    exit 1;
}

##############################################################################
### PRIVATE METHODS
##############################################################################

method _find_file {

    my @search_dirs;

    if ( $self->use_file_sharedir ) {

        my $dist_name = $self->file_sharedir_dist_name;
        if ( !$dist_name ) {
            confess "must provide file_sharedir_dist_name "
              . "when use_file_sharedir is true";
        }

        load 'File::ShareDir';

        @search_dirs = ('./share');
        push @search_dirs, File::ShareDir::dist_dir($dist_name);
    }
    else {

        if ( $self->path ) {
            push @search_dirs, split( /:/, $self->path );
        }

        push @search_dirs, DEFAULT_CLI_DRIVER_PATH;
    }

    foreach my $path (@search_dirs) {
        my $fullpath = sprintf "%s/%s", $path, $self->file;
        if ( -f $fullpath ) {
            return $fullpath;
        }
    }

    my $msg = sprintf "unable to find %s in: %s", $self->file,
      join( ', ', @search_dirs );
    confess $msg;
}

method _build_actions {

    my @actions;

    my $driver_file = $self->_find_file;
    my $actions     = $self->_parse_yaml( path => $driver_file );

    foreach my $action_name ( keys %$actions ) {

        my $action = CLI::Driver::Action->new(
            href         => $actions->{$action_name},
            name         => $action_name,
            use_argv_map => $self->has_argv_map ? 1 : 0
        );

        my $success = $action->parse;
        if ($success) {
            push @actions, $action;
        }
    }

    return \@actions;
}

method _parse_yaml (Str :$path!) {

    my $href;
    eval {
        $href = YAML::Syck::LoadFile($path);
    };
    confess $@ if $@;
    
    return $href;
}

method _build_file {

    if ( $ENV{CLI_DRIVER_FILE} ) {
        return $ENV{CLI_DRIVER_FILE};
    }

    return DEFAULT_CLI_DRIVER_FILE;
}

method _build_global_argv_map (HashRef $argv_map) {

    %ARGV = ();

    foreach my $key ( keys %$argv_map ) {
        $ARGV{$key} = $argv_map->{$key};
    }
}

__PACKAGE__->meta->make_immutable;

1;
