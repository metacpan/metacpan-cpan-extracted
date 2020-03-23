package CLI::Driver;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use YAML::Tiny;
use CLI::Driver::Action;

with 'CLI::Driver::CommonRole';

our $VERSION = 0.50;

=head1 NAME

CLI::Driver

=cut

=head1 SYNOPSIS

This is a module to drive your cli tool from a yaml config file.

    use CLI::Driver;
    
    my $cli = CLI::Driver->new;
    
    my $action = $cli->get_action( name => $ActionFromArgv );
    if ($action) {
        $action->do;
    }
    else {
        $Driver->fatal("failed to find action in config file");
    }

	### cli-driver.yml example
	
	do-something:
      class:
        name: My::App
        attr:
          required:
            hard:
              f: foo
            soft:
              h: home
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
=cut

##############################################################################
### CONSTANTS
##############################################################################

use constant DEFAULT_CLI_DRIVER_PATH => ( '.', 'etc', '/etc' );
use constant DEFAULT_CLI_DRIVER_FILE => 'cli-driver.yml';

##############################################################################
### REQUIRED ATTRIBUTES
##############################################################################

##############################################################################
### OPTIONAL ATTRIBUTES
##############################################################################

has path => (
	is      => 'rw',
	isa     => 'Str',
);

has file => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	builder => '_build_file'
);

##############################################################################
### ACCESSOR ATTRIBUTES
##############################################################################

has actions => (
	is      => 'rw',
	isa     => 'ArrayRef[CLI::Driver::Action]',
	lazy    => 1,
	builder => '_build_actions',
);

##############################################################################
### PRIVATE ATTRIBUTES
##############################################################################

has _orig_argv => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub {[ @ARGV ]}
);

##############################################################################
### PUBLIC METHODS
##############################################################################

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

##############################################################################
### PRIVATE METHODS
##############################################################################

method _find_file {

	my @path;
	if ($self->path) {
		push @path, split(/:/, $self->path);
	}
	
	push @path, DEFAULT_CLI_DRIVER_PATH;

	foreach my $path (@path) {
		my $fullpath = sprintf "%s/%s", $path, $self->file;
		if ( -f $fullpath ) {
			return $fullpath;
		}
	}

	my $msg = sprintf "unable to find %s in: %s", $self->file,
	  join( ', ', @path );
	confess $msg;
}

method _build_actions {

	my @actions;

	my $driver_file = $self->_find_file;
	my $actions = $self->_parse_yaml( path => $driver_file );

	foreach my $action_name ( keys %$actions ) {

		my $action = CLI::Driver::Action->new( name => $action_name );
		my $success = $action->parse( href => $actions->{$action_name} );
		if ($success) {
			push @actions, $action;
		}
	}

	return \@actions;
}

method _parse_yaml (Str :$path!) {

	my $actions;
	eval {
		my $yaml = YAML::Tiny->read($path);
		$actions = $yaml->[0];
	};
	confess $@ if $@;

	return $actions;
}

method _build_file {

	if ( $ENV{CLI_DRIVER_FILE} ) {
		return $ENV{CLI_DRIVER_FILE};
	}

	return DEFAULT_CLI_DRIVER_FILE;
}

1;
