
package CouchDB::Client::DesignDoc;

use strict;
use warnings;

our $VERSION = $CouchDB::Client::VERSION;
use base qw(CouchDB::Client::Doc);
use URI::Escape qw(uri_escape_utf8);

use Carp            qw(confess);

sub new {
	my $class = shift;
	my %opt = @_ == 1 ? %{$_[0]} : @_;

	my $self = $class->SUPER::new(\%opt);
	confess "Design doc ID must start with '_design/'" unless $self->{id} =~ m{^_design/};
	$self->{data}->{language} ||= 'javascript';
	return bless $self, $class;
}

sub views { @_ == 2 ? $_[0]->{data}->{views} = $_[1] : $_[0]->{data}->{views}; }


sub contentForSubmit {
	my $self = shift;
	my $content = $self->SUPER::contentForSubmit();
	delete $content->{attachments};
	return $content;
}

sub listViews {
	my $self = shift;
	return keys %{$self->data->{views}};
}

sub queryView {
	my $self = shift;
	my $view = shift;
	my %args = @_;

	confess("No such view: '$view'") unless exists $self->views->{$view};
	my $sn = $self->id;
	$sn =~ s{^_design/}{};
	$sn = uri_escape_utf8($sn);

	# The uri path for views changed and the parameter "count" has been renamed "limit"
	# between v0.8 and v0.9 and above.  (issue #48407 and #49759 in RT)
	my ($M,$m,undef) = split(/\./,$self->{db}->{client}->serverInfo()->{version});

	my $vp;
	if ($M > 0 || ($M == 0 && $m >= 9)) {
		$vp = "/_design/$sn/_view/$view";
		if (defined($args{count})) {
			$args{limit} = $args{count};
			delete $args{count};
		}
	}
	else {
		$vp = "/_view/$sn/$view";
		if (defined($args{limit})) {
			$args{count} = $args{limit};
			delete $args{limit};
		}
	}

	my $qs = %args ? $self->{db}->argsToQuery(%args) : '';

	my $res = $self->{db}->{client}->req('GET', $self->{db}->uriName . $vp . $qs);
	confess("Connection error: $res->{msg}") unless $res->{success};
	return $res->{json};
}

1;

=pod

=head1 NAME

CouchDB::Client::DesignDoc - CouchDB::Client design documents (views)

=head1 SYNOPSIS

	$dd->listViews;
	# ...
	my $res = $dd->queryView('all');

=head1 DESCRIPTION

This module represents design documents (containing views) in the CouchDB database.

Design documents are basically documents that have some fields interpreted specifically
in CouchDB. Therefore, this is a subclass of C<CouchDB::Client::Doc> and has all of the
same functionality except that it will not save attachments.

=head1 METHODS

=over 8

=item new

Constructor. Same as its parent class but only accepts IDs that are valid for design
documents.

=item views

Read-write accessor for the views. It needs to be in the format that CouchDB expects.
Note that this only changes the views on the client side, you have to create/update
the object for it to be stored.

=item contentForSubmit

Same as its parent class but removes attachments.

=item listViews

Returns a list of all the views defined in this design document.

=item queryView $VIEW_NAME, %ARGS?

Takes the name of a view in this design document (an exception will be thrown if it isn't
there) and an optional hash of query arguments as supported by CouchDB (e.g. startkey,
descending, count, etc.) and returns the data structure that the server returns. It will
throw exceptions for connection errors too.

The query parameters are expected to be expressed in a Perlish fashion. For instance if
one has a boolean value you should use Perl truth and it will work; likewise if you are
using multiply-valued keys then simply pass in an arrayref and it will be converted and
quoted properly.

The data structure that is returned is a hashref that will contain C<total_rows> and
C<offset> keys, as well as a C<rows> field that contains an array ref being the
resultset.

=back

=head1 AUTHOR

Robin Berjon, <robin @t berjon d.t com>
Maverick Edwards, <maverick @t smurfbane d.t org> (current maintainer)

=head1 BUGS

Please report any bugs or feature requests to bug-couchdb-client at rt.cpan.org, or through the
web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CouchDB-Client.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Robin Berjon, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as
Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may
have available.

=cut
