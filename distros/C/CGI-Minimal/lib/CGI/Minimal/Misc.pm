package CGI::Minimal;

use strict;

####

sub _internal_calling_parms_table {
	my $self = shift;
	my $pkg = __PACKAGE__;
	my $vars = $self->{$pkg};

	my $outs = <<"EOF";
<table border="1" cellspacing="0">
<tr> <th colspan="4">Form Fields</th> </tr>
<tr> <th>Field</th> <th>Value</th> <th>mime Type</th> <th>File Name</th> </tr>
EOF
	foreach my $fname (sort @{$vars->{'field_names'}}) {
		my $f_data = $vars->{'field'}->{$fname};
		my $sub_field_counter = $#{$f_data->{'value'}};
		for (my $fn=0;$fn <= $sub_field_counter;$fn++) {
			my $fmime  = $f_data->{'mime_type'}->[$fn];
			my $ffile  = $f_data->{'filename'}->[$fn];
			my $fvalue = '[non-text value]';
			if ($fmime =~ m#^text/#oi) {
				$fvalue = $self->htmlize($f_data->{'value'}->[$fn]);
			}
		$outs .= <<"EOF";
	<tr>
	 <td>$fname (#$fn)</td>
	 <td> $fvalue </td>
	 <td>$fmime</td>
	 <td>$ffile</td>
	</tr>
EOF
		}
	}
	$outs .= <<"EOF";
<tr>
  <th colspan="4">Environment Variables</th>
</tr>

<tr>
  <th>Variable</th>
  <th colspan="3">Value</th>
</tr>
EOF

	foreach my $fname (sort keys (%ENV)) {
		$outs .= "<tr>\n  <td>$fname</td>\n  <td colspan=\"3\">" .
			$self->htmlize($ENV{$fname}) . "</td>\n</tr>\n";
	}

	$outs .= "</table>\n";

	return $outs;
}

####

sub _internal_date_rfc1123 {
	my $self = shift;
	my ($tick) = @_;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=gmtime($tick);
	my $wkday = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat')[$wday];
	my $month = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')[$mon];
	$year += 1900;
	my $date = sprintf('%s, %02d %s %s %02d:%02d:%02d GMT',$wkday,$mday,$month,$year,$hour,$min,$sec);
	return $date;
}

####

sub _internal_url_decode {
	my $self = shift;
	my ($s) = @_;
	return '' if (! defined($s));
	$s =~ s/\+/ /gs;
	$s =~ s/%(?:([0-9a-fA-F]{2})|u([0-9a-fA-F]{4}))/
		defined($1)? chr hex($1) : _utf8_chr(hex($2))/ge;
	return $s;
}

####

sub _internal_dehtmlize {
	my $self = shift;

	my($s)=@_;;

	return ('') if (! defined($s));

	$s=~s/\&gt;/>/gs;
	$s=~s/\&lt;/</gs;
	$s=~s/\&quot;/\"/gs;
	$s=~s/\&amp;/\&/gs;

	return $s;
}

sub _internal_set {
	my $pkg = __PACKAGE__;
	my $vars = shift->{$pkg};

	my ($parms) =  @_;
	foreach my $name (keys %$parms) {
		my $value = $parms->{$name};
		my $data  = [];
		my $data_type = ref $value;
		if (! $data_type) {
			$data = [ $value ];

		} elsif ($data_type eq 'ARRAY') {
			@$data = @$value; # Shallow copy

		} else {
			require Carp;
			Carp::croak ("${pkg}::_internal_set() - Parameter '$name' has illegal data type of '$data_type'");
		}

		if (! defined ($vars->{'field'}->{$name}->{'count'})) {
			push (@{$vars->{'field_names'}},$name);
		}
		my $record = {};
		$vars->{'field'}->{$name} = $record;
		$record->{'count'} = @$data;
		$record->{'value'} = $data;
		my $data_entries = @$data;
		for (my $f_count=0;$f_count < $data_entries;$f_count++) {
			$record->{'filename'}->[$f_count]  = '';
			$record->{'mime_type'}->[$f_count] = 'text/plain';
		}
	}
}

1;
