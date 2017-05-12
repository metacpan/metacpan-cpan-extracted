package Apache::Wyrd::Site::Page;
use strict;
use base qw(
	Apache::Wyrd::Interfaces::IndexUser
	Apache::Wyrd::Interfaces::Indexable
	Apache::Wyrd::Interfaces::Setter
	Apache::Wyrd
);
use Apache::Wyrd::Services::SAK qw(token_parse strip_html);
use Apache::Wyrd::Services::FileCache;
use Digest::SHA qw(sha1_hex);
our $VERSION = '0.98';

#state of the widgets is stored by an alphanumeric code where a=1 and Z=62, limiting
#widget controls to 62 states and widgets to 62 controls
my @encode = split //, 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
my $counter = 0;
my %decode = map {$_, $counter++} @encode;

=pod

=head1 NAME

Apache::Wyrd::Site::Page - Construct and track a page of an integrated site

=head1 SYNOPSIS

  <BASENAME::Page
    title="A Random Page"
    tags="random, sample, system"
    description="This is a sample page."
  >
    Body of the page here...
  </BASENAME::Page>

=head1 DESCRIPTION

Page is the fundamental unit in the Apache::Wyrd::Site hierarchy.  It
generates the layout of and the meta-information for a "web page" and
informs the index of the site about its self and its relationship to other
pages.

Page is usually used to represent a full page of HTML, in a single file,
referred to by a single URL which needs to be find-able by other objects on
the site.  Consequently, it is almost always seen as the outermost Wyrd on a
page of HTML.  It's attributes are, for the most part, those that a page of
HTML may have in it's HEAD section, namely a title, keywords, description,
and other meta-data.

An exception is when used as a proxy, in which case it stands in for another
file/distinct location of the site, or some grouping of like files.  In this
behavior, it informs the index about it's original file's meta-data, text,
etc.  This provides a simple method of overcoming the opaqueness of some
file formats to being indexed for word and meta-data content.  This is not
the default behaviour.

Page is rarely used in its "default" state, meaning that the logic of the
layout or construction of a site is best served by working the special
behaviors into a subclass of the Page Wyrd.  Consequently, the
_format_output method of this Wyrd can generally be safely overridden in a
subclass, as long as the index's update_entry is called with the page as the
argument. (This call is, of course, only necessary if you plan to make use
of Pulls and word-search indexing.)

A page is also the parent of and controller of the Widget wyrds which exist
on it.  Several of the internal methods of the Page Wyrd perform the
housekeeping functions for Widgets, and unless Widgets and WidgetControls
are used, can be safely ignored.

=head2 HTML ATTRIBUTES

=over

=item name, timestamp, digest, data, children

These are "reserved" attributes which are auto-generated in a format to suit
the C<Apache::Wyrd::Services::Index> object.  They should not be defined in
the HTML.  See C<Apache::Wyrd::Interfaces::Indexable>.

=item parent

The page directly above this one in the navigation-tree hierarchy.

=item keywords

Key words of the page, used for the keywords meta tag in the header.

=item description

A description of the page.

=item published

The publication date in YYYYMMDD format.

=item section

The section of the site, i.e. first branch of the tree this page belongs to in
the navigational hierarcy.  See C<Apache::Wyrd::Site> and C<Apache::Wyrd::Site::NavPull>.

=item allow/deny

Authorization tags.  The default C<Apache::Wyrd::Services::Auth>,
C<Apache::Wyrd::User>, and related classes operate by checking levels of
authorization.  Users are assigned levels and what they are allowed to
access depend on what levels are required.  If "allow" is not set, the page
is considered public.  If it is, only authenticated users with the security
level indicated by the tags are allowed access.  If "deny" is set, those
users who would normally have access by virtue of the allow value are denied
if they match one of the deny tags.

=item tags

Tokens used to classify the Page by subject matter.  These are used by
C<Apache::Wyrd::Site::TagPull> to create lists of documents by subject
metadata.

