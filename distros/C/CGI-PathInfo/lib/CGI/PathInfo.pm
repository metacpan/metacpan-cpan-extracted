package CGI::PathInfo;

use strict;

BEGIN {
	$CGI::PathInfo::VERSION = '1.03';
        $CGI::PathInfo::_mod_perl = 0;
}

# check for mod_perl and include the 'Apache' module if needed
if (exists($ENV{'MOD_PERL'}) && (0 == $CGI::PathInfo::_mod_perl)) {
	$| = 1;

        if (exists ($ENV{MOD_PERL_API_VERSION}) && ($ENV{MOD_PERL_API_VERSION} == 2)) {
                require Apache2::RequestUtil;
                require Apache2::RequestIO;
                require APR::Pool;
                $CGI::PathInfo::_mod_perl = 2;

        } else {
                require Apache;
                $CGI::PathInfo::_mod_perl = 1;
        }
}

sub new {
	my $proto   = shift;
	my $package = __PACKAGE__;
	my $class;
	if (ref($proto)) {
		$class = ref ($proto);
	} elsif ($proto) {
		$class = $proto;
	} else {
		$class = $package;
	}
	my $self    = bless {},$class;

	$self->{$package}->{'field_names'} = [];
	$self->{$package}->{'field'}       = {};
	$self->{$package}->{'settings'} = {
								       'eq' => '-',
								  'spliton' => '/',
						'stripleadingslash' => 1,
					   'striptrailingslash' => 1,
							};

	my $parms;
	if ($#_ == 0) {
		$parms = shift;
	} elsif ($#_ > 0) {
		if (0 == $#_ % 2) {
			require Carp;
			Carp::croak('[' . localtime(time) . "] [error] $package" . '::new() - odd number of passed parameters');
		}
		%$parms = @_;
	} else {
		$parms = {};
	}
	if (ref($parms) ne 'HASH') {
		require Carp;
		Carp::croak('[' . localtime(time) . "] [error] $package" . '::new() - Passed parameters do not appear to be valid');
	}
	my @parm_keys = keys %$parms;
	foreach my $parm_name (@parm_keys) {
		my $lc_parm_name = lc ($parm_name);
		if (not exists $self->{$package}->{'settings'}->{$lc_parm_name}) {
			require Carp;
			Carp::croak('[' . localtime(time) . "] [error] $package" . "::new() - Passed parameter name '$parm_name' is not valid here");
		}
		$self->{$package}->{'settings'}->{$lc_parm_name} = $parms->{$parm_name};
	}
	$self->_decode_path_info;

	return $self;
}

#######################################################################

sub param {
	my $self = shift;
	my $package = __PACKAGE__;

	if (1 < @_) {
		my $n_parms = @_;
		if (($n_parms % 2) == 1) {
			require Carp;
			Carp::croak('[' . localtime(time) . "] [error] $package" . "::param() - Odd number of parameters  passed");
		}
		my $parms = { @_ };
		$self->_set($parms);
		return;
	}
	if ((@_ == 1) and (ref ($_[0]) eq 'HASH')) {
		my $parms = shift;
		$self->_set($parms);
		return;
	}

	my @result = ();
	if ($#_ == -1) {
		@result = @{$self->{$package}->{'field_names'}};
	} else {
		my ($fieldname)=@_;
		if (defined($self->{$package}->{'field'}->{$fieldname})) {
			@result = @{$self->{$package}->{'field'}->{$fieldname}->{'value'}};
		}
	}


	if (wantarray) {
		return @result;
	} else {
		return $result[0];
	}
}

#######################################################################

sub calling_parms_table {
	my $self = shift;
	my $package = __PACKAGE__;

	require HTML::Entities;

	my $outputstring = "<table border=\"1\" cellspacing=\"0\"><tr><th colspan=\"2\">PATH_INFO Fields</th></tr><tr><th>Field</th><th>Value</th></tr>\n";
	my @field_list = $self->param;
	foreach my $fieldname (sort @field_list) {
		my @values = $self->param($fieldname);
		my $sub_field_counter= $#values;
		for (my $fieldn=0; $fieldn <= $sub_field_counter; $fieldn++) {
			my $e_fieldname = HTML::Entities::encode_entities($fieldname);
			my $fieldvalue  = HTML::Entities::encode_entities($values[$fieldn]);
			$outputstring .= "<tr><td>$e_fieldname (#$fieldn)</td><td> $fieldvalue</td></tr>\n";
		}
	}

	$outputstring .= "</table>\n";

	return $outputstring;
}

