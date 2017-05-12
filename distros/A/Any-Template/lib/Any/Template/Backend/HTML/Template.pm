package Any::Template::Backend::HTML::Template;

use strict;
use HTML::Template;
use Any::Template::Backend;
use vars qw(@ISA);
@ISA = qw(Any::Template::Backend);

use vars qw($VERSION);
$VERSION = sprintf"%d.%03d", q$Revision: 1.7 $ =~ /: (\d+)\.(\d+)/;

sub new {
	my ($class, $options) = @_;
	my $marshalled = _marshall_options($options);
	DUMP($marshalled);
	my $self = {
		engine => new HTML::Template(%$marshalled)	
	};
	return bless($self, $class);
}

sub native_object {
	my $self = shift;
	return $self->{engine};	
}

sub process_to_string {
	my ($self, $data, $ref_buffer) = @_;
	my $engine = $self->{engine};
	$engine->clear_params();
	$engine->param($data);
	$$ref_buffer = $engine->output();
}

sub process_to_filehandle {
	my ($self, $data, $fh) = @_;
	my $engine = $self->{engine};
	$engine->clear_params();
	$engine->param($data);
	$engine->output(print_to => $$fh);
}

#
# This marshalls the Any::Template ctor options into the form required for HTML::Template
#
sub _marshall_options {
	my $at_options = shift;
	my %ht_options = %{$at_options->{Options}};
	$ht_options{filename} = $at_options->{Filename} if(exists $at_options->{Filename});	
	$ht_options{filehandle} = $at_options->{Filehandle} if(exists $at_options->{Filehandle});	
	$ht_options{scalarref} = \$at_options->{String} if(exists $at_options->{String});	
	return \%ht_options;
}

#Log::Trace stubs
sub TRACE {}
sub DUMP{}

1;

=head1 NAME

Any::Template::Backend::HTML::Template - Any::Template backend for HTML::Template

=head1 SYNOPSIS

	use Any::Template;
	my $template = new Any::Template(
		Backend => 'HTML::Template',
		Options => {
			strict => 0, #Pass in any HTML::Template ctor options here			
		},
		File => 'page.tmpl'
	);	
	my $output = $template->process($data);

=head1 DESCRIPTION

All template input methods are provided natively by HTML::Template.
Output to a coderef uses the default implementation of buffering all the output in a string and passing this to a coderef,
so beware of the memory consumption if the output is large.  Output to a string and filehandle all use HTML::Template's native implementation.
Output to a file uses the default wrapper around output to a fileshandle.

=head1 SEE ALSO

L<Any::Template>, L<Any::Template::Backend>, L<HTML::Template>

=head1 VERSION

$Revision: 1.7 $ on $Date: 2005/05/08 18:25:17 $ by $Author: johna $

=head1 AUTHOR

John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut