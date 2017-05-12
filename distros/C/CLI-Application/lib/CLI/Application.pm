
package CLI::Application;

use strict;
use warnings;


use Carp;

use Text::Table;

use Attribute::Handlers;

use Module::Pluggable;
use Module::Load;


our $VERSION = '0.03';

our %ACTION;
our $FALLBACK;
our $AUTOLOAD;


sub new {
	my ($class, %rc) = @_;
	return bless \%rc, $class;
}


# Take a list of command line arguments and prepare the application for
# execution by parsing options, detecting the action to perform, loading
# plugins and so on.
sub prepare {
	my ($self, @argv) = @_;

	my $wanted = $self->{options} || [];
	my @rest;
	my %option;
	my $class = ref $self;

	# Get list of available plugins.
	my %plugin = map { $_ => 0 } $self->plugins;

	$self->{plugged} = {};

	# Load plugins.
	if($self->{plugins}) {
		while(my ($plugin, $param) = each %{$self->{plugins}}) {
			my $package = $class . '::Plugin';

			# Allow leaving 'CLI::Application::Plugin::' away.
			if($plugin !~ /^$package/) {
				$plugin = $class . '::Plugin::' . $plugin;
			}

			die "Plugin $plugin not found.\n" unless exists($plugin{$plugin});

			load $plugin;

			my $instance = $plugin->new(%$param);

			# Assign the instance of the plugin to each exported method.
			$self->{plugged}->{$_} = $instance for($plugin->export);
		}
	}


	# Parse options from command line arguments.
	while(my $arg = shift(@argv)) {

		# Save non-option arguments.
		if($arg =~ /^[^-]/) {
			push @rest, $arg;
		}

		# Save everything after '--'.
		elsif($arg eq '--') {
			push @rest, @argv;
			last;
		}

		# Get long options.
		elsif($arg =~ /^--(.+?)(?:=(.*))?$/) {
			my ($key, $value) = ($1, $2);
			my $option = $self->_option($key);

			if($option->[2]) {
				$value = shift @argv unless defined $value;

				die $self->usage("Missing argument for option --$key.")
					unless defined $value;

				if(!$self->_validate_option($option->[2], $value)) {
					my $error = "Wrong argument for option --$key.";
					$error .= ' ' . $option->[3] if($option->[3]);
					die $self->usage($error);
				}

				$option{$_} = $value for(@{$option->[0]});
			}
			else {
				$option{$_} = !0 for(@{$option->[0]});
			}
		}

		# Get short options.
		elsif($arg =~ /^-([^-].*)$/) {
			my $all = $1;

			while($all) {
				$all =~ s/^(.)//;
				my $key = $1;

				my $option = $self->_option($key);
				
				if($option->[2]) {
					if($all) {
						$option{$_} = $all for(@{$option->[0]});
						last;
					}
					else {
						my $value = shift @argv;

						die $self->usage("Missing argument for option -$key.")
							unless(defined $value);

						if(!$self->_validate_option($option->[2], $value)) {
							my $error = "Wrong argument for option -$key.";
							$error .= ' ' . $option->[3] if($option->[3]);
							die $self->usage($error);
						}

						$option{$_} = $value for(@{$option->[0]});
					}
				}
				else {
					$option{$_} = !0 for(@{$option->[0]});
				}
			}
		}

		else {
			die "Don't know what to do with '$arg'.\n";
		}
	}

	$self->{parsed} = \%option;
	$self->{rest} = \@rest;

	delete $self->{action};
}


# Take an error message and print it together with our usage information.
sub usage {
	my ($self, @message) = @_;

	my $usage = $self->_usage;

	local $" = ' ';
	$usage = "@message\n\n$usage" if @message;

	return $usage . "\n";
}


# Return (and set) the action we're going to dispatch to.
sub action {
	my ($self, $action) = @_;

	if(defined $action and !$ACTION{$action}) {
		die "Unknown action '$action'.\n";
	}

	if(defined $action) {
		$self->{action} = $action;
	}
	elsif(!$self->{action}) {
		# Get command from remaining arguments or take default action.
		my $command = (shift @{$self->{rest}}) || $FALLBACK;

		die $self->usage("No action.") unless $command;

		if($ACTION{$command}) {
			$self->{action} = $command;
		}
		else {
			die $self->usage("No such command.");
		}
	}

	return $self->{action};
}


# Return (and set) the value of an option.
sub option {
	my ($self, $option, $argument) = @_;

	if(@_ == 3) {
		$self->{parsed}->{$option} = $argument;
	}

	return $self->{parsed}->{$option};
}


