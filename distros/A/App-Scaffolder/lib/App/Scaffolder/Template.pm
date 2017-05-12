package App::Scaffolder::Template;
{
  $App::Scaffolder::Template::VERSION = '0.002000';
}

# ABSTRACT: Represent a template for App::Scaffolder

use strict;
use warnings;

use Carp;
use Scalar::Util qw(blessed);
use Path::Class::File;
use File::Spec;


sub new {
	my ($class, $arg_ref) = @_;

	my $name = $arg_ref->{name};
	if (! defined $name || $name eq '') {
		croak("Required 'name' parameter not passed");
	}

	my $path = $arg_ref->{path};
	unless (defined $path && ref $path eq 'ARRAY') {
		croak("Required 'path' parameter not passed or not an array reference");
	}

	my $self = {
		name => $name,
		path => $path,
	};

	return bless($self, $class);
}



sub add_path_entry {
	my ($self, $dir) = @_;

	unless (blessed $dir && $dir->isa('Path::Class::Dir')) {
		croak("Required 'dir' parameter not passed or not a 'Path::Class::Dir' instance");
	}
	push @{$self->{path}}, $dir;
	return;
}



sub get_path {
	my ($self) = @_;
	return $self->{path};
}



sub get_name {
	my ($self) = @_;
	return $self->{name};
}



sub process {
	my ($self, $arg_ref) = @_;

	unless (defined $arg_ref && ref $arg_ref eq 'HASH') {
		croak("No parameters passed or not a hash reference");
	}
	my $target = $arg_ref->{target};
	unless (blessed $target && $target->isa('Path::Class::Dir')) {
		croak("Required 'target' parameter not passed or not a 'Path::Class::Dir' instance");
	}
	my $variables = $arg_ref->{variables};
	unless (defined $variables && ref $variables eq 'HASH') {
		croak("Required 'variables' parameter not passed or not a hash reference");
	}

	my @created_files;
	for my $file (values %{$self->get_template_files()}) {
		my $rel_target = $self->replace_file_path_variables(
			$file->{rel_target},
			$variables
		);
		my $target_dir = $target->subdir($rel_target->parent());
		unless (-d $target_dir) {
			$target_dir->mkpath()
				or confess("Unable to create target directory $target_dir");
		}

		my $output_file = $target_dir->file(
			$rel_target->basename()
		);
		if (-e $output_file && ! $arg_ref->{overwrite}) {
			croak(
				"File " . $output_file . " exists - need to pass 'overwrite' "
					. "parameter to overwrite files"
			);
		}
		$output_file->openw()->write($self->get_content_for(
			$file->{source}, $variables
		));
		push @created_files, $output_file;
	}

	return @created_files;
}



sub get_content_for {
	my ($self, $file, $variables) = @_;

	unless (blessed $file && $file->isa('Path::Class::File')) {
		croak("Required 'file' parameter not passed or not a 'Path::Class::File' instance");
	}
	$variables ||= {};

	my $content = '';
	if ($file =~ m{\.tt$}x) {
		require Template;
		my $template = Template->new({
			ABSOLUTE => 1,
		});
		$template->process($file->stringify(), $variables, \$content)
			or confess $template->error();
	}
	else {
		$content = $file->slurp();
	}
	return $content;
}



sub replace_file_path_variables {
	my ($self, $path, $variables) = @_;

	unless (blessed $path && $path->isa('Path::Class::File')) {
		croak("Required 'path' parameter not passed or not a 'Path::Class::File' instance");
	}

	if (! defined $variables || ref $variables ne 'HASH') {
		croak("Required 'variables' parameter not passed or not a hash reference");
	}

	my $orig_path = $path;
	my @orig_parts = File::Spec->splitdir($orig_path);

	while ($path =~ m{___([^_/\\]+)___}x) {
		if (defined $variables->{$1}) {
			$path =~ s{___([^_/\\]+)___}{$variables->{$1}}gx;
			$path = Path::Class::File->new($path);
		}
		else {
			croak("Unreplaceable filename variable $1 found");
		}
	}
	my @parts = File::Spec->splitdir($path);
	if (scalar @parts > scalar File::Spec->no_upwards(@parts)
			|| scalar @parts < scalar @orig_parts) {
		croak("Potential directory traversal detected in path '$path'");
	}
	return $path;
}