#######################################################################

sub url_encode {
	my $self   = shift;
	my ($line) = @_;

	return '' if (! defined ($line));
	$line =~ s/([^a-zA-Z0-9])/"\%".unpack("H",$1).unpack("h",$1)/egs;
	return $line;
}

#######################################################################

sub url_decode {
	my $self   = shift;
	my ($line) = @_;

	return '' if (! defined ($line));
	$line =~ s/\+/ /gos;
	$line =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/egs;
	return $line;
}


########################################################################
# Performs PATH_INFO decoding

sub _decode_path_info {
	my $self = shift;
	my $package = __PACKAGE__;

	my $buffer = '';
	if (1 == $CGI::PathInfo::_mod_perl) {
			  $buffer = Apache->request->path_info;
	} elsif (2 == $CGI::PathInfo::_mod_perl) {
			  $buffer = Apache2::RequestUtil->request->path_info;
	} else {
			  $buffer = $ENV{'PATH_INFO'} if (defined $ENV{'PATH_INFO'});
	}
	$self->_burst_URL_encoded_buffer($buffer);

	return;
}

##########################################################################
# Bursts normal URL encoded buffers
# Takes: $buffer   - the actual data to be burst
#
# parameters are presumed to be seperated by ';' characters
#

sub _burst_URL_encoded_buffer {
	my $self = shift;
	my $package = __PACKAGE__;

	my ($buffer) = @_;
	my $settings = $self->{$package}->{'settings'};
	if ($settings->{'stripleadingslash'})  { $buffer =~ s#^/+##s; }
	if ($settings->{'striptrailingslash'}) { $buffer =~ s#/+$##s; }

	my $spliton  = $settings->{'spliton'};
	my $eq_mark  = $settings->{'eq'};

	# Split the name-value pairs on the selected split char
	my @pairs = ();
	if ($buffer) {
		@pairs = split(/$spliton/, $buffer);
	}

	# Initialize the field hash and the field_names array
	$self->{$package}->{'field'}       = {};
	$self->{$package}->{'field_names'} = [];

	foreach my $pair (@pairs) {
		my ($name, $data) = split(/$eq_mark/,$pair,2);

		# Anything that didn't split is omitted from the output
		next if (not defined $data);

		# De-URL encode %-encoding
		$name = $self->url_decode($name);
		$data = $self->url_decode($data);

		if (! defined ($self->{$package}->{'field'}->{$name}->{'count'})) {
			push (@{$self->{$package}->{'field_names'}},$name);
			$self->{$package}->{'field'}->{$name}->{'count'} = 0;
		}
		my $record      = $self->{$package}->{'field'}->{$name};
		my $field_count = $record->{'count'};
		$record->{'count'}++;
		$record->{'value'}->[$field_count]     = $data;
	}
	return;
}

##################################################################
#
# Sets values into the object directly
# Pass an anon hash for name/value pairs. Values may be
# anon lists or simple strings
#
##################################################################

sub _set {
	my $self = shift;
	my $package = __PACKAGE__;

	my ($parms) = @_;
	foreach my $name (keys %$parms) {
		my $value = $parms->{$name};
		my $data  = [];
		my $data_type = ref $value;
		if (not $data_type) {
			$data = [ $value ];
		} elsif ($data_type eq 'ARRAY') {
			# Shallow copy the anon array to prevent action at a distance
			@$data = map {$_} @$value;
		} else {
			require Carp;
			Carp::croak ('[' . localtime(time) . "] [error] $package"  . "::_set() - Parameter '$name' has illegal data type of '$data_type'");
		}

		if (! defined ($self->{$package}->{'field'}->{$name}->{'count'})) {
			push (@{$self->{$package}->{'field_names'}},$name);
		}
		my $record = {};
		$self->{$package}->{'field'}->{$name} = $record;
		$record->{'count'} = @$data;
		$record->{'value'} = $data;
	}
	return;
}

##########################################################################

1;
