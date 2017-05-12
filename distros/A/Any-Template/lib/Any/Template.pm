###############################################################################
# Purpose : Consistent interface to templating modules
# Author  : John Alden
# Created : Dec 2004
# CVS     : $Header: /home/cvs/software/cvsroot/any_template/lib/Any/Template.pm,v 1.15 2006/04/18 08:32:26 johna Exp $
###############################################################################

package Any::Template;

use strict;
use Carp;
use File::Spec;
use File::Find;

use vars qw($VERSION);
$VERSION = sprintf"%d.%03d", q$Revision: 1.15 $ =~ /: (\d+)\.(\d+)/;

sub new {
	my($class, $options) = @_;
	DUMP("Any::Template constructor - options", $options);
	$options->{Options} = {} unless defined ($options->{Options}); #Ensure this key is present

	#Input checking	
	my $backend = $options->{Backend} || $ENV{ANY_TEMPLATE_DEFAULT} 
		or croak("You must nominate a Backend or set the ANY_TEMPLATE_DEFAULT environment variable");
	croak("Package name '$backend' looks incorrect") if($backend =~ /[^\w:]/);
	my @sources = qw(Filename Filehandle String);
	croak("You must supply one of: ".join(", ", @sources)) unless grep {defined $options->{$_}} @sources;
	
	#Load backend
	$backend = join("::", __PACKAGE__, 'Backend', $backend);	
	eval "require $backend";
	die($@) if($@);

	#Create object (containing backend)
	my $self = {};
	$self->{backend} = $backend->new($options);
	DUMP({Level => 2}, "Any::Template object", $self);
	return bless($self, $class);
}

sub process {
	my($self, $data, $collector) = @_;
	
	#Input checking
	croak("You must supply a data structure") unless defined($data);
	croak("Data structure should be a reference") unless(ref $data);
	
	my $string;
	if(defined $collector) {
		$self->_process($data, $collector);		
	} else {
		$self->_process($data, \$string);
	}		
	return $string;
}

sub native_object {
	my $self = shift;
	return $self->{backend}->native_object();
}

#Find all the available backends for Any::Template
sub available_backends {
	my @possible_locations = grep {-d $_} map {File::Spec->catfile($_, split(/::/, __PACKAGE__), "Backend")} @INC;
	
	my @backends;
	my $collector = sub {
		return unless $_ =~ /\.pm$/;
		my $file = $File::Find::name;	
		$file =~ s/\Q$File::Find::topdir\E//;
		$file =~ s/\.pm$//;
		my @dirs = File::Spec->splitdir($file);
		shift @dirs;
		$file = join("::", @dirs);
		push @backends, $file;
	};
	
	File::Find::find($collector, @possible_locations);	
	return \@backends;
}

#
# Private functions
#

sub _process {
	my($self, $data, $collector) = @_;
	
	#Preprocess data if required
	$data = $self->{backend}->preprocess($data); 

	#Type-based dispatch
	die("Hash or array refs not supported as sinks") if(ref $collector eq "HASH" || ref $collector eq "ARRAY");
	return $self->{backend}->process_to_string($data, $collector) if(ref $collector eq "SCALAR"); 
	return $self->{backend}->process_to_sub($data, $collector) if(ref $collector eq "CODE");   
	return $self->{backend}->process_to_filehandle($data, $collector) if(ref $collector eq "GLOB"); #Filehandle ref
	return $self->{backend}->process_to_filehandle($data, \$collector) if(ref \$collector eq "GLOB"); #Filehandle
	return $self->{backend}->process_to_file($data, $collector) if(not ref $collector); #Must come after check for glob
	return $self->{backend}->process_to_filehandle($data, $collector); #object - treat as a filehandle
}

#Log::Trace stubs
sub TRACE{}
sub DUMP{}

=head1 NAME

Any::Template - provide a consistent interface to a wide array of templating languages

