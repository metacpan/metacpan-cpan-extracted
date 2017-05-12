package CGI::Minimal;

# This program is licensed under the same terms as Perl.
# See http://dev.perl.org/licenses/
# Copyright 1999-2004 Benjamin Franz. All Rights Reserved.

# I don't 'use warnings;' here because it pulls in ~ 20Kbytes of code
# and is incompatible with perl's older than 5.6

use strict;

####

sub _internal_param_mime {
	my $pkg = __PACKAGE__;
	my $vars = shift->{$pkg};

	my @result = ();
	if ($#_ == -1) {
		@result = @{$vars->{'field_names'}};
	} elsif ($#_ == 0) {
		my ($fname)=@_;
		if (defined($vars->{'field'}->{$fname})) {
			@result = @{$vars->{'field'}->{$fname}->{'mime_type'}};
		}
	} else {
		require Carp;
		Carp::confess($pkg . "::param_mime() - incorrect number of calling parameters (either 1 or no parameters expected)");
	}
	if (wantarray) {
		return @result;
	} elsif ($#result > -1) {
		return $result[0];
	} else {
		return;
	}
}

####

sub _internal_param_filename {
	my $pkg = __PACKAGE__;
	my $vars = shift->{$pkg};

	my @result = ();
	if ($#_ == -1) {
		@result = @{$vars->{'field_names'}};
	} elsif ($#_ == 0) {
		my ($fname)=@_;
		if (defined($vars->{'field'}->{$fname})) {
			@result = @{$vars->{'field'}->{$fname}->{'filename'}};
		}
	} else {
		require Carp;
		Carp::confess($pkg . "::param_filename() - incorrect number of calling parameters (either 1 or no parameters expected)");
	}

	if (wantarray) {
		return @result;
	} elsif ($#result > -1) {
		return $result[0];
	} else { return; }
}

####

sub _burst_multipart_buffer {
	my $self = shift;
	my $pkg = __PACKAGE__;

	my ($buffer,$bdry)=@_;

	my $vars = $self->{$pkg};

	# Special case boundaries causing problems with 'split'
	if ($bdry =~ m#[^A-Za-z0-9',-./:=]#s) {
		my $nbdry = $bdry;
		$nbdry =~ s/([^A-Za-z0-9',-.\/:=])/ord($1)/egs;
		my $quoted_boundary = quotemeta ($nbdry);
		while ($buffer =~ m/$quoted_boundary/s) {
			$nbdry .= chr(int(rand(25))+65);
			$quoted_boundary = quotemeta ($nbdry);
		}
		my $old_boundary = quotemeta($bdry);
		$buffer =~ s/$old_boundary/$nbdry/gs;
		$bdry   = $nbdry;
	}

	$bdry = "--$bdry(--)?\015\012";
	my @pairs = split(/$bdry/, $buffer);

	foreach my $pair (@pairs) {
		next if (! defined $pair);
		chop $pair; # Trailing \015 
		chop $pair; # Trailing \012
		last if ($pair eq "--");
		next if (! $pair);

		my ($header, $data) = split(/\015\012\015\012/s,$pair,2);

		# parse the header
		$header =~ s/\015\012/\012/osg;
		my @headerlines = split(/\012/so,$header);
		my $name = '';
		my $filename = '';
		my $mime_type = 'text/plain';

		foreach my $headfield (@headerlines) {
			my ($fname,$fdata) = split(/: /,$headfield,2);
			if ($fname =~ m/^Content-Type$/io) {
				$mime_type=$fdata;
			}
			if ($fname =~ m/^Content-Disposition$/io) {
				my @dispositionlist = split(/; /,$fdata);
				foreach my $dispitem (@dispositionlist) {
					next if ($dispitem eq 'form-data');
					my ($dispfield,$dispdata) = split(/=/,$dispitem,2);
					$dispdata =~ s/^\"//o;
					$dispdata =~ s/\"$//o;
					$name = $dispdata if ($dispfield eq 'name');
					$filename = $dispdata if ($dispfield eq 'filename');
				}
			}
		}

		if (! defined ($vars->{'field'}->{$name}->{'count'})) {
			push (@{$vars->{'field_names'}},$name);
			$vars->{'field'}->{$name}->{'count'} = 0;
		}
		my $record = $vars->{'field'}->{$name};
		my $f_count = $record->{'count'};
		$record->{'count'}++;
		$record->{'value'}->[$f_count] = $data;
		$record->{'filename'}->[$f_count]  = $filename;
		$record->{'mime_type'}->[$f_count] = $mime_type;
	}
}

####

1;
