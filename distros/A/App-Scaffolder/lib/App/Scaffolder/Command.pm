package App::Scaffolder::Command;
{
  $App::Scaffolder::Command::VERSION = '0.002000';
}

# ABSTRACT: Base class for App::Scaffolder commands

use strict;
use warnings;

use Carp;

use App::Cmd::Setup -command;
use File::HomeDir;
use File::ShareDir;
use Path::Class::Dir;
use MRO::Compat;
use Config;

use App::Scaffolder::Template;


sub opt_spec {
	my ($class, $app) = @_;
	return (
		[ 'list|l'              => 'List the search path and the available templates' ],
		[ 'template|t=s'        => 'Name of the template that should be used' ],
		[ 'target=s'            => 'Target directory where output should go - '
			. 'defaults to current directory, but commands may override this' ],
		[ 'create-template-dir' => 'Create directory for custom user templates' ],
		[ 'overwrite'           => 'Overwrite existing files', { default => 0 }],
		[ 'quiet'               => 'Do not print the list of created files' ],
		[], ['Command-specific options:'],
		$class->get_options($app),
	)
}

sub validate_args {
	my ($self, $opt, $args) = @_;

	$self->next::method($opt, $args);
	unless ($self->contains_base_args($opt) || $opt->template()) {
		$self->usage_error("Parameter 'template' required");
	}
	return;
}



sub contains_base_args {
	my ($self, $opt) = @_;
	return $opt->list() || $opt->create_template_dir();
}


sub get_options {
	my ($class, $app) = @_;
	return ();
}



sub get_template_dirs {
	my ($self) = @_;

	my @dirs;
	my $command_name = $self->command_names();
	my $user_template_dir = $self->_get_user_template_dir($command_name);
	if ($user_template_dir) {
		push @dirs, $user_template_dir;
	}
	push @dirs, $self->get_extra_template_dirs($command_name);
	my $command_dir = Path::Class::Dir->new(
		File::ShareDir::dist_dir($self->get_dist_name())
	)->subdir($command_name);
	if (-d $command_dir) {
		push @dirs, $command_dir;
	}

	return @dirs;
}

sub _get_user_template_dir {
	my ($self, $command, $create) = @_;
	my $my_dist_data = File::HomeDir->my_dist_data(
		$self->get_dist_name(),
		$create ? { create => 1} : ()
	);
	if ($my_dist_data) {
		my $my_command_dir = Path::Class::Dir->new($my_dist_data)->subdir($command);
		if (-d $my_command_dir) {
			return $my_command_dir;
		}
		elsif ($create) {
			$my_command_dir->mkpath()
				or confess("Unable to create template dir $my_command_dir");
			return $my_command_dir
		}
	}
	return;
}



sub get_extra_template_dirs {
	my ($self, $command) = @_;

	if (! defined $command || $command eq '') {
		croak("Required 'command' parameter not passed or empty");
	}

	my $scaffolder_template_path = $ENV{SCAFFOLDER_TEMPLATE_PATH};
	my @extra_template_dirs;
	if (defined $scaffolder_template_path && $scaffolder_template_path ne '') {
		push @extra_template_dirs, grep { -d $_ } map {
			Path::Class::Dir->new($_)->subdir($command)
		} split(/$Config::Config{path_sep}/x, $scaffolder_template_path);
	}

	return @extra_template_dirs;
}



sub get_templates {
	my ($self) = @_;

	my $template = {};
	for my $dir ($self->get_template_dirs()) {
		for my $template_dir (grep { $_->is_dir() } $dir->children()) {
			my $name = $template_dir->dir_list(-1, 1);
			if (exists $template->{$name}) {
				$template->{$name}->add_path_entry($template_dir);
			}
			else {
				$template->{$name} = App::Scaffolder::Template->new({
					name => $name,
					path => [ $template_dir ],
				});
			}
		}
	}
	return $template;
}



sub get_template {
	my ($self, $name) = @_;

	if (! defined $name || $name eq '') {
		croak("Required 'name' parameter not passed or empty");
	}

	my $template = $self->get_templates();
	unless (exists $template->{$name}) {
		croak("No template called '$name' found");
	}
	return $template->{$name}
}