=item original

The location of the document if this page is proxying for another document. 
For example, if the document is located site-root-relative pdfs/thispdf.pdf,
the attribute would be "/pdfs/thispdf.pdf".  You would then want to set the
doctype to "PDF" so that your pull can indicate that the doctype is PDF, not
HTML.

=item doctype

The type of document (defaults to "HTML").

=item expires

A date attribute.  Not currently used by the default Wyrds in this
hierarchy, but often proves useful in determining when something should no
longer be considered new.

=item longdescription

In some pulls, a longer description can be useful.  This allows that
description to be used, and defaults to the value of "description" when it
is not provided.

=item shorttitle

Especially in NavPulls, the actual title of a page may be too cumbersome. 
This allows for a shorter alternate.

=item etc., etc.,

Other indexible attributes may be added in subclasses.  Note that the
attributes should be given as parameters to the index object (so it knows to
look for and store them).  If the index object is SQL-type, the attributes
should be added to the underlying main table (normaly _wyrd_index), an
index_xxxxx method needs to be made to properly supply that value to the
index, and either the more_info method be defined to add all the data from
these attributes to the data fingerprint, or the index_digest call
SUPER::index_digest with the additional data as an argument (single scalar).
 See C<Apache::Wyrd::Services::Index> and
C<Apache::Wyrd::Interfaces::Indexible>.

=back

=head2 FLAGS

=over

=item nofail

If a document is supplied to the "original" attribute and the document does
not exist, Page will normally terminate with a fatal error.  This forces
Page to ignore the error.  It's normal use is to allow external
sites/documents to be referenced by a Page Wyrd (i.e. by using the full
URL).

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (void) C<_init_state> (void)

Internal method for initializing the widget substructure.

=cut

sub _init_state {
	my ($self) = @_;
	#initialize the counter which will record the number of widgets
	$self->{'_state_counter'} = 0;

	#if the state information has arrive via CGI, set the _override marker to indicate that
	#the new state will have precedence over the default state, and decode that information
	#into the _state holding key
	my $string = $self->{'_override'} = $self->_state_string;
	$self->{'_state'} = $self->_decode_state($string) if ($string);
}

=item (scalar) C<_state_digit> (void)

=item (scalar) C<_state_symbol> (void)

Internal methods for mapping widget states to values

=cut

#return the number associated with the character
sub _state_digit {
	return $decode{$_[1]};
}

#return the nth character
sub _state_symbol {
	return $encode[$_[1]];
}

=item (scalar) C<_decode_state> (void)

=item (scalar) C<_encode_state> (void)

=item (scalar) C<_state_string> (void)

Internal methods for interacting with state values

=cut

sub _decode_state {
	my ($self, $string) = @_;
	#warn $string;

	#The state is returned via a CGI string, which has a colon.  To the left of the colon is the
	#state of the page prior to this request.  The status on the right is the part which changes.
	my ($oldstate, $widget, $newstate) = split ':', $string;
	my @state = split //, $oldstate;
	my @array = ();
	while (@state) {

		#read off a char.  It represents the number of controls on the widget.
		my $controls = $self->_state_digit(shift @state);
		#warn $controls;
		my @controls = ();
		while ($controls) {
			#read off as many chars as there are controls
			push(@controls, $self->_state_digit(shift @state));
			$controls--;
		}
		push @array, \@controls;
	}

	#warn 'Decoded state: ' . Dumper(\@array);
	#The status on the right splits into "what control" and "what state"
	my ($control, $value) = split //, $newstate;

	#map this value over the previous value
	$array[$widget]->[$self->_state_digit($control)]=$self->_state_digit($value);
	#warn 'Decoded state, with change: ' . Dumper(\@array);
	return \@array;
}

