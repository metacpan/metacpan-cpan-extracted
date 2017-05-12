package Any::Template::Backend::Text::MicroMason;

use strict;
use Text::MicroMason;
use Any::Template::Backend;
use vars qw(@ISA);
@ISA = qw(Any::Template::Backend);

use vars qw($VERSION);
$VERSION = sprintf"%d.%03d", q$Revision: 1.7 $ =~ /: (\d+)\.(\d+)/;

sub new {
	my ($class, $options) = @_;
	my $attributes = $options->{Options}{Attributes} || {};
	my $mixins = $options->{Options}{Mixins} || [];
	my $compile_options = _compile_options($options);
	my $factory = new Text::MicroMason(@$mixins, %$attributes);
	my $self = {
		engine => $factory->compile(%$compile_options)
	};
	return bless($self, $class);
}

sub native_object {
	my $self = shift;
	return $self->{engine};	
}

sub process_to_string {
	my ($self, $data, $ref_buffer) = @_;
	die("data must be a hashref") unless(ref $data eq "HASH");
	$$ref_buffer = $self->{engine}->(%$data);
	return 1;
}

#
# This marshalls the Any::Template ctor options into the form required for Text::MicroMason
#
sub _compile_options {
	my $at_options = shift;
	my %options;
	if(exists $at_options->{String}) {
		$options{text} = $at_options->{String};
	}
	elsif(exists $at_options->{Filename}) {
		$options{file} = $at_options->{Filename};
	}
	elsif(exists $at_options->{Filehandle}) {
		$options{text} = _fh_to_string($at_options->{Filehandle});
	}
	return \%options;
}

sub _fh_to_string {
	my $fh = shift;
	local $/ = undef;
	$fh = $$fh if(ref $fh eq 'GLOB');
	my $string = <$fh>;
	return $string;
}

sub DUMP {}
sub TRACE {}

1;

=head1 NAME

Any::Template::Backend::Text::MicroMason - Any::Template backend for Text::MicroMason

=head1 SYNOPSIS

	use Any::Template;
	my $template = new Any::Template(
		Backend => 'Text::MicroMason',
		Options => {
			Attributes => {global_vars => 1},      #MicroMason %attribs
			Mixins => [qw(-HTMLTemplate -Filters)] #Specify mixins
		},
		File => 'page.tmpl'
	);	
	my $output = $template->process($data);

=head1 DESCRIPTION

Attributes may be passed to Text::MicroMason in the {Options}{Attributes} key.  
The {Options}{Mixins} key is used to pass mixins to Text::MicroMason.  

Inputs from a file and string are provided natively by Text::MicroMason.
Input from a filehandle uses the default implementation (which is to read into a string).

Output to filehandle is based on the default implementation of capturing output in a string and writing
this to a filehandle, so watch out for this if your output is very large.  Output to a file uses the native
Text::MicroMason implementation.

Output to a coderef uses the default implementation of buffering all the output in a string and passing this to a coderef,
so again beware of the memory consumption if the output is large.

=head1 SEE ALSO

L<Any::Template>, L<Any::Template::Backend>, L<Text::MicroMason>

=head1 VERSION

$Revision: 1.7 $ on $Date: 2006/05/08 12:28:00 $ by $Author: mattheww $

=head1 AUTHOR

John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut

# vim:noet
