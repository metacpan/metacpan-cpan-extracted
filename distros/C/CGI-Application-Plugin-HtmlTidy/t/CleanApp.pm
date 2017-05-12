package CleanApp;

use strict;
use CGI::Application;
use base qw/CGI::Application/;
use CGI::Application::Plugin::HtmlTidy;

## need to override this to add ht support
sub cgiapp_postrun {
	my ($self, $outputref) = @_;
	$self->htmltidy_clean($outputref);
}

sub setup {
	my $self = shift;
	$self->start_mode('valid_html');
	$self->run_modes([ qw/ valid_html invalid_html non_html header_redirect header_none/ ]);
}

sub valid_html {
	return '<html><head><title>valid</title></head><body>valid</body></html>'
}

sub invalid_html {
	return qq{
	<html>
		<headhunter>
			<h1>h1 not allowed here, and not closed
		</head>
		Missing body
	</htm>
	};
}

sub non_html {
	my $self = shift;
	$self->header_props(-type => 'text/js');
	return qq{
	var a = new Array;
	}
}

sub header_redirect {
	my $self = shift;
	$self->header_type('redirect');
	$self->header_props(-url => '/');
	return 'redirect';
}

sub header_none {
	my $self = shift;
	$self->header_type('none');
	return 'none';
}

1;


