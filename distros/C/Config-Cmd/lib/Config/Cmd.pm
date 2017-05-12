package Config::Cmd;
use Mo qw(default);
use YAML qw'DumpFile LoadFile';
use Modern::Perl;
use Carp;

# ABSTRACT: Command line to config file two way interface
our $VERSION = '0.002'; # VERSION

use constant EXT => '_conf.yaml';

has section => ();
has filename => ();
has quote => ( default => sub { q(') } );

sub set {
    my $self = shift;
    my $args = shift;

    say STDERR "# writing into ". $self->_set_file;
    say STDERR "# options: ". "@$args";

    $self->set_silent($args);
}

sub set_silent {
    my $self = shift;
    my $args = shift;

    # process arguments
    my $section = $self->section;
    croak "Set section before writing into a file" unless $section;
    my $config->{$section} = [];

    my $key = '';
    while (my $e = shift @$args) {
	if ($e eq '=') {
	    next;
	}
	elsif ($e =~ /(-.+)=(.+)/) {
	    if ($key) {
		my $tuple->{key} = $key ;
		push @{$config->{$section}}, $tuple;
		$key = '';
	    }
	    my $tuple->{key} = $1 ;
	    $tuple->{value} = $2 ;
	    push @{$config->{$section}}, $tuple;
	}
	elsif ($e =~ /^-/) {
	    if ($key) {
		my $tuple->{key} = $key ;
		push @{$config->{$section}}, $tuple;
	    }
	    $key = $e;
	} else {
	    if ($key) {
		my $tuple->{key} = $key ;
		$tuple->{value} = $e ;
		push @{$config->{$section}}, $tuple;
	    }
	    $key = '';
	}

    }
    if ($key) {
	my $tuple->{key} = $key;
	push @{$config->{$section}}, $tuple;
    }

    DumpFile $self->_set_file, $config;
}

sub get {
    my $self = shift;
    my $section = $self->section;

    my $config = LoadFile($self->_get_file);

    my @list;
    for my $tuple (@{$config->{$section}}) {
	if (defined $tuple->{value}) {
	    my $value = $tuple->{value};
	    $value = $self->quote. $value. $self->quote if  $value =~ /\s/;
	    push @list, $tuple->{key}, $value;
	} else {
	    push @list, $tuple->{key};
	}
    }
    return join ' ', @list;
}

# internal methods

sub _default_filename {
    return shift->section. EXT;
}

sub _set_file {
    my $self = shift;

    return $self->filename if defined $self->filename;
    return $self->_default_filename if $self->section;
    return; # if no matching files were found
}


sub _get_file {
    my $self = shift;

    return $self->filename if defined $self->filename;
    if (-e $self->_default_filename) {
	return $self->_default_filename;
    } elsif (-e $ENV{HOME}. '.'. $self->_default_filename) {  #check home directory
	return $ENV{HOME}. '.'. $self->_default_filename;
    }
    return; # if no matching files were found
}

1;

__END__

=pod

=head1 NAME

Config::Cmd - Command line to config file two way interface

=head1 VERSION

version 0.002

=head1 SYNOPSIS

   # user writes options in a file;
   configcmd parallel -j 8 --verbose
   # stored in ./parallel_conf.yaml

   # same functionality when using the module directly
   use Config::Cmd;
   my $conf = Config::Cmd(section => 'parallel');
   $conf->set('-j 8 --verbose');

   # main application uses the options
   use Config::Cmd;
   my $conf = Config::Cmd(section => 'parallel');
   my $parallel_opts = $conf->get;  # read from ./parallel_conf.yaml
   # call external program
   `$exe $parallel_opts @args`;

=head1 DESCRIPTION

This module makes it easy to take a set of command line options, store
them into a config file, and read them later in for passing to an
external program. Part of this distribution is a command line program
L<configcmd> for writing these options into a file. The main
application can then use this module to automate reading of these
options and passing them on.

The options stored by Command::Cmd and its command line tool use
single quotes around options with white space, but that can be changed
to double quotes if needed by using method L<quote>. Usually you will
want stick with single quotes.

=head2 Finding the configuration files

The command line program writes into the working directory. The
default filename is the section name appended with string
'_conf.yaml'. This file can be moved and renamed.

The method L<filename> can be used to set the path where the file is
found. This overrides all other potential places. If the filename has
not been set, the module uses the section name to find the
configuration file from the working directory (./[section]_conf.yaml).
If that file is not found, it looks into user's home directory for a
file ~/.[section]_conf.yaml.

=head1 METHODS

=head2 section

The obligatory section name for the stored configuration. This string,
typically a program name, defines the name of the config file.

=head2 filename

Override method that allows user to determine the filename where a
config is to be written or read.

=head2 set

Store the command line into a file as YAML. Returns true value on
success.

=head2 set_silent

Same as set() but does not report to STDERR.

=head2 get

Get the command line options stored in the file as a string.

=head2 quote

The quote character to put around a string with white spaces by method
L<get>. Defaults to single quote to make it possible to use double
quotes for the whole string. Can be set to any string but you would
foolish to set to anything else than single or double quote character.

=head1 SEE ALSO

L<configcmd>, L<Config::Auto>

=head1 AUTHOR

Heikki Lehvaslaiho <heikki.lehvaslaiho@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Heikki Lehvaslaiho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
