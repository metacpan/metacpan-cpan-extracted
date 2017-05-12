use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Form::Preload;
our $VERSION = '0.98';
use base qw (Apache::Wyrd);

=pod

=head1 NAME

Apache::Wyrd::Form::Preload - Wyrd to load a Form Wyrd with existing data

=head1 SYNOPSIS

    <BASENAME::SQLForm index="user_id" table="users">
      <BASENAME::Form::Template name="password">
        <BASENAME::Form::Preload>
          <BASENAME::Defaults>
            select 'root' as user_id;
          </BASENAME::Defaults>
          <BASENAME::Query>
            select user_id from users where name='Groucho'
          </BASENAME::Query>
        </BASENAME::Form::Preload>
        <b>Enter Password:</b><br>
        <BASENAME::Input name="password" type="password" />
        <BASENAME::Input name="user_id" type="hidden" />
      </BASENAME::Form::Template>
      <BASENAME::Form::Template name="result">
        <H1>Status: $:_status</H1>
        <HR>
        <P>$:_message</P>
      </BASENAME::Form::Template>
    </BASENAME::SQLForm>

=head1 DESCRIPTION

Provides pre-loaded values to the Form Template in which it resides. The
query may return multiple values, in which case it will create an array
of hashrefs data structure appropriate for an
C<Apache::Wyrd::Input::Complex> input if it is flagged to do so with a
"complex" or "multiple" flag.

The preload requires an C<Apache::Wyrd::Query> object to be embedded in
it.  It can also accept a C<Apache::Wyrd::Defaults> object.

=head2 HTML ATTRIBUTES

NONE

=head2 PERL METHODS

NONE

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _setup and _generate_output methods.

=cut

sub _setup {
	my ($self) = @_;
	$self->{'query'} = undef;
	$self->{'defaults'} = 'no default available';
}

sub _generate_output {
	my ($self) = @_;
	my $data = $self->_get_data;
	foreach my $key (keys %$data) {
		$self->{'_parent'}->{'_variables'}->{$key} = $data->{$key};
	}
	$self->{'_parent'}->_flags->preload(1);
	$self->{'_parent'}->_flags->preloaded(1);
	return;
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=item Apache::Wyrd::Form

Build complex HTML forms from Wyrds

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

sub _get_data {
	my ($self) = @_;
	my $query = $self->{'query'};
	$self->_raise_exception("No query supplied to Preload") unless ($query);
	my $data = {};
	if ($query eq 'no default available') {
		$self->_warn("Query failed and there is no default");
		return $data;
	}
	my $data1 = $query->sh->fetchrow_hashref;
	my $data2 = undef;
	if ($data1) {
		#this step is mostly just to keep warnings quiet
		$data2 = $query->sh->fetchrow_hashref;
	} else {
		#The data will be new if there is no data
		$self->_get_defaults;
		return $self->_get_data;
	}
	if ($data2 or $self->_flags->multiple or $self->_flags->complex) {
		#if there is more than one record, assume a table is needed, and build a hash
		#with arrayrefs of all items of that query.  Presumably this will be used by a
		#set item, or if not, it will have to perform it's own conversions.
		my @remainder = ();
		while (my $item = $query->sh->fetchrow_hashref) {
			push @remainder, {%$item};#avoid the "copy the same hashref" error.
		}
		if ($self->_flags->complex) {
			my $param = $self->{'param'};
			$self->raise_exception('You must name the complex input in the preload using param="xxxx"')
				unless $param;
			my $entries = [];
			foreach my $item ($data1, $data2, @remainder) {
				push @$entries, $item;
			}
			$data->{$param} = $entries;
		} else {
			foreach my $item ($data1, $data2, @remainder) {
				foreach my $key (keys %$item) {
					$data->{$key} ||= [];#avoid typecast error on empty arrayrefs
					$data->{$key} = [@{$data->{$key}}, $item->{$key}]
				}
			}
		}
	} else {
		$data = $data1;
	}
	return $data;
}

sub _get_defaults {
	my ($self) = @_;
	$self->{'query'} = $self->{'defaults'};
}

sub register_query {
	my ($self, $query) = @_;
	$self->{'query'} = $query;
}

sub register_defaults {
	my ($self, $query) = @_;
	$self->{'defaults'} = $query;
}

1;