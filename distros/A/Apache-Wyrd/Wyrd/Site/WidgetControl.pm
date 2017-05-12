package Apache::Wyrd::Site::WidgetControl;
use base qw(Apache::Wyrd::Interfaces::Setter Apache::Wyrd);
use Apache::Wyrd::Services::SAK qw(env_4_get);
use strict;
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Site::WidgetControl - Links that change a Widget's State

=head1 SYNOPSIS

  <BASENAME::SomeWidget>
    <BASENAME::Site::WidgetControl attribute="color" value="blue" flags="default">
      Try this Widget in BLUE
    </BASENAME::Site::WidgetControl>
    <BASENAME::Site::WidgetControl attribute="color" value="green">
      Try this Widget in GREEN
    </BASENAME::Site::WidgetControl>
    <BASENAME::Site::WidgetControl attribute="color" value="red">
      Try this Widget in RED
    </BASENAME::Site::WidgetControl>
  </BASENAME::SomeWidget>

=head1 DESCRIPTION

A WidgetControl provides controlled access to attributes of a Widget via a
self-maintaining set of links.  These links provide encoded page-state data
via a link to the Apache::Wyrd::Site::Page object of the target of that
link.  Using this page-state data, an attribute of the Widget in which the
WidgetControl is enclosed can indipendently maintain its state from other
widgets on the page, while allowing some element of it to be changed for a
dynamic purpose, such as changing the sort order of a Pull, or altering the
coloration or units of a chart.

To do so, it must return it's enclosed HTML "_data" in the final output,
since the WidgetControl objects it encloses will have provided themselves as
links in that HTML text.

=head2 HTML ATTRIBUTES

=over

=item attribute

Which attribute of the enclosing widget is manipulated by this WidgetControl.

=item value

The value of that attribute if this Control's link is clicked.

=item off/on

How this Control should look (i.e. the HTML) when waiting to be clicked on, or if just clicked on.  In general, it is simpler just to assign a class to the anchor tag and provide this class as an attribute to the WidgetControl.

=back

=head2 FLAGS

=over

=item default

Designate this WidgetControl out of all others in this widget as the
"default" value.

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (scalar) C<url> (void)

create the href of the link which will provide the state data.  The default is to bundle up all CGI attributes other than _page_state and put in placemarkers for the WidgetControl maintenance data.

=cut

sub url {
	my ($self) = @_;
	my $url = $self->dbl->self_path;
	my $args = $self->env_4_get('_page_state');
	$args = '&' . $args if ($args);
	$url . '?_page_state=#!#_wyrd_site_page_state#!#:$:switch' . $args . '#$:anchor';
}

sub inactive {
	my ($self, $string) = @_;
	if (defined($self->{'on'})) {
		return $self->{'on'};
	} else {
		return '<b>' . $string . '</b>';
	}
}

sub active {
	my ($self, $string) = @_;
	if (defined($self->{'off'})) {
		return $self->{'off'}
	} else {
		return '<a name="$:anchor" href="' . $self->url . '"?:class{ class="$:class"}>' . $string . '</a>';
	}
}

=pod

=back

=head1 BUGS/CAVEATS

Reserves the _setup and _format_output methods.

=cut

sub _setup {
	my ($self) = @_;
	$self->{'_on'} = 0;
	$self->_fatal('Must have an attribute') unless ($self->{'attribute'});
	$self->{'value'} = ($self->{'value'} || $self->_data || $self->_parent->{$self->{'attribute'}});
	if ($self->_flags->signal) {
		$self->{'value'} = $self->_parent->{$self->{'value'}};
	}
	$self->{'_original'} = $self->_data;
	$self->_data('$:' . $self->_parent->register_child($self));
}

sub final_output {
	my ($self) = @_;
	my $string = $self->{'_original'};
	return '' unless ($string);
	if ($self->{'_on'}) {
		$string = $self->inactive($string);
	} else {
		$string = $self->active($string);
	}
	#take only the pre-colon part of the switch to identify the widget with via anchor name
	my ($anchor) = split /:/, $self->{'_switch'};
	$anchor = 'widget_' .$anchor;
	return $self->_set(
		{
			switch => $self->{'_switch'},
			anchor => $anchor,
			class => $self->{'class'},
		}, $string);
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Site::Widget

Abstract dynamic element of a Page

=item Apache::Wyrd::Site::Page

Construct and track a page of an integrated site

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;