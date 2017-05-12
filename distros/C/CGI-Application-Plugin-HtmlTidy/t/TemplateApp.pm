package TemplateApp;

use strict;
use CGI::Application;
use base qw/CGI::Application/;
use CGI::Application::Plugin::DevPopup;
use CGI::Application::Plugin::HtmlTidy;

sub setup {
	my $self = shift;
	$self->start_mode('non_html');
	$self->run_modes([ qw/ non_html / ]);
}

sub load_tmpl {
    my $self = shift;
    my $file = shift;
    my %args = @_;
    warn "load_tmpl called with $args{die_on_bad_params}";
    $args{die_on_bad_params} = 1;
    $self->SUPER::load_tmpl("nonexistent/path/rhesa/smintheus/".$file, %args); # what are the odds? ;)
}

sub non_html {
	my $self = shift;
	# $self->header_props(-type => 'text/js');
	return qq{
	var a = new Array;
	}
}

1;

