package Apache::Wyrd::Site::Pull;
use strict;
use base qw(Apache::Wyrd::Interfaces::IndexUser Apache::Wyrd::Interfaces::Setter Apache::Wyrd::Interfaces::Dater Apache::Wyrd);
use Apache::Wyrd::Services::SAK qw(token_parse);
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Site::Pull - Abstract class for Page Lists

=head1 SYNOPSIS

	#subclass Pull object to always ignore documents which have expired,
	#"expires" being an attribute of a Page object expressed in YYYYMMDD
	#form.
	package BASENAME::Pull;
	use base qw(Apache::Wyrd::Site::Pull);
	sub _date_fields {
		return ('published', 'expires');
	}

	sub _require_fields {
		return qw(expires);
	}

	sub _doc_filter {
		my $self = shift;
		my @docs = @_;
		my $today = $self->_today_yyyymmdd;
		@docs = grep {$_->{expires} > $today} @docs;
		return @docs;
	}

=head1 DESCRIPTION

Pull is an abstract ancestor class for NavPull and TagPull Wyrds which is
used to apply rules for all page entries in a site index which are to be
displayed on a page of that site.  See Apache::Wyrd::Site for details.

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (array) C<_process_docs> (array)

Apply some transformation to every index entry.  Accepts an array (as
returned by C<Apache::Wyrd::Site::Index::search()>), and returns a copy of
the array with the transformation applied.

The default transformation is to change every date field of the array into a
human-readable form, as Apache::Wyrd::Interfaces::Dater::_date_string() and
to delete any false-value keys, so that all
C<Apache::Wyrd::Interfaces::Setter> methods will work consistently.
Generally, if you want to override this method in a subclass, you should
finish with a call to the SUPER class unless you have made allowances for
this need (i.e. C<$self->SUPER::_process_docs(@docs)>).

=cut

sub _process_docs {
	my ($self, @docs) = @_;
	my @out = ();
	foreach my $doc (@docs) {
		foreach my $key (keys(%$doc)) {
			$$doc{$key} = $self->_date_string(split(/[,-]/, $$doc{$key})) if (grep {$_ eq $key} $self->_date_fields);
			delete $$doc{$key} unless ($$doc{$key});#undefine missing bits for setter
		}
		push @out, $doc;
	}
	return @out;
}

=item (array) C<_date_fields> (void)

The array of fields that should be transformed from the standard YYYYMMDD
string into human-readable dates.  Default is the single field "published". 
Override this method to change this list.

=cut

sub _date_fields {
	return qw(published);
}

=item (array) C<_require_fields> (void)

The array of fields that must be in any entry requested from the site index.
 Generally, this is not necessary, since all fields are returned by default
except those in C<_skip_fields>.

=item (array) C<_skip_fields> (void)

The array of fields that have no use to Pulls, and should not be included in
the returned array of entries.  Defaults to "data", "timestamp", and
"digest", which are usually of interest only to the site index.  (see
C<Apache::Wyrd::Site::Index>).  Override this method to change this list.

=cut

sub _skip_fields {
	return qw(data timestamp digest);
}

=item (hashref) C<_search_params> (void)

This returns the value of the parameter to send to the site index objects in
order to apply the terms of C<_skip_fields> and C<_require_fields>.  It is
used by the TagPull and NavPull objects in their requests for an array of
documents matching their criteria.  Override only if you need to extend this
distinction beyond C<_skip_fields> and C<_require_fields>.

=cut

sub _search_params {
	my ($self) = @_;
	my %params = ();
	if ($self->can('_skip_fields')) {
		my @skip = $self->_skip_fields;
		$params{'skip'} = \@skip;
	}
	if ($self->can('_require_fields')) {
		my @require = $self->_require_fields;
		$params{'require'} = \@require;
	}
	return \%params;
}

sub _generate_output {
	my ($self) = @_;
	$self->{'index'} = undef;
	return $self->{'_data'};
}

=item (array) C<_process_eventdate> (array)

If the index entry includes the field "eventdate", this method can be called
in order to filter out items which do not fall within an event window.  Note
that "eventdate" is not one of the default attributes of
C<Apache::Wyrd::Site::Page>, and you will need to add it to the attributes
list (see C<_attribs> in the documentation for the Page Wyrd) as well as
overriding the C<_process_docs> method in order to include this method in
the transformation.

Where the pull's attribute is set to a date range in the standard eight-day
form (see C<Apache::Wyrd::Interfaces::Dater>) with a comma (i.e.
eventdate="YYYYMMDD,YYYYMMDD"), the eventdate attribute of the page entry
will be compared to this window, and if there is no overlap, the document
will not appear in the Tag/NavPull.

Also acceptable as a value for eventdate is a positive or negative integer,
indicating so many days in the future or the past.

If unset, the Pull's contents will be unaffected.

=cut

sub _process_eventdate {
	my ($self, @docs) = @_;
	my $eventdate = $self->{'eventdate'};
	return @docs unless ($eventdate);
	my @localtime = localtime;
	$localtime[4]++;
	my ($year, $month, $day) = ($localtime[5], $localtime[4], $localtime[3]);
	my $today = $self->_num_today;
	my $yesterday = $self->_num_yesterday;
	my $tomorrow = $self->_num_tomorrow;
	$eventdate =~ s/yesterday/$yesterday/g;
	$eventdate =~ s/today/$today/g;
	$eventdate =~ s/tomorrow/$tomorrow/g;
	if ($eventdate =~ /^([+-])\d+$/) {
		my $begin = $self->_num_today;
		my ($nyear, $nmonth, $nday) = Add_Delta_Days($year, $month, $day, $eventdate);
		my $end = $self->_num_year($nyear, $nmonth, $nday);
		$eventdate = "$begin,$end";
	}
	#warn $eventdate;
	unless ($eventdate =~ /^(\d{8})?,(\d{8})?$/) {
		$self->_error("Illegal value for eventdate: $eventdate");
		return @docs;
	}
	my ($begin, $end) = split ',', $eventdate;
	#split returns strings; make sure perl treats these like numbers
	$begin += 0;
	$end += 0;
	@docs = grep {$_->{'eventdate'}} @docs;
	foreach my $doc (@docs) {
		($doc->{'eventbegin'}, $doc->{'eventend'}) = split ',', $doc->{'eventdate'};
		$doc->{'eventend'} ||= $doc->{'eventbegin'};
	}
	#map {warn $_->{'eventbegin'} . '-' . $_->{'eventend'}} @docs;
	@docs = grep {$_->{'eventend'} >= $begin} @docs if ($begin);
	@docs = grep {$_->{'eventbegin'} <= $end} @docs if ($end);
	return @docs;
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

=item Apache::Wyrd::Page

Base Wyrd for Web site pages

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;