package Any::Template::Backend;

use strict;

use vars qw($VERSION);
$VERSION = sprintf"%d.%03d", q$Revision: 1.8 $ =~ /: (\d+)\.(\d+)/;

sub process_to_file {
	my ($self, $data, $filepath) = @_;
	local *FH;
	open (FH, ">$filepath") or die("Unable to open $filepath - $!");
	$self->process_to_filehandle($data, \*FH);
	close FH;
}

sub process_to_filehandle {
	my ($self, $data, $fh) = @_;
	my $buffer;
	$self->process_to_string($data, \$buffer);
	print $fh $buffer;	
}

sub process_to_sub {
	my ($self, $data, $coderef) = @_;
	my $buffer;
	$self->process_to_string($data, \$buffer);
	return $coderef->($buffer);	
}

sub preprocess {
	return $_[1]; #no-op by default	
}

1;

=head1 NAME

Any::Template::Backend - base class for implementing backends for Any::Template

=head1 SYNOPSIS

	package Any::Template::Backend::MyTemplate;
	
	use MyTemplate;
	use Any::Template::Backend;
	use vars qw(@ISA);
	@ISA = qw(Any::Template::Backend);
	
	sub new {
		...		
	}

=head1 DESCRIPTION

This exists purely to be inherited from.  It provides some default implementations of sending output to
different sinks based on the lowest common denominator of returning data to a string or filehandle.
You can override these implementations with more efficient ones where the templating engine provides them
natively.

=head1 API FOR BACKEND MODULES

=over 4

=item $o = new Any::Template::Backend::MyBackend(\%options);

You MUST supply a constructor.  There is no default contructor to inherit.
The constructor will need to marshal the options and create the backend template object from them.
Example implementations can be found in backend classes included with the distribution.

=item $templating_engine = $o->native_object()

Returns the underlying native template object.  You SHOULD supply this method.
Although accessing the underlying object defeats the point of Any::Template,
a valid use is in refactoring code, where dependencies on a particular engine's API
can be eradicated in iterations.

=item $data = $o->preprocess($data)

You CAN supply a method to preprocess the data structure before it's handed off to one of the process methods listed below.
Typically you might use this to remove some values from the data structure (e.g. globrefs) that a template backend
might not be able to handle.
The default implementation returns $data unmodified.

=item $o->process_to_string($data, $scalar_ref)

You MUST supply this method.
Example implementations can be found in backend classes included with the distribution.

=item $o->process_to_filehandle($data, $fh)

You CAN supply this method.  If you don't, output will be collected in a string and sent to the filehandle.

=item $o->process_to_sub($data, \&code)

You CAN supply this method.  If you don't, output will be collected in a string and sent to the sub.

=item $o->process_to_file($data, $filename)

You CAN supply this method.  If you don't, a filehandle will be opened against this file,
and process_to_filehandle will be used to populate it.

=back

=head1 VERSION

$Revision: 1.8 $ on $Date: 2005/05/08 18:25:16 $ by $Author: johna $

=head1 AUTHOR

John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