sub _encode_state {
	my ($self) = @_;

	#state emerges from the _register_child method of the widgets as an array of 'widgets'
	#each of which are an array of the current value of all widget controls.
	my $state = $self->{'_state'};
	#warn 'Pre-encoded state: ' . Dumper($state);

	#state will be encoded as:
	#	first char: number of widget controls
	#	second char: state of first widget
	#	third char: state of second widget
	#	fourth char: .....
	my @sequence = ();

	foreach my $widget (@$state) {
		#go through each widget (which have registered their controls via the
		#widget controls' _register_child method), and encode it by first taking
		#the number of controls in the widget and encoding that.
		push @sequence, $self->_state_symbol(scalar(@$widget));

		foreach my $value (@$widget) {
			#then put the value out of the possible values into the next char
			#until all the widget controls are accounted for.
			push @sequence, $self->_state_symbol($value);
		}
	}
	return join '', @sequence;
}

#returns the value of the current CGI variable for the state.
sub _state_string {
	my ($self) = @_;
	return $self->dbl->param($self->_state_marker);
}

=pod

=item (void) C<_state_marker> (void)

Provides a string of characters which will be globally replaced at runtime in
order to maintain state between page-views.  All Widget Controls (see
C<Apache::Wyrd::Site::WidgetControl>) will need to include this in information
submitted to the next page view in order to maintain consistent state between
page views.

=cut

sub _state_marker {
	my ($self) = @_;
	return '#!#_wyrd_site_page_state#!#';
}

=pod

=item (void) C<_set_state> (void)

The process by which the placemarker for the current state (once built) is inserted into the page
final body.  The default is to use a s/// regular expression.

=cut

sub _set_state {
	my ($self) = @_;
	my $state = $self->_encode_state;
	my $marker = $self->_state_marker;
	$self->{'_data'} =~ s/$marker/$state/g;
}

=pod

=item (void) C<get_state> (void)

This method is called by Widgets on the page to determine their overall state.
The widget passes a reference to itself as the argument of the method.  The Page
Object uses this method to obtain information on Widgets on the page in order to
track their current state and to give their controls a switch to use to pass as
a CGI variable in order to manipulate this state, changing the attributes of the
Widget.

=cut

sub get_state {
	my ($self, $widget) = @_;
	#warn 'widget counter is ' . $self->{'_state_counter'};
	$widget->{'_widget_state_name'} = $self->{'_state_counter'};

	#if CGI data has been detected, prefer it over the default
	if ($self->{'_override'}) {

		#check to see if the widget in its default state registered itself on page load
		unless (ref($self->{'_state'}->[$self->{'_state_counter'}]) eq 'ARRAY') {
			#whoops!  the number of widgets has grown.  Assume the programmer knows
			#what is being done, so initialize an ARRAYREF for the widget, but log
			#this as an error anyway.
			$self->_error('Widget tracking state not initialized.  Assume widget number has grown');
			$self->{'_state'}->[$self->{'_state_counter'}] = $self->_read_widget_state($widget);
		}

		my @state = @{$self->{'_state'}->[$self->{'_state_counter'}]};#copy array to preserve actual state
		#hash of attributes under the control of widgetcontrols
		my %attr = ();

		#hash of the possible values the collective controls for a given attribute may have
		my %this_attr = ();
		my $attr_counter = 1;

		#go through each registered widget in order.
		foreach my $child (@{$widget->{'_children'}}) {
			#skip non-widget controls
			next unless UNIVERSAL::isa($child, 'Apache::Wyrd::Site::WidgetControl');

			#does this child have an attribute unlike other attributes?
			unless ($attr{$child->{'attribute'}}) {
				#assign it a number and indicate this attribute has been found
				$attr{$child->{'attribute'}} = $attr_counter++;
			}

			#make the child's "switch" out of the widget number, a colon,
			#the code for the attribute that's changing, and the value of
			#the choice of attribute.
			$child->{'_switch'} =  $self->{'_state_counter'}
								 . ':'
								 . $self->_state_symbol($attr{$child->{'attribute'}} - 1)
								 . $self->_state_symbol($this_attr{$child->{'attribute'}});
			if ($state[$attr{$child->{'attribute'}} - 1] == 0) {
				#warn 'found ' . $child->{'attribute'} . ' of ' . $child->{'value'};
				#we've hit the current state for that attribute, set the attribute of the widget to that value
				my $on_value = 1;
				$on_value = 0 if ($child->_flags->signal); #if a control is a signal, it's never "on", but sends a one-time value
				$child->{'_on'} = $on_value; 
				$widget->{$child->{'attribute'}} = $child->{'value'};
			} else {
				$child->{'_on'} = 0;
			}
			$this_attr{$child->{'attribute'}}++;
			$state[$attr{$child->{'attribute'}} - 1]--;
		};
	} else {
		#We don't know the state.  Read it off of the defaults
		$self->{'_state'}->[$self->{'_state_counter'}] = $self->_read_widget_state($widget);
	}
	$self->{'_state_counter'}++;
}