sub get_target {
	my ($self, $opt) = @_;
	return Path::Class::Dir->new($opt->target() || '.');
}



sub get_variables {
	my ($self, $opt) = @_;
	return {};
}



sub get_dist_name {
	confess("get_dist_name must be implemented by scaffolder commands");
}



sub execute {
	my ($self, $opt, $args) = @_;

	if ($opt->list()) {
		print "Template search path for ".$self->command_names().":\n ";
		print join "\n ", $self->get_template_dirs();
		print "\nAvailable templates for ".$self->command_names().":\n ";
		print join "\n ", sort keys %{$self->get_templates()};
		print "\n";
		return;
	}
	if ($opt->create_template_dir()) {
		$self->_get_user_template_dir($self->command_names(), 1);
		print "Template search path after creating template dir for "
			.$self->command_names().":\n ";
		print join "\n ", $self->get_template_dirs();
		print "\n";
		return;
	}

	my @files = $self->get_template($opt->template())->process({
		target    => $self->get_target($opt),
		variables => $self->get_variables($opt),
		overwrite => $opt->overwrite(),
	});
	unless ($opt->quiet()) {
		print join("\n", sort @files) . "\n";
	}

	return;
}

1;


__END__
=pod

=head1 NAME

App::Scaffolder::Command - Base class for App::Scaffolder commands

=head1 VERSION

version 0.002000

=head1 SYNOPSIS

	package App::Scaffolder::Command::mycommand;
	use parent qw(App::Scaffolder::Command);

	sub get_dist_name {
		return 'App-Scaffolder-MyDist';
	}

	1;

=head1 DESCRIPTION

App::Scaffolder::Command is a base class for L<App::Scaffolder|App::Scaffolder>
commands. Among other things, it provides access to the templates that belong to
the command and provides the C<execute> method which handles some basic
parameters like C<--list> and also evaluates the selected template.

=head2 contains_base_args

Check if options contain a base argument like C<--list> or
C<--create-template-dir>.

=head3 Result

True if yes, false otherwise.

=head2 get_options

Getter for the options. Should be implemented by subclasses.

=head3 Result

A list with additional options for the command.

=head2 get_template_dirs

Getter for the directories where templates are searched. Uses
L<File::HomeDir|File::HomeDir> and L<File::ShareDir|File::ShareDir> using the
distribution name and appends the command name to the directory. If
C<get_extra_template_dirs> returns a non-empty list, this will be put between
these two default directories.

=head3 Result

A list with the directories.

=head2 get_extra_template_dirs

Method to insert additional template directories between the 'local',
L<File::HomeDir|File::HomeDir>-based directory and the 'global',
L<File::ShareDir|File::ShareDir>-based one into the search path. By default,
this takes the directories from the C<SCAFFOLDER_TEMPLATE_PATH> environment
variable.

=head3 Parameters

This method expects positional parameters.

=over

=item command

Name of the command template directories should be returned for.

=back

=head3 Result

A potentially empty list with the additional directories.

=head2 get_templates

Reads the template directories and creates a
L<App::Scaffolder::Template|App::Scaffolder::Template> object for each template
that is found.

=head3 Result

A hash reference with the found templates.

=head2 get_template

Get the template with a given name.

=head3 Parameters

This method expects positional parameters.

=over

=item name

Name of the template.

=back

=head3 Result

The L<App::Scaffolder::Template|App::Scaffolder::Template> with the given name
if it exists, an exception otherwise.

=head2 get_target

Extract the target directory from the options.

=head3 Parameters

This method expects positional parameters.

=over

=item opt

Options as passed to C<execute>.

=back

=head3 Result

A L<Path::Class::Dir|Path::Class::Dir> object with the target directory.

=head2 get_variables

Get variables that should be passed to templates. Should be overridden by
subclasses.

=head3 Result

A hash reference with template variables.

=head2 get_dist_name

Getter for the distribution name. Must be implemented by subclasses.

=head3 Result

The name of the distribution the command belongs to.

=head2 execute

Execute the command using the given command line options.

=head3 Result

Nothing on success, an exception otherwise.

=head1 AUTHOR

Manfred Stock <mstock@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Manfred Stock.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