=head1 SYNOPSIS

	use Any::Template;
	my $template = new Any::Template({
		Backend => 'HTML::Template',
		Filename => 'page.tmpl',
		Options => {'strict' => 0}
	});
	my $output = $template->process($data);

	my $template2 = new Any::Template({
		Backend => 'Text::Template',
		String => $template2_content
	});
	$template->process($data, \*STDOUT);

=head1 DESCRIPTION

This module provides a simple, consistent interface to common templating engines so you can write code that
is agnostic to the template language used in the presentation layer.  This means you can allow your interface 
developers to work in the templating language they're happiest in or write code that works with legacy/in-house 
templating modules but can also be released onto CPAN and work with more standard CPAN templating systems.

By its very nature, this interface only exposes pretty much the lowest common denominator of the template engine APIs.
It does however provide a fairly rich set of input and output mechanisms, using native implementations where available
and providing some default implementations to extend the default set offered by some templating modules.

If you need the quirky features of a particular templating engine, then this may not be for you.
Having said that, in some cases you may be able to encapsulate some of your logic in options passed into the adaptor classes
(either rolling your own adaptors, or improving ours) to pull the relevant strings on the backend module.

Templateing languages supported by backends supplied with this distribution can be found in the README (remember there may be others out there and you can always roll your own).

=head1 METHODS

=over 4

=item my $template = new Any::Template(\%options);

	See below for a list of options

=item $template->process($data_structure, $sink);

	$sink can be:
		- a scalar ref
		- a filename (string)
		- a filehandle (as a glob or glob ref) or an object offering a print method
		- a coderef (output will be passed in as the first argument)

=item $string = $template->process($data_structure);

A convenience form, if no second argument is passed to C<process()>, equivalent to:
	
	my $string;
	$template->process($data_structure, \$string);

except data is passed by value rather than by reference.

=item $templating_engine = $template->native_object();

Allows the native templating engine to be accessed.
This completely breaks the abstraction of Any::Template so it's not recommended you use it
other than as a bridging strategy as part of a refectoring/migration process 
(with a view to ultimately eliminating its use).

=back

=head1 SUBROUTINES

=over

=item available_backends

 $list_of_backends = Any::Template::available_backends();

Scans @INC for a list of modules in the Any::Template::Backend:: namespace.

=back

=head1 ERROR HANDLING

If an error occurs, an exception is raised with die().  You can use an eval block to handle the exception.  $@ will contain an error message.

=head1 CONSTRUCTOR OPTIONS

=over 4

=item Backend

Backends distributed with this module are listed in the distribution README.

See L<Any::Template::Backend> for information on writing your own backends.  
You should be able to create a new backend in a couple of dozen lines of code and 
slot it into the unit test with a one or 2 line change.

=item Filename

	Filename of the template file

=item String

	String containing the template

=item Filehandle

	Reference to a filehandle from which to read the template

=item Options

	A hashref of options passed to the backend templating engine

=back

=head1 ENVIRONMENT

If you don't supply a Backend to the constructor, Any::Template looks for a default Backend in the
ANY_TEMPLATE_DEFAULT environment variable. This allows you to retrofit Any::Template into legacy code without
hard-coding a default templating language or forcing a backwardly-incompatible change to the interface of the code you are retrofitting into.

=head1 CACHING

This module doesn't have built-in caching, however the objects it creates are intended to be cachable
(where possible the backends hold onto precompiled templates that can be fed any number of data structures).
It's therefore up to you what caching strategy you use.  In the spirit of "if you liked this, you might also like..."
L<Cache> and L<Cache::Cache> offer a consistent interface to a number of different caching strategies.

=head1 SEE ALSO

=over 4

=item *

L<CGI::Application::Plugin::AnyTemplate>

=item *

L<Text::MicroMason>

=item *

L<Template>

=item *

L<HTML::Template>
 
=item *

L<Text::Template>

=back 

=head1 VERSION

$Revision: 1.15 $ on $Date: 2006/04/18 08:32:26 $ by $Author: johna $

=head1 AUTHOR

John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 
 
=cut