=pod

=item (void) C<_read_widget_state> (void)

The function by which each widget is assigned widget controls and records which values those widget
controls have.  Additionally, what encoding the widget controls will pass as CGI variables in order
to manipulate their respective widget's state are generated during this attribute/value permutation
count.

=cut

sub _read_widget_state {
	my ($self, $widget) = @_;
	my @state = ();
	my %attr = ();
	my %this_attr = ();
	my $attr_counter = 1;
	#Go through each child (Apache::Wyrd::Site::WidgetControl) of the widget
	foreach my $child (@{$widget->{'_children'}}) {
		#keep track of which attribute number it is, since this will need to be translated
		unless ($attr{$child->{'attribute'}}) {
			$attr{$child->{'attribute'}} = $attr_counter++;
		}
		#If the attribute value is not yet initialized, use the value of the widget control
		$widget->{$child->{'attribute'}} ||= $child->{'value'};
		#If one child is the "default", i.e. flagged default, that value overrides the first-value-found above
		$widget->{$child->{'attribute'}} = $child->{'value'} if ($child->_flags->default);
		#if the current value of the attribute matches the value of the widget control, the state of the
		#widget control is set to "on".
		if ($widget->{$child->{'attribute'}} eq $child->{'value'}) {
			$state[$attr{$child->{'attribute'}} - 1] = $this_attr{$child->{'attribute'}};
			$child->{'_on'} = 1;
		}
		#give the child a "name" it passes via link to a newly loaded page.  The name is the encoding of the
		#current state plus the new encoding for the value to be changed.  At this point, the page state is not
		#built, so the placemarker for the page is used for the first portion (up to the :) of the link.
		$child->{'_switch'} =  $self->{'_state_counter'}
							 . ':'
							 . $self->_state_symbol($attr{$child->{'attribute'}} - 1)
							 . $self->_state_symbol($this_attr{$child->{'attribute'}});
		#and increment the attribute counter for the next widgetcontrol.
		$this_attr{$child->{'attribute'}}++;
	};
	return \@state
}

=item (scalar) C<_check_auth> (void)

Examine the allow/deny state of the page and determine whether the user has the
clearance to view the page.  These interact with Apache::Wyrd::User-derived
objects using the Apache::Wyrd::Services::Auth conventions to determine the
user's current authorization levels.  If the page is forbidden to the public, it
will use the dir_config value "UnauthURL" to direct them to an "unauthorized
page", presumably to be prompted to log in, or failing the existence of that,
simply return an error message.

=cut


