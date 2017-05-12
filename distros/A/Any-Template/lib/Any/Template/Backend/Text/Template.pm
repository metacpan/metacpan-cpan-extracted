package Any::Template::Backend::Text::Template;

use strict;
use Text::Template;
use Any::Template::Backend;
use vars qw(@ISA);
@ISA = qw(Any::Template::Backend);

use vars qw($VERSION);
$VERSION = sprintf"%d.%03d", q$Revision: 1.6 $ =~ /: (\d+)\.(\d+)/;

sub new {
	my ($class, $options) = @_;
	my $marshalled = _marshall_options($options);
	DUMP($marshalled);
	my $self = {
		engine => new Text::Template(%$marshalled)	
	};
	return bless($self, $class);
}

sub native_object {
	my $self = shift;
	return $self->{engine};	
}

sub process_to_string {
	my ($self, $data, $ref_buffer) = @_;
	$$ref_buffer = $self->{engine}->fill_in(HASH => $data);
	return 1;
}

sub process_to_filehandle {
	my ($self, $data, $fh) = @_;
	$self->{engine}->fill_in(HASH => $data, OUTPUT => $fh);
	return 1;
}

#
# This marshalls the Any::Template ctor options into the form required for Text::Template
#
sub _marshall_options {
	my $at_options = shift;
	my %tt_options = %{$at_options->{Options}};
	if(exists $at_options->{String}) {
		$tt_options{TYPE} = 'STRING';
		$tt_options{SOURCE} = $at_options->{String};
	}
	elsif(exists $at_options->{Filename}) {
		$tt_options{TYPE} = 'FILE';
		$tt_options{SOURCE} = $at_options->{Filename};	
	}
	elsif(exists $at_options->{Filehandle}) {
		$tt_options{TYPE} = 'FILEHANDLE';
		$tt_options{SOURCE} = $at_options->{Filehandle};		
	}
	return \%tt_options;
}

sub DUMP {}
sub TRACE {}

1;

=head1 NAME

Any::Template::Backend::Text::Template - Any::Template backend for Text::Template

=head1 SYNOPSIS

	use Any::Template;
	my $template = new Any::Template(
		Backend => 'Text::Template',
		Options => {
			UNTAINT => 1 #Pass in Text::Template ctor options
		},
		File => 'page.tmpl'
	);	
	my $output = $template->process($data);

=head1 DESCRIPTION

All template input methods are provided natively by Text::Template.
Output to a coderef uses the default implementation of buffering all the output in a string and passing this to a coderef,
so beware of the memory consumption if the output is large.  Output to a string and filehandle all use Text::Template's native implementation.
Output to a file uses the default wrapper around output to a fileshandle.

=head1 SEE ALSO

L<Any::Template>, L<Any::Template::Backend>, L<Text::Template>

=head1 VERSION

$Revision: 1.6 $ on $Date: 2005/05/08 18:25:18 $ by $Author: johna $

=head1 AUTHOR

John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut