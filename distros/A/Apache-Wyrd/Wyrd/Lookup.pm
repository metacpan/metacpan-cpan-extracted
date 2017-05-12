#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Lookup;
our $VERSION = '0.98';
use base qw (Apache::Wyrd Apache::Wyrd::Interfaces::Setter);
use Apache::Wyrd::Services::SAK qw(:db);

=pod

=head1 NAME

Apache::Wyrd::Lookup - Wyrd for returning an SQL query result

=head1 SYNOPSIS

    <BASENAME::Lookup joiner=" : ">
      select * from people
    </BASENAME::Lookup>

    <BASENAME::Lookup
      query="select name from contact where name is like 'S%'">
      <b>$:name</b>
      <BASENAME::Var name="field_joiner"><BR></BASENAME::Var>
    </BASENAME::Lookup>

=head2 HTML ATTRIBUTES

=over

=item joiner

what to join multiple values with.  Defaults to ", ".  If either this or
record_joiner is set to "CSV", comma separated value format will be
used.  For the special characters, "CR" or "\r" will give carriage
return, and LF or "\n" will give a linefeed, the same for CRLF and
"\r\n".

=item field_joiner

an alias for C<joiner>

=item no_results

what HTML text to display when there are no results (optional).

=item record_joiner

what to join multiple values with.  Defaults to newline.

=item flags

=over

=item nojoin

Sets the record and field joiner to the null string.

=back

=back

=head2 PERL METHODS

I<(format: (returns) name (accepts))>

=over

=item (scalar) C<_default_joiner> (void)

method to be overridden in a subclass to change the default value for joiner.

=cut

sub _default_joiner {
	return ', ';
}

=item (scalar) C<_default_record_joiner> (void)

method to be overridden in a subclass to change the default value for joiner.

=cut

sub _default_record_joiner {
	return "\n";
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _format_output and _generate_output methods.

=cut

sub _format_output {
	my ($self) = @_;
	$self->{'field_joiner'} ||= ($self->{'joiner'} || $self->_default_joiner);
	$self->{'record_joiner'} ||= $self->_default_record_joiner;
	if ($self->_flags->nojoin) {
		$self->{'field_joiner'} = $self->{'record_joiner'} = '';
	}
	if (($self->{'field_joiner'} =~ /CSV/i) or ($self->{'record_joiner'} =~ /CSV/i)) {
		#to use CSV, the EOL must be one of the standard EOLs (which are interpolated below, in _interpolate_special)
		$self->{'record_joiner'} = "\n" unless ($self->{'record_joiner'} =~ /^\\r\\n|\\r|\r\n|\r/);
	}
	return;
}

sub _generate_output {
	my ($self) = @_;
	my $sh = undef;
	#set the query from the data if it is not set., then vice-versa
	$self->{'query'} ||= $self->{'_data'};
	my $debug_query = $self->{'query'};
	my $success = 0;
	my $final = '';
	#if there are more than one query, execute them in order, leaving one active handle,
	#and preserve the final query for debugging purposes.
	my @queries = split (';', $self->{'query'});
	foreach my $subquery (@queries) {
		next unless ($subquery);
		$self->_info("executing query: $subquery");
		$sh = $self->cgi_query($subquery);
		$debug_query = $subquery
	}
	#if we wind up with non-null data different than the query attribute, it's a template,
	#so treat it as one.
	if ($self->{'_data'} and ($self->{'query'} ne $self->{'_data'})) {
		$self->_info("Interpreting data as a templated query.");
		my @parts = ();
		while (my $data = $sh->fetchrow_hashref) {
			$success = 1;
			push @parts, $self->_set($data);
		}
		if (scalar(@parts) > 1) {
			#Make it a delinated list if it's multiple
			return $self->_do_join(@parts);
		}
		$final = $parts[0];
	#otherwise, execute the query, possibly joining the data
	} else {
		my @parts = ();
		$self->_info("Interpreting data as a raw query.");
		while (my $data = $sh->fetchrow_arrayref) {
			$success = 1;
			if (scalar(@$data) > 1) {
				push @parts, $self->_do_join(@$data);
			} else {
				push @parts, $$data[0];
			}
		}
		if (scalar(@parts) > 1) {
			#Make it a delinated list if it's multiple
			return $self->_do_record_join(@parts);
		}
		$final = $parts[0];
	}
	unless ($success) {
		my $template = $self->{'no_results'};
		#The query failed to produce results.  Report if there's an error
		if ($sh->err) {
			$self->_error("Error in query ($debug_query): " . $sh->errstr);
		} elsif ($template) {
			$self->_info("No results found, using no_results template.");
			return $template;
		}
	}
	return $final;
}


=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

sub _do_join {
	my ($self, @parts) = @_;
	my $joiner = $self->{'field_joiner'};
	$joiner = $self->_interpolate_special($joiner);
	if ($joiner =~ /^CSV$/i) {
		return join(',', map {"\"$_\""} map {$_ =~ s/"/\\"/g} @parts);
	}
	return join($joiner, @parts);
}

sub _do_record_join {
	my ($self, @parts) = @_;
	my $joiner = $self->{'record_joiner'};
	$joiner = $self->_interpolate_special($joiner);
	if ($joiner =~ /^CSV$/i) {
		return join(',', map {"\"$_\""} map {$_ =~ s/"/\\"/g} @parts);
	}
	return join($joiner, @parts);
}

sub _interpolate_special {
	my ($self, $string) = @_;
	$string = "\t" if ($string =~ /^TAB|\\t$/i);
	$string = "\n" if ($string =~ /^LF|\\n$/i);
	$string = "\r" if ($string =~ /^CR|\\r$/i);
	$string = "\r\n" if ($string =~ /^CRLF|\\r\\n$/i);
	return $string;
}

1;