# Dispatch to the given action or the action parsed from command line
# arguments.
sub dispatch {
	my ($self, $action) = @_;

	$action ||= $self->action || $FALLBACK;

	my $code = $ACTION{$action}->{code};

	return &{$code}($self) if($code);

	die "Nothing to do.\n";
}


# Return the applications name.
sub name { $_[0]->{name} }


# Return anything from the command line that's left after parsing options and
# commands.
sub arguments { return @{$_[0]->{rest}} }


# Generate a help message with all valid commands and options and return it.
sub _usage {
	my ($self) = @_;

	my $usage = "Usage: $0 [options] <action>\n";

	if(%ACTION) {
		my $table = new Text::Table;

		while(my ($name, $hash) = each %ACTION) {
			$table->add("\t" . $name, '-- ' . $hash->{text});
		}

		$usage .= "\nACTIONS\n" . $table->table . "\n";
	}

	my $options = $self->_option_usage;
	$usage .= "\nOPTIONS\n$options\n" if($options);

	return $usage;
}


# Return a formatted table of valid options using Text::Table.
sub _option_usage {
	my ($self) = @_;

	if($self->{options} and @{$self->{options}}) {
		my $table = new Text::Table;

		for my $option (@{$self->{options}}) {
			my ($flags, $description, $validate) = @{$option};

			my @aliases;

			for my $flag (@{$flags}) {
				push @aliases, (length($flag) < 2 ? '-' : '--') . $flag;
			}

			$flags = join(' | ', @aliases);

			if($validate) {
				if(ref($validate)) {
					if(ref($validate) eq 'ARRAY') {
						$validate = '[' . join(' | ', @{$validate}) . ']';
					}
					else {
						$validate = '<...>';
					}
				}

				$flags .= ' ' . $validate;
			}

			$description ||= "Don't know what this option is good for.";

			$table->add(
				$flags,
				' -- ' . $description,
			);
		}

		return $table->table;
	}

	return '';
}


# Searches the options array for an option matching the given string and
# returns the first option that has a matching option flag.
sub _option {
	my ($self, $needle) = @_;

	my $list = $self->{options} || [];

	for my $option (@$list) {
		return $option if grep { $_ eq $needle } @{$option->[0]};
	}

	die $self->usage("Unknown option '$needle'.\n");
}


# Take an option from the arguments hash and a value from the command line,
# check if the value is vaid for the option.
sub _validate_option {
	my ($self, $validate, $value) = @_;

	if(ref($validate)) {
		my $type = uc ref $validate;

		if($type eq 'ARRAY') {
			return grep { $_ eq $value } @{$validate};
		}

		elsif($type eq 'REGEXP' or $type eq 'SCALAR') {
			$validate = qr/${$validate}/ if($type eq 'SCALAR');

			return $value =~ $validate;
		}

		elsif($type eq 'HASH') {
			# Don't know what to do with hashes yet.
		}

		elsif($type eq 'CODE') {
			return &{$validate}($value);
		}
	}

	return !0;
}


# Attribute to mark functions as commands.
sub UNIVERSAL::Command : ATTR(CODE) {
	my ($package, $symbol, $code, $attribute, $data, $phase) = @_;

	$ACTION{*{$symbol}{NAME}} = {
		code => $code,
		text => ref($data)
			? $data->[0]
			: 'I have no idea what this action does.',
	};
}


# Attribute to mark a default command.
sub UNIVERSAL::Fallback : ATTR(CODE) {
	my ($package, $symbol, $code, $attribute, $data, $phase) = @_;

	$FALLBACK = *{$symbol}{NAME};
}


# AUTOLOAD method to call plugin methods.
sub AUTOLOAD {
	my $self = shift;

	my ($method) = (split /::/, $AUTOLOAD)[-1];
	my $module = $self->{plugged}->{$method};

	croak "Unknown method '$method' in ", ref($self) unless $module;

	return $module->$method($self, @_);
}


sub DESTROY {
	my ($self) = @_;

	delete $self->{plugged};
}


!0;

__END__

=head1 NAME

CLI::Application - (not yet) extensible CLI application framework

=head1 SYNOPSIS

	use CLI::Application;

	my $app = new CLI::Application(
		name => 'test',
		version => '0.01',
		options => [
			[ [ qw( t test ) ], 'Test option.' ],
			[ [ qw( a any ) ], 'Option with any argument.', 1 ],
			[ [ qw( f foobar ) ], 'Option with argument foo or bar.', [qw(foo bar)] ],
		],
		plugins => [ qw( RC::YAML ) ],
	);

	sub list : Command('Show list of items.') : Fallback {
		my ($app) = @_;
		# list items ...
	}

	sub add : Command('Add item.') {
		my ($app) = @_;
		print "TEST!\n" if($options->{test});
		# add item
		add_item($app->arguments);
	}

	sub remove : Command('Remove item.') {
		my ($app) = @_;
		my $any = $app->option('any');
		for my $item_id ($app->arguments) {
			remove_item($item_id);
		}
	}

