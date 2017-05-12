package CGI::Application::Plugin::AutoRunmode::FileDelegate;

use strict;
use Carp;

our $VERSION = '0.18';

sub new{
	my ($pkg, @directories) = @_;
	foreach my $directory (@directories){
		# keep taint-mode happy where ./ is not in @INC
		$directory = "./$directory" unless (index ($directory, '/') == 0);
		# check if the directory exists
		croak "$directory is not a directory" unless -d $directory;
	}
	return bless \@directories, $pkg;
}

sub can{
	my($self, $name) = @_;
	# check the directories
	foreach (@$self){
		if (-e "$_/$name.pl"){
			my $can = do "$_/$name.pl";
			if ($@ or $!){
				croak "could not evaluate runmode in file $_/$name.pl: $@ $!";
			}
			return $can if ref $can eq 'CODE';
			croak "runmode file $_/$name.pl did not return a subroutine reference";
		}
	}
	
	return UNIVERSAL::can($self, $name); 
}

1;

__END__

=head1 NAME

CGI::Application::Plugin::AutoRunmode::FileDelegate - delegate CGI::App run modes to a directory of files

=head1 SYNOPSIS

	# in file runmodes/my_run_mode.pl
		sub  {
			my ($app, $delegate) = @_;
				# do something here
		};
		
	# in file runmodes/another_run_mode.pl
		sub {
				# do something else
		};
		
	
	package MyApp;
   	use base 'CGI::Application';
	use CGI::Application::Plugin::AutoRunmode 
		qw [ cgiapp_prerun];
	use CGI::Application::Plugin::AutoRunmode::FileDelegate();
		
		sub setup{
			my ($self) = @_;
			my $delegate = new CGI::Application::Plugin::AutoRunmode::FileDelegate
					('/path/to/runmodes')
			$self->param('::Plugin::AutoRunmode::delegate' => $delegate);
		}
	
	 # you now have two run modes
	 # "my_run_mode" and "another_run_mode"

=head1 DESCRIPTION

Using this module, you can place the definition of your run modes
for a CGI::Application into directory of files (as opposed to into
a Perl module).

Each run mode is
contained in its own file, named foo.pl for a run mode called foo.
The run modes are lazily evaluated (on demand) for each request.
In the case of mod_perl this means you can update them
without restarting your web server. In the case of plain CGI it means
a reduced startup cost if you have many run modes (because only
the one that you need gets parsed and loaded, along with dependent 
modules).

=head2 Using more than one directory with runmodes

You can pass multiple directory paths to the constructor
for the delegate:

    	my $delegate = new CGI::Application::Plugin::AutoRunmode::FileDelegate
			('/path/to/runmodes', '/path/to/more_runmodes')
					

In this case, they will be searched in order. The first 
matching file becomes the run mode. In the case of errors
with that file, the module will croak (and not continue
the search in the remaining directories).

=head1 BUGS

With all the namespace nesting going on the name of this module 
has reached an intolerable Java-esque length.

=head1 SEE ALSO

If you like the idea of moving everything outside of Perl modules
into seperate files, you should also have a look at
L<CGI::Application::Plugin::TemplateRunner>, which does a similar
thing for HTML templates and the Perl code needed to provide them with 
data.

=head1 AUTHOR

Thilo Planz, E<lt>thilo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Thilo Planz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