sub get_template_files {
	my ($self) = @_;
	my $file = {};
	for my $path_entry (map {$_->absolute()} @{$self->get_path()}) {
		$path_entry->recurse(callback => sub {
			my ($child) = @_;
			unless ($child->is_dir()) {
				my $rel_path = $child->relative($path_entry);
				my $key = $rel_path->stringify();
				if ($key =~ s{\.tt$}{}x) {
					my ($filename) = $rel_path->basename() =~ m{(.*)\.tt}x;
					$rel_path = $rel_path->parent()->file($filename)->cleanup();
				}
				unless (exists $file->{$key}) {
					$file->{$key} = {
						rel_target => $rel_path,
						source     => $child,
					};
				}
			}
		});
	}
	return $file;
}


1;

__END__
=pod

=head1 NAME

App::Scaffolder::Template - Represent a template for App::Scaffolder

=head1 VERSION

version 0.002000

=head1 SYNOPSIS

	use Path::Class::Dir;
	use App::Scaffolder::Template;

	my $template = App::Scaffolder::Template->new({
		name => 'name_of_the_template',
		path => [
			Path::Class::Dir->new('/first/path/belonging/to/template'),
			Path::Class::Dir->new('/second/path/belonging/to/template'),
		]
	});
	my @files = $template->process({
		target    => Path::Class::Dir->new('target', 'directory'),
		variables => {
			variable_value => 'a variable value',
		}
	});

=head1 DESCRIPTION

App::Scaffolder::Template represents a template. A template consists of one or
more directories containing files that should be copied to a target directory
when processing it. If a file has a C<.tt> extension, it will be passed through
L<Template|Template> before it is written to a target file without the C<.tt>
suffix. Thus the template

	foo
	|-- subdir
	|   |-- template.txt.tt
	|   `-- sub.txt
	|-- top-template.txt.tt
	`-- bar.txt

would result in the following structure after processing:

	output
	|-- subdir
	|   |-- template.txt
	|   `-- sub.txt
	|-- top-template.txt
	`-- bar.txt

The path of a file in the template may also contain variables, which are
delimited by C<___> and replaced with values from the C<variables> passed to
C<process>:

	# Template file path:
	___dir___/___name___.txt

	# Given $variables = { dir => 'directory', name => 'some_name' }, the
	# following file will be created in the target directory:
	directory/some_name.txt

This can be useful if parts of the output file path are not constant.

=head1 METHODS

=head2 new

Constructor, creates new instance.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item name

Name of the template.

=item path

Search path for files that belong to the template. If more than one file has
the same relative path, only the first one will be used, so it is possible to
override files that come 'later' in the search path.

=back

=head2 add_path_entry

Push another directory on the search path.

=head2 get_path

Getter for the template file search path.

=head3 Result

The template file search path.

=head2 get_name

Getter for the name.

=head3 Result

The name.

=head2 process

Process the template.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item target

Target directory where the output should be stored.

=item variables

Hash reference with variables that should be made available to templates.

=item overwrite

By default, existing files will not be overwritten. Passing a truthy value for
the C<overwrite> parameter changes this.

=back

=head3 Result

A list with the created files on succes, an exception otherwise.

=head2 get_content_for

Given a file from the template and some template variables, read and potentially
process the file and return the content the resulting file should have.

=head3 Parameters

This method expects positional parameters.

=over

=item file

Input file from the template.

=item variables

Variables that should be made available to the template.

=back

=head3 Result

The content for the corresponding target file.

=head2 replace_file_path_variables

Replace parts inside a L<Path::Class::File|Path::Class::File>-based path that
match C<___E<lt>nameE<gt>___> with a value from a hash.

=head3 Parameters

This method expects positional parameters.

=over

=item path

Path to the file which may contain placeholders.

=item variables

Hash reference with values that should replace the placeholders.

=back

=head3 Result

The processed file path.

=head2 get_template_files

Getter for the file that belong to the template.

=head3 Result

A hash reference containing hash references with information about the files.

=head1 AUTHOR

Manfred Stock <mstock@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Manfred Stock.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