=head1 DESCRIPTION

B<CLI::Application> is another framework for writing command line applications.
It provides automatic parsing of and validating of command line options,
generating of usage texts based on your option definitions and dispatching to
commands based on code attributes, similar to Catalyst. In future, support for
plugins will be added, so additional functionality can be imported easily.

=head1 METHODS

=over 4

=item B<new>(application setup hash)

The constructor takes a hash with all the data the framework needs to get your
application started. The contents are explained below.

=over 4

=item B<name>

The name of your application

=item B<version>

The version of your application

=item B<options>

A list of the options your application understands. Each option is an array of
two to four elements. The first element is another array of strings which are
used as the option names. Single character strings will be used as short
options (like '-f'), longer strings will be long arguments (e.g. '--file').
It's a good idea to always provide both, but that's up to you. If more than one
string is given and the option is set on command line, the option is available
to you (using the B<option> method) with any of the strings. The second element
is a short description of your option. This will be used automatically
generated usage and help texts. The third argument is optional. If it is true,
B<CLI::Application> will expect the option to have an argument and will die
with a usage message if it is missing. If the value is just a true scalar, any
argument is allowed. If it is a regular expression, that expression will be
applied on the argument, and the argument is considered invalid if the
expression doesn't match. If the value is an array reference, the argument must
be one of the referenced arrays elements to be valid. If the value is a code
reference, the referenced code will be called with the argument as argument,
and it should return a boolean to indicate if the argument is valid or not.  If
the fourth element of the option array is given and the argument of the option
is invalid, the value will be added to the error message printed to the user.

=item B<plugins>

Names of plugins to load. See L<CLI::Application::Plugin> to learn how to
write/use plugins.

=back

=item B<prepare>(arguments)

Prepare the application for runtime. The argument will typically be B<@ARGV>,
but may be any list of values. The elements of this list will be used for
parsing options and arguments and detecting the command to later.

=item B<dispatch>(command)

Dispatch to a command. If no command is given as argument, the action will be
taken from the argument list given to the B<prepare> method. If no action is
found, the fallback command will be called, if available. If this fails too,
B<CLI::Application> will die with an error.

=item B<option>(option, argument)

This is the getter/setter for options.

=item B<arguments>

Returns a list of arguments.

=item B<action>(action)

Getter/setter for the command that B<CLI::Application> is going to execute. Use
this after a call to B<prepare> to find out what B<CLI::Application> thinks is
the action the user wants to execute, or to overwrite it. See B<dispatch>.

=item B<name>

Returns the application name.

=item B<usage>(message)

Return a usage text containing action and option descriptions. Any arguments will
be prepended.

=back

=head1 COMMANDS

Commands are simple functions that have the 'Command' label. That label
may/should have a string as argument that describes the action in short. That
text will be used in the usage text. Command functions will be called with the
B<CLI::Application> object as argument, so you can get options and arguments
from it in the function.

The command to execute is determined from the command line arguments given to
B<prepare>. The first argument that is not an option or option argument will be
used as the name of the command to execute. If there is no function with the
name and with the Command label, B<CLI::Application> will die with an error.
If no non-option argument is found, the function with the label 'Fallback' will
be used, if found. Only one function should have that label, otherwise the last
function labeled with 'Fallback' will be used (in order of definition).

	# This will be called if the command argument is 'list' or if no other
	# command is found. In the second form, no other non-option arguments are
	# possible, because there would be no way to tell them apart from command
	# names.
	# $ my-app -o some-option list <more arguments>
	# $ my-app -o some-option
	sub list : Command('Print list of something.') : Fallback {
		my ($app) = @_;
		print "List goes here...\n";
	}

	# This will be called only if there is an command argument and if it equals
	# 'add'.
	# $ my-app -o some-option add <more arguments>
	sub add : Command('Add something.') {
		my ($app) = @_;
		print "Adding something...\n";
	}

=head1 TODO

=over 4

=item * Add support for plugins.

=item * Write plugin for automatic configuration file detection and parsing.

=back

=head1 BUGS

Please report bugs in the CPAN bug tracker.

=head1 COPYRIGHT

Copyright (C) 2008 by Jonas Kramer. Published under the terms of the Artistic
License 2.0.

=cut