sub _check_auth {
	my ($self) = @_;
	#warn 'here, authorizing with an allow of ' . $self->{'allow'};
	if ($self->{'allow'}) {
		return undef if($self->_override_auth_conditions);
		unless ($self->dbl->user->username) {
			#warn 'here, about to ask for a redirect';
			my $hash = $self->_auth_hash;
			while (my ($key, $value) = each %$hash) {
				$self->dbl->req->dir_config->add($key, $value);
			}
			#$self->dbl->req->dir_config->add('AuthLevel', $self->{'allow'});
			$self->abort('request authorization');
			die "abort failed.";
		}
		if ($self->dbl->user->auth($self->{'allow'}, $self->{'deny'})) {
			return;
		}
		my $redirect = $self->dbl->req->dir_config('UnauthURL');
		if ($redirect) {
			$self->abort($redirect);
			die "abort failed.";
		}
		$self->_data($self->_unauthorized_text);
	}
	#warn 'here about tor return from check_auth';
	return;
}

=item (scalar) C<_override_auth_conditions> (void)

Override the default authorization behavior.  The default behavior is to check
the id against the dir_config values for "trusted_ipaddrs", a
whitespace-separated list.

=cut

sub _override_auth_conditions {
	my ($self) = @_;
	my $addrs = $self->dbl->req->dir_config('trusted_ipaddrs');
	return 0 unless ($addrs);
	my @trusted_ips = split /\s+/, $addrs;
	my $ip = $self->dbl->req->connection->remote_addr;
	return 1 if (grep {$_ eq $ip} @trusted_ips);
	return 0;
}

=item (scalar) C<_unauthorized_text> (void)

The error message to be returned when no UnauthURL is set.

=cut

sub _unauthorized_text {
	my ($self) = @_;
	return '<h1>Unauthorized</h1><hr>You are not authorized to view this document';
}

=item (void) C<_page_edit> (void)

A hook method for pages which interact with some sort of content management editing facility.

=cut

sub _page_edit {
	my ($self) = @_;
	return;
}

=item (void) C<_process_template> (void)

A hook method for how to assemble the body section of the page from the
template.  Defaults to replacing the string _INSERT_TEXT_HERE_ with the
enclosed text.

=cut

sub _process_template {
	my ($self, $template) = @_;
	$template =~ s/_INSERT_TEXT_HERE_/$$self{_data}/;
	$self->{_data} = $template;
}

=item (array) C<_attribute_list> (void)

=item (array) C<_map_list> (void)

List of those attributes supported by this Page object that are tracked in
the the attributes of the Index object that supports it.  The default is to
use the Index object's attribute and map lists, respectively.  See
C<qw(Apache::Wyrd::Site::Index)> and C<qw(Apache::Wyrd::Services::Index)>.

=cut

#index-dependent attribute list
sub _attribute_list {
	my ($self) = @_;
	return ($self->index->attribute_list);
}

sub _map_list {
	my ($self) = @_;
	return $self->index->map_list;
}

#overloads Indexable

=item (scalar) C<index_digest> (void)

As in C<Apache::Wyrd::Interfaces::Indexable>, provides the raw data to be
considered in generating the "fingerprint" that is used to determine if this
page has been changed, and consequently requires re-indexing.

=cut

sub index_digest {
	my ($self, $extra) = @_;
	$extra ||= '';
	return $self->SUPER::index_digest(
		  $self->index_parent
		. $self->index_published
		. $self->index_section
		. $self->index_allow
		. $self->index_deny
		. $self->index_tags

		. $self->index_doctype
		. $self->index_expires
		. $self->index_longdescription
		. $self->index_shorttitle

		. $self->more_info
		. $extra
	);
}

=item (scalar) C<more_info> (void)

A hook method for adding information to the fingerprint for C<index_digest>.

=cut

sub more_info {
	return;
}

=item (scalar) C<index_*> (void)

Methods used to provide this fingerprint data, per
C<Apache::Wyrd::Interfaces::Indexable>.

One of the default methods provided in this class is C<index_children>,
which also provides for the arbitrary order of children of a parent.  See
C<Apache::Wyrd::Site::NavPull> for an explanation of this feature.

Also by default, the C<index_name> method will return the "original"
attribute if set, to allow the page to proxy for another document.

=cut

#handled by Indexable: name reverse timestamp digest data count title keywords description

#Abstract Page attributes: parent file published section allow deny tags children

sub index_name {
	my ($self) = @_;
	return $self->{'original'} || $self->SUPER::index_name();
}

sub index_parent {
	my ($self) = @_;
	return $self->{'parent'};
}

sub index_file {
	my ($self) = @_;
	return $self->dbl->self_path;
}

sub index_published {
	my ($self) = @_;
	return $self->{'published'};
}

sub index_section {
	my ($self) = @_;
	return $self->{'section'};
}

sub index_allow {
	my ($self) = @_;
	return $self->{'allow'};
}

sub index_deny {
	my ($self) = @_;
	return $self->{'deny'};
}

sub index_tags {
	my ($self) = @_;
	return $self->{'tags'};
}

sub index_children {
	my ($self) = @_;
	return $self->{'parent'};
}

sub handle_children {
	my ($self, $id, $parent) = @_;
	my @parents = token_parse($parent);
	my %score = ();
	foreach $parent (@parents) {
		($parent, my $score) = split(':', $parent);
		$score{$parent} = $score;
	}
	$self->index->index_map('children', $id, \%score);
}

#The list goes on and on

sub index_doctype {
	my ($self) = @_;
	return ($self->{'doctype'} || 'HTML');
}

sub index_expires {
	my ($self) = @_;
	return $self->{'expires'};
}

sub index_longdescription {
	my ($self) = @_;
	return ($self->{'longdescription'} || $self->{'description'});
}

sub index_shorttitle {
	my ($self) = @_;
	return ($self->{'shorttitle'} || $self->{'title'});
}

=back

=head1 BUGS/CAVEATS

Reserves the _format_output and _generate_output methods.

=cut

sub _setup {
	my ($self) = @_;
	$self->_init_state;
	$self->_check_auth;
	$self->_init_index;
	$self->_page_edit;
	unless ($self->_flags->nofail) {
		my $name = $self->index_name;
		if ($name eq $self->{'original'}) {
			if ($name =~ m/^\//) {
				unless (-f $self->dbl->req->document_root . $name) {
					$self->_raise_exception("Original file doesn't exist ($name).  Use the nofail flag to override this error.");
				}
			}
		}
	}
}

sub _format_output {
	my ($self) = @_;
	my $response = $self->index->update_entry($self);
	$self->_info($response);
	$self->_set_state;
	my $head = join ('/', $self->dbl->req->document_root, 'lib/head.html');
	my $file = join ('/', $self->dbl->req->document_root, 'lib/body.html');
	my $template = $self->get_cached($head);
	my $title = $self->{'title'};
	my $keywords = $self->{'keywords'};
	my $description = $self->{'description'};
	my $meta = $self->{'meta'};
	$template =~ s/<\/head>/\n$meta\n<\/head>/ if ($meta);
	my $lib = $self->{'lib'};
	if ($lib) {
		my @inserts = token_parse($lib);
		foreach my $lib (@inserts) {
			$lib =  join ('/', $self->dbl->req->document_root, 'lib', $lib);
			$lib = $self->get_cached($lib);
			$template =~ s/<\/head>/$lib\n<\/head>/;
		}
	}
	$title =~ s/\s+/ /g;
	$keywords =~ s/\s+/ /g;
	$description =~ s/\s+/ /g;
	$template = $self->_set({title => strip_html($title), keywords => strip_html($keywords), description => strip_html($description)}, $template);
	$template .= $self->get_cached($file);
	$self->_process_template($template);
	return;
}

sub _generate_output {
	my ($self) = @_;
	$self->_dispose_index;
	return $self->SUPER::_generate_output;
}


=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Services::Index

=item Apache::Wyrd::Services::MySQLIndex

=item Apache::Wyrd::Site::Index

=item Apache::Wyrd::Site::MySQLIndex

Various index objects for site organization.

=item Apache::Wyrd::Site

Documentation about this sub-hierarchy

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;
