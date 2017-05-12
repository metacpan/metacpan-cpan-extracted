package Apache::Wyrd::Site::Widget;
use strict;
use warnings;
our $VERSION = '0.98';
use base qw(Apache::Wyrd::Interfaces::Indexable Apache::Wyrd::Interfaces::Mother);
use Digest::SHA qw(sha1_hex);

=pod

=head1 NAME

Apache::Wyrd::Site::Widget - Abstract dynamic element of a page

=head1 SYNOPSIS

  package BASENAME::SampleWidget;
  use base (Apache::Wyrd::Site:::Widget);

  sub _format_output {
    my ($self) = @_;
    my $text = '';
    #...
    ##---generate some occasionally-changing content here---
    #...
    $self->_data($text);
  }
  ....

  <BASENAME::Page>
    <BASENAME::SampleWidget />
  </BASENAME::Page>

=head1 DESCRIPTION

Widgets are a generic class of objects which work with
C<Apache::Wyrd::Site::Page> Wyrds, primarily to generate content on a page
which may change through time and viewings.  This makes the indexing of
pages problematic, since a Page object by default looks only to its own
file modification date to determine if it has been changed and needs
re-indexing.  A Widget will keep track of its own content in a similar
way as the page (see C<Apache::Wyrd::Site::WidgetIndex>), triggering an
update in its parent Page Wyrd when it's content changes.  It does this
by changing the (internal) modification time value of the parent to the
current time as defined by the builtin C<time()> call.

So, if you want content from external sources to be indexed as a page is
indexed, the wyrd which generates the content should be a sub-class of
C<Apache::Wyrd::Site::Widget>.

=head2 HTML ATTRIBUTES

=over

=item name/title

All widgets MUST have either a title or a name attribute, as required by the
WidgetIndex.  Without one or the other, widgets may erroneously trigger a
re-index of the Page object.

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (Apache::Wyrd::Site::WidgetIndex ref) C<index> (void)

Returns a Widget Index reference.  If the package
E<lt>BASENAMEE<gt>::Site::WidgetIndex exists, it will attempt to call
C<new()> to get this reference.  If not, it will assume that the widget
index should be located in the /var directory under the document root.  It
is recommended that a subclass of this object initializes the WidgetIndex
explicitly.

=cut

sub index {
	my ($self) = @_;
	return undef if ($self->_flags->noindex);
	$self->_error("Widgets are better written by subclassing Apache::Wyrd::Site::Widget and defining an index() method as an interface that returns a WidgetIndex for your site.");
	my $formula = $self->base_class . '::Site::WidgetIndex';
	eval ("use $formula") unless ($INC{$formula});
	my $index = undef;
	if ($@) { #assume a failed compile means no WidgetIndex is defined
		$index = Apache::Wyrd::Site::WidgetIndex->new({file => $self->dbl->req->document_root . '/var/widgetindex.db'});
	} else {
		eval ('$index=' . $formula . '->new()');
	}
	return $index;
}

=item (void) C<index_digest> (void)

Returns a fingerprint of the content (using sha1_hex by default) for storage
in the index.  For internal use.


=cut

sub index_digest {
	my ($self) = @_;
	return sha1_hex($self->_data);
}

=item (void) C<index_name> (void)

Returns the indexable name of the widget for storage in the index.  For
internal use.

=cut

sub index_name {
	my ($self) = @_;
	return $self->dbl->self_path . ':' . ($self->{'name'} || $self->{'title'});
}

=pod

=item (void) C<_change_state> (void)

If the widget makes use of Widget controls (Apache::Wyrd::Site::WidgetControl),
their state is found and set by the Page Wyrd by calling this method.  Widgets
should call _change_state() during the _format_output phase.  This method does
nothing other than call the parent's C<get_state> method (see
C<Apache::Wyrd::Site::Page>) and immediately follow it by a call to it's own
C<_set_children> method (see C<Apache::Wyrd::Interfaces::Mother>).

If, however, the widget must make a decision more complicated than a simple
radio-button-style switch between alternate values for given attributes, it
should first call get_state to change the value of it's attributes to reflect
the current input of the Widget Controls, then having made any adjustments based
on this input, should call _set_children after these adjustments are made.

=cut

sub _change_state {
	my ($self) = @_;
	if (UNIVERSAL::can($self->_parent, 'get_state')) {
		$self->_parent->get_state($self);
	} else {
		$self->_warn('Parent cannot get_state().  Ignoring state of Widget Controls.');
	}
	$self->_set_children;
}

=pod

=item (void) C<_process_child> (void)

Sets the default attributes for the widget from the Widget Controls.  The
first Widget Control will provide a value for it's attribute if it has not
been set in the Widget Object already.  Any Widget Controls flagged
"default" will override the current value, with priority to the last one so
flagged.

=cut

sub _process_child {
	#As children are added, change the attributes based on them if they are undefined.
	#This allows default values to be arrived at.  A child's flag of default overrides
	#the initial value.
	my ($self, $child) = @_;
	my $attribute = $child->{'attribute'};
	my $value = $child->{'value'};
	$self->{$attribute} ||= $value;
	#set default values based on self values;
	$self->{$attribute} = $value if ($child->_flags->default);
}

=pod

=back

=head1 BUGS/CAVEATS

Reserves both the _setup and _generate_output methods.

=cut

sub _setup {
	my ($self) = @_;
	unless ($self->_flags->noindex) {
		$self->{'widgetindex'} = $self->index;
	}
}

sub _generate_output {
	my ($self) = @_;
	unless ($self->_flags->noindex) {
		$self->_error($self->class_name . " must have a name or title attribute or it will slow down indexing") 
			unless ($self->{'title'} or $self->{'name'});
		my $changed = $self->widgetindex->update_entry($self);
		if ($changed) {
			#fool the parent Page object into thinking it's changed.
			$self->dbl->{'mtime'} = time;
		}
	}
	return $self->_data;
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Index

General-purpose metadata index

=item Apache::Wyrd::Page

Base Wyrd for Web site pages

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;