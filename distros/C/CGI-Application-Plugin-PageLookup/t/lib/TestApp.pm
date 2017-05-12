package TestApp;

use strict;
use warnings;

use CGI::Application;
@TestApp::ISA = qw(CGI::Application);
use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use CGI::Application::Plugin::PageLookup (qw/:all/);
use CGI::Application::Plugin::Forward;

sub setup {
        my $self = shift;

        $self->start_mode('basic_test');
        $self->run_modes(
		'basic_test'  => 'basic_test',
		'xml_sitemap' => 'xml_sitemap_rm',
		'pagelookup_rm'=> 'pagelookup_rm',
		'test0'=>\&test0
		);

}

sub basic_test {
        my $self = shift;
        return "Hello World: basic_test";
}

sub cgiapp_init {
        my $self = shift;
	# use the same args as DBI->connect();
	#$self->dbh_config("dbi:SQLite:t/dbfile","","");

	my %params = (remove=>['lang', 'template', 'pageId', 'internalId', 'changefreq']);
	$params{prefix} = $self->param('prefix') if $self->param('prefix');
	$params{remove} = $self->param('remove') if $self->param('remove');
	$params{msg_param} = $self->param('msg_param') if $self->param('msg_param');
	if ($self->param('notfound_stuff')) {
		$params{status_404}=4000 ;
		$params{msg_param}='error_param';
	}
	$params{xml_sitemap_base_url} = $self->param('xml_sitemap_base_url') if $self->param('xml_sitemap_base_url');
	$params{template_params} = $self->param('template_params') if $self->param('template_params');
	if ($self->param('objects')) {
		use HTML::Template::Pluggable;
		use HTML::Template::Plugin::Dot;
		$self->html_tmpl_class('HTML::Template::Pluggable');
		$params{objects} = $self->param('objects');
	}

	$self->pagelookup_config(%params);
}

sub create_smart_object {
	my $self = shift;
        use SmartObjectTest;
        return SmartObjectTest->new($self, shift, shift, shift);
}


