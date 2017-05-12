package App::Scaffolder::Command::html;
{
  $App::Scaffolder::Command::html::VERSION = '0.001000';
}
use parent qw(App::Scaffolder::Command);

# ABSTRACT: Scaffold a basic HTML file

use strict;
use warnings;

use MRO::Compat;
use Path::Class::Dir;



sub get_variables {
	my ($self, $opt) = @_;
	return {
		name  => scalar $opt->name(),
		title => scalar $opt->title() || scalar $opt->name(),
	};
}



sub get_dist_name {
	return 'App-Scaffolder-HTML';
}



sub get_options {
	my ($class) = @_;
	return (
		[ 'name|n=s' => 'Name of the new HTML file that should be created, without suffix' ],
		[ 'title=s'  => 'Title of the new HTML document that should be created' ],
	);
}


sub validate_args {
	my ($self, $opt, $args) = @_;

	$self->next::method($opt, $args);
	unless ($self->contains_base_args($opt) || $opt->name()) {
		$self->usage_error("Parameter 'name' required");
	}
	return;
}


1;

__END__
=pod

=head1 NAME

App::Scaffolder::Command::html - Scaffold a basic HTML file

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

	# Create a simple HTML5 file:
	$ scaffolder html --template html5 --name index --title "My Document"

	# Create a simple XHTML file:
	$ scaffolder html --template xhtml10strict --name index --title "My Document"

=head1 DESCRIPTION

App::Scaffolder::Command::html scaffolds HTML files. By default, it provides two
simple templates:

=over

=item *

C<html5>: Create a HTML5 document.

=item *

C<xhtml10strict>: Create a XHTML 1.0 strict document.

=back

=head1 METHODS

=head2 get_variables

Specialized C<get_variables> version which returns the name of the output file
and the title for the document.

=head2 get_dist_name

Return the name of the dist this command is in.

=head2 get_options

Return additional options for this command.

=head1 SEE ALSO

=over

=item *

L<App::Scaffolder::Command|App::Scaffolder::Command> - command base class

=back

=head1 AUTHOR

Manfred Stock <mstock@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Manfred Stock.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

