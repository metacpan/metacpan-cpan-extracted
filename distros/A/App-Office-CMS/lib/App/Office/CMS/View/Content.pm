package App::Office::CMS::View::Content;

use Any::Moose;
use common::sense;

use Text::Xslate 'mark_raw';

use Try::Tiny;

extends 'App::Office::CMS::View::Base';

# If Moose...
#use namespace::autoclean;

our $VERSION = '0.92';

# -----------------------------------------------

sub build_head_js
{
	my($self) = @_;

	$self -> log(debug => 'build_head_js()');

	my($config) = $self -> config;
	my($param)  =
	{
		form_action => $self -> form_action,
	};

	return $self -> templater -> render('content.js', $param);

} # End of build_head_js.

# -----------------------------------------------

sub build_update_content_html
{
	my($self, $site, $design, $page, $asset) = @_;

	$self -> log(debug => 'build_update_content_html()');

	my($backup_command) = ${$self -> config}{backup_command};
	my($content)        = $self -> db -> content -> get_content_by_page_id($$page{id});
	my($context)        = 'update';
	my($param)          =
	{
	 backup      => $backup_command ? 1 : 0, # We only need a Boolean in the template.
	 body_text   => mark_raw($$content{body_text}),
	 colspan     => $backup_command ? 1 : 2, # Make generate button's position look pretty.
	 context     => $context,
	 design_name => $$design{name},
	 head_text   => mark_raw($$content{head_text}),
	 page_name   => $$page{name},
	 sid         => $self -> session -> id,
	 site_name   => $$site{name},
	 submit_text => 'Save',
	};

	return $self -> templater -> render('content.tx', $param);

} # End of build_update_content_html.

# -----------------------------------------------

sub edit
{
	my($self, $site, $design, $page, $asset) = @_;

	$self -> log(debug => 'edit()');

	return $self -> build_update_content_html($site, $design, $page, $asset);

} # End of edit.

# -----------------------------------------------

sub generate
{
	my($self, $site, $design, $page, $menu, $content) = @_;

	$self -> log(debug => 'generate()');

	my($config) = $self -> config;
	my($param)  =
	{
		body_text   => mark_raw($$content{body_text}),
		design_name => $$design{name},
		head_text   => mark_raw($$content{head_text}),
		menu        => mark_raw(join("\n", @$menu) ),
		page_name   => $$page{name},
		site_name   => $$site{name},
		yui_url     => $$config{yui_url},
	};

	my($template_name) = $$page{homepage} eq 'Yes' ? 'home.page.tx' : 'generic.page.tx';

	return $self -> templater -> render("page.templates/$template_name", $param);

} # End of generate.

# -----------------------------------------------

no Any::Moose;

# If Moose...
#__PACKAGE__ -> meta -> make_immutable;

1;
