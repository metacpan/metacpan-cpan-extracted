package App::Office::CMS::View::Page;

use strict;
use warnings;

use Moo;

use Text::Xslate 'mark_raw';

use Try::Tiny;

extends 'App::Office::CMS::View::Base';

our $VERSION = '0.93';

# -----------------------------------------------

sub build_head_js
{
	my($self) = @_;

	$self -> log(debug => 'build_head_js()');

	return $self -> templater -> render('page.js', {form_action => $self -> form_action});

} # End of build_head_js.

# -----------------------------------------------

sub build_update_page_html
{
	my($self, $site, $design, $page) = @_;

	$self -> log(debug => 'build_update_page_html()');

	# TODO. We assume the page has 1 asset, so we get it from the db.

	my($asset)      = $self -> db -> asset -> get_asset_by_page_id($$page{id});
	my($asset_type) = $self -> db -> asset -> get_asset_type_by_id($$asset{asset_type_id});
	my($context)    = 'update';
	my($param)      =
	{
	 context           => $context,
	 current_page_name => $$page{name},
	 design_name       => $$design{name},
	 homepage          => $$page{homepage} eq 'Yes' ? 'checked' : '',
	 name              => $$page{name}, # Prefer '', but set it for validation.
	 sid               => $self -> session -> id,
	 site_name         => $$site{name},
	 submit_text       => 'Save',
	 template_name     => mark_raw($self -> build_select('asset_types', $$asset{asset_type_id}) ),
	};

	return $self -> templater -> render('page.tx', $param);

} # End of build_update_page_html.

# -----------------------------------------------

sub edit
{
	my($self, $site, $design, $page) = @_;

	$self -> log(debug => 'edit()');

	return $self -> build_update_page_html($site, $design, $page);

} # End of edit.

# -----------------------------------------------

1;
