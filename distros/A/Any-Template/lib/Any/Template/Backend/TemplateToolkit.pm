package Any::Template::Backend::TemplateToolkit;

use strict;
use Template;
use Any::Template::Backend;
use vars qw(@ISA);
@ISA = qw(Any::Template::Backend);

use vars qw($VERSION);
$VERSION = sprintf"%d.%03d", q$Revision: 1.7 $ =~ /: (\d+)\.(\d+)/;

sub new {
	my ($class, $options) = @_;
	my $self = bless {}, $class;
	my $marshalled = $self->_marshall_options($options);
	$self->{engine} = new Template($marshalled) or die($Template::ERROR);
	return $self;		
}

sub native_object {
	my $self = shift;
	return $self->{engine};	
}

sub process_to_string {
	my ($self, $data, $ref_buffer) = @_;
	$$ref_buffer = '';
	TRACE("Input", $self->{input});
	$self->{engine}->process($self->{input}, $data, $ref_buffer) or die($self->{engine}->error());
}

sub process_to_filehandle {
	my ($self, $data, $fh) = @_;
	TRACE("Input", $self->{input});
	$self->{engine}->process($self->{input}, $data, $fh) or die($self->{engine}->error());
}

sub process_to_file {
	my ($self, $data, $filepath) = @_;
	TRACE("Input", $self->{input});
	$self->{engine}->process($self->{input}, $data, $filepath) or die($self->{engine}->error());
}

sub process_to_sub {
	my ($self, $data, $coderef) = @_;
	return $self->{engine}->process($self->{input}, $data, $coderef) or die($self->{engine}->error());
}

#
# This marshalls the Any::Template ctor options into the form required for Template-Toolkit
#
sub _marshall_options {
	my $self = shift;
	my $at_options = shift;
	my %tt_options = %{$at_options->{Options}};
	if(exists $at_options->{String}) {
		$self->{input} = \$at_options->{String};
	}
	elsif(exists $at_options->{Filehandle}) {
		$self->{input} = $at_options->{Filehandle}; 		
	}
	elsif(exists $at_options->{Filename}) {
		$self->{input} = $at_options->{Filename};
	}
	else {
		die("No Filename, Filehandle or String");	
	}
	return \%tt_options;
}

#Log::Trace stubs
sub TRACE{}
sub DUMP{}

1;


=head1 NAME

Any::Template::Backend::TemplateToolkit - Any::Template backend for Template Toolkit

=head1 SYNOPSIS

	use Any::Template;
	my $template = new Any::Template(
		Backend => 'TemplateToolkit',
		Options => {
			'POST_CHOMP' => 1, #Template ctor options
		},
		File => 'page.tmpl'
	);	
	my $output = $template->process($data);

=head1 DESCRIPTION

All input and output methods are implemented using Template Toolkit's native features so they should
all be pretty efficient.

=head1 SEE ALSO

L<Any::Template>, L<Any::Template::Backend>, L<Template>

=head1 VERSION

$Revision: 1.7 $ on $Date: 2005/11/24 22:07:55 $ by $Author: johna $

=head1 AUTHOR

John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut