package OptionsApp;

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
	$self->run_modes([ qw/ valid_html invalid_html / ]);
    $self->htmltidy_config(
            'tidy-mark'    => 'yes',
            'alt-text'     => 'xxx',
        );
}

sub valid_html {
	return '<html><head><title>valid</title></head><body>valid<img src="/"></body></html>'
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

1;


