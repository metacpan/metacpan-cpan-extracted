package App::Office::CMS::Controller::Initialize;

use parent 'App::Office::CMS::Controller';
use common::sense;

use Text::Xslate 'mark_raw';

our $VERSION = '0.92';

# -----------------------------------------------

sub build_about_html
{
	my($self) = @_;

	$self -> log(debug => 'build_about_html()');

	my($config) = $self -> param('config');

	my(@tr);

	push @tr, {left => 'Program', right => "$$config{program_name} $$config{program_version}"};
	push @tr, {left => 'Author',  right => $$config{program_author} };
	push @tr, {left => 'Help',    right => mark_raw(qq|<a href="$$config{program_faq_url}">FAQ</a>|)};

	# Make YUI happy by turning the HTML into 1 long line.

	my($html) = $self -> param('templater') -> render('table.tx', {data => [@tr]});
	$html     =~ s/\n//g;

	return $html;

} # End of build_about_html.

# -----------------------------------------------

sub build_head_init
{
	my($self) = @_;

	$self -> log(debug => 'build_head_init()');

	# These things are called by YAHOO.util.Event.onDOMReady(init).
	# We use $site_count like this:
	# o If there are no sites yet, default to the New Site tab.
	# o If there are some sites, default to the Edit Site tab.

	my($about_html)    = $self -> build_about_html;
	my($new_site_html) = $self -> param('view') -> site -> build_new_site_html;
	my($search_html)   = $self -> param('view') -> search -> build_search_html;
	my($site_count)    = $self -> param('db') -> get_site_count;

	# Add tabs left-to-right to the tabview.
	# Warning: These tabs are numbered 0 .. N by YUI.
	# To make a specific tab active, e.g. after it's contents are updated
	# via AJAX, the tab number is used. See:
	# page.js lines 13 & 39: tab_view.set('activeIndex', 2); // Edit Pages tab.

	my($head_init) = <<EJS;

var new_site_tab = new YAHOO.widget.Tab
({
	label: "New Site",
	content: '$new_site_html',
	active: $site_count ? false : true
});
tab_view.addTab(new_site_tab);
new_site_tab.addListener('click', make_new_site_name_focus);

var edit_site_tab = new YAHOO.widget.Tab
({
	label: "Edit Site",
	content: '$search_html',
	active: $site_count ? true : false
});
tab_view.addTab(edit_site_tab);
edit_site_tab.addListener('click', make_search_name_focus);

var edit_page_tab = new YAHOO.widget.Tab
({
	label: "Edit Pages",
	content: '<div id="update_page_div"><h3 align="center">Acess via Edit Site...</h3></div>',
	active: false
});
tab_view.addTab(edit_page_tab);
edit_page_tab.addListener('click', make_update_page_name_focus);

var edit_content_tab = new YAHOO.widget.Tab
({
	label: "Edit Content",
	content: '<div id="update_content_div"><h3 align="center">Access via Edit Pages...</h3></div>',
	active: false
});
tab_view.addTab(edit_content_tab);
edit_content_tab.addListener('click', make_update_content_name_focus);

var about_tab = new YAHOO.widget.Tab
({
	label: "About",
	content: '$about_html',
	active: false
});
tab_view.addTab(about_tab);

// Add tab view to document.

tab_view.appendTo("tabview_container");

if ($site_count)
{
	make_search_name_focus();
}
else
{
	make_new_site_name_focus();
}

EJS

	return $head_init;

} # End of build_head_init.

# -----------------------------------------------

sub build_head_js
{
	my($self) = @_;

	$self -> log(debug => 'build_head_js()');

	my($view_js) =
		$self -> param('view') -> content -> build_head_js .
		$self -> param('view') -> page -> build_head_js .
		$self -> param('view') -> search -> build_head_js .
		$self -> param('view') -> site -> build_head_js;

	# These things are being declared within the web page's head.

	my($js) = <<EJS;
$view_js

function make_new_site_name_focus(eve)
{
	document.new_site_form.name.focus();
}

function make_search_name_focus(eve)
{
	document.search_form.name.focus();
}

function make_update_content_name_focus(eve)
{
	document.update_content_form.head.focus();
}

function make_update_page_name_focus(eve)
{
	document.update_page_form.name.focus();
}

function make_update_site_name_focus(eve)
{
	document.update_site_form.name.focus();
}

var tab_view = new YAHOO.widget.TabView();

EJS

	return $js;

} # End of build_head_js.

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> log(debug => 'display()');

	# Generate the web page itself. This is not loaded by sub cgiapp_init(),
	# because, with AJAX, we only need it the first time the script is run.

	my($config) = $self -> param('config');
	my($param)  =
	{
	 css_url           => $$config{css_url},
	 head_init         => mark_raw($self -> build_head_init),
	 head_js           => mark_raw($self -> build_head_js),
	 validator_css_url => $$config{validator_css_url},
	 validator_js_url  => $$config{validator_js_url},
	 yui_url           => $$config{yui_url},
	};

	return $self -> param('templater') -> render('web.page.tx', $param);

} # End of display.

# -----------------------------------------------

1;
