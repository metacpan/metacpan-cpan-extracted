package CGI::Pure;

# Pragmas.
use strict;
use warnings;

# Modules.
use CGI::Deurl::XS qw(parse_query_string);
use Class::Utils qw(set_params);
use Encode qw(decode_utf8);
use English qw(-no_match_vars);
use Error::Pure qw(err);
use List::MoreUtils qw(none);
use Readonly;
use URI::Escape qw(uri_escape uri_escape_utf8 uri_unescape);

# Constants.
Readonly::Scalar my $EMPTY_STR => q{};
Readonly::Scalar my $POST_MAX => 102_400;
Readonly::Scalar my $POST_MAX_NO_LIMIT => -1;
Readonly::Scalar my $BLOCK_SIZE => 4_096;
Readonly::Array my @PAR_SEP => (q{&}, q{;});

# Version.
our $VERSION = 0.05;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# CRLF separator.
	$self->{'crlf'} = undef;

	# Disable upload.
	$self->{'disable_upload'} = 1;

	# Init.
	$self->{'init'} = undef;

	# Parameter separator.
	$self->{'par_sep'} = q{&};

	# Use a post max of 100K ($POST_MAX),
	# set to -1 ($POST_MAX_NO_LIMIT) for no limits.
	$self->{'post_max'} = $POST_MAX;

	# Save query data from server.
	$self->{'save_query_data'} = 0;

	# UTF8 CGI params.
	$self->{'utf8'} = 1;

	# Process params.
	set_params($self, @params);

	# Check to parameter separator.
	if (none { $_ eq $self->{'par_sep'} } @PAR_SEP) {
		err "Bad parameter separator '$self->{'par_sep'}'.";
	}

	# Global object variables.
	$self->_global_variables;

	# Initialization.
	my $init = $self->{'init'};
	delete $self->{'init'};
	$self->_initialize($init);

	# Object.
	return $self;
}

# Append param value.
sub append_param {
	my ($self, $param, @values) = @_;

	# Clean from undefined values.
	my @new_values = _remove_undef(@values);

	$self->_add_param($param, ((defined $new_values[0] and ref $new_values[0])
		? $new_values[0] : [@new_values]));
	return $self->param($param);
}

# Clone class to my class.
sub clone {
	my ($self, $class) = @_;
	foreach my $param ($class->param) {
		$self->param($param, $class->param($param));
	}
	return;
}

# Delete param.
sub delete_param {
	my ($self, $param) = @_;
	if (! defined $self->{'.parameters'}->{$param}) {
		return;
	}
	delete $self->{'.parameters'}->{$param};
	return 1;
}

# Delete all params.
sub delete_all_params {
	my $self = shift;
	delete $self->{'.parameters'};
	$self->{'.parameters'} = {};
	return;
}

# Return param[s]. If sets parameters, than overwrite.
sub param {
	my ($self, $param, @values) = @_;

	# Return list of all params.
	if (! defined $param) {
		return sort keys %{$self->{'.parameters'}};
	}

	# Clean from undefined values.
	my @new_values = _remove_undef(@values);

	# Return values for $param.
	if (! @new_values) {
		if (! exists $self->{'.parameters'}->{$param}) {
			return ();
		}

	# Values exists, than sets them.
	} else {
		$self->_add_param($param, (ref $new_values[0] eq 'ARRAY'
			? $new_values[0] : [@new_values]), 'overwrite');
	}

	# Return values of param, or first value of param.
	return wantarray ? sort @{$self->{'.parameters'}->{$param}}
		: $self->{'.parameters'}->{$param}->[0];
}

# Gets query data from server.
sub query_data {
	my $self = shift;
	if ($self->{'save_query_data'}) {
		return $self->{'.query_data'};
	} else {
		return 'Not saved query data.';
	}
}

# Return actual query string.
sub query_string {
	my $self = shift;
	my @pairs;
	foreach my $param ($self->param) {
		foreach my $value ($self->param($param)) {
			push @pairs, $self->_uri_escape($param).q{=}.
				$self->_uri_escape($value);
		}
	}
	return join $self->{'par_sep'}, @pairs;
}

# Upload file from tmp.
sub upload {
	my ($self, $filename, $writefile) = @_;
	if ($ENV{'CONTENT_TYPE'} !~ m/^multipart\/form-data/ismx) {
		err 'File uploads only work if you specify '.
			'enctype="multipart/form-data" in your form.';
	}
	if (! $filename) {;
		if ($writefile) {
			err 'No filename submitted for upload to '.
				"'$writefile'.";
		}
		return $self->{'.filehandles'}
			? keys %{$self->{'.filehandles'}} : ();
	}
	my $fh = $self->{'.filehandles'}->{$filename};
	if ($fh) {

		# Get ready for reading.
		seek $fh, 0, 0;

		if (! $writefile) {
			return $fh;
		}
		binmode $fh;
		my $buffer;
		my $out;
		if (! open $out, '>', $writefile) {
			err "Cannot write file '$writefile': $!.";
		}
		binmode $out;
		while (read $fh, $buffer, $BLOCK_SIZE) {
			print {$out} $buffer;
		}
		if (! close $out) {
			err "Cannot close file '$writefile': $!.";
		}
		$self->{'.filehandles'}->{$filename} = undef;
		undef $fh;
	} else {
		err "No filehandle for '$filename'. ".
			'Are uploads enabled (disable_upload = 0)? '.
			'Is post_max big enough?';
	}
	return;
}

# Return informations from uploaded files.
sub upload_info {
	my ($self, $filename, $info) = @_;
	if ($ENV{'CONTENT_TYPE'} !~ m/^multipart\/form-data/ismx) {
		err 'File uploads only work if you '.
			'specify enctype="multipart/form-data" in your '.
			'form.';
	}
	if (! $filename) {
		return keys %{$self->{'.tmpfiles'}};
	}
	if ($info =~ m/mime/ims) {
		return $self->{'.tmpfiles'}->{$filename}->{'mime'}
	}
	return $self->{'.tmpfiles'}->{$filename}->{'size'};
}

# Adding param.
sub _add_param {
	my ($self, $param, $value, $overwrite) = @_;
	if (! defined $param) {
		return ();
	}
	if ($overwrite
		|| ! exists $self->{'.parameters'}->{$param}) {

		$self->{'.parameters'}->{$param} = [];
	}
	my @values = ref $value eq 'ARRAY' ? @{$value} : ($value);
	foreach my $value (@values) {
		push @{$self->{'.parameters'}->{$param}}, $value;
	}
	return;
}

# Common parsing from any methods..
sub _common_parse {
	my $self = shift;
	my $data;

	# Information from server.
	my $type = $ENV{'CONTENT_TYPE'} || 'No CONTENT_TYPE received';
	my $length = $ENV{'CONTENT_LENGTH'} || 0;
	my $method = $ENV{'REQUEST_METHOD'} || 'No REQUEST_METHOD received';

	# Multipart form data.
	if ($length && $type =~ m/^multipart\/form-data/imsx) {

		# Get data_length, store data to internal structure.
		my $got_data_length = $self->_parse_multipart;

		# Bad data length vs content_length.
		if ($length != $got_data_length) {
			err "500 Bad read! wanted $length, got ".
				"$got_data_length.";
		}

		return;

	# POST method.
	} elsif ($method eq 'POST') {

		# Maximal post length is above my length.
		if ($self->{'post_max'} != $POST_MAX_NO_LIMIT
			and $length > $self->{'post_max'}) {

			err '413 Request entity too large: '.
				"$length bytes on STDIN exceeds ".
				'post_max !';

		# Get data.
                } elsif ($length) {
			read STDIN, $data, $length;
		}

		# Save data for post.
		if ($self->{'save_query_data'}) {
			$self->{'.query_data'} = $data;
		}

		# Bad length of data.
		if ($length != length $data) {
			err "500 Bad read! wanted $length, got ".
				(length $data).q{.};
		}

	# GET/HEAD method.
	} elsif ($method eq 'GET' || $method eq 'HEAD') {
		$data = $ENV{'QUERY_STRING'} || $EMPTY_STR;
		if ($self->{'save_query_data'}) {
			$self->{'.query_data'} .= $data;
		}
	}

	# Parse params.
	if ($data) {
		$self->_parse_params($data);
	}
	return;
}

# Define the CRLF sequence.
sub _crlf {
	my $self = shift;

	# If not defined.
	if (! defined $self->{'crlf'}) {

		# VMS.
		if ($OSNAME =~ m/VMS/ims) {
			$self->{'crlf'} = "\n";

		# EBCDIC systems.
		} elsif ("\t" eq "\011") {
			$self->{'crlf'} = "\015\012";

		# Other.
		} else {
			$self->{'crlf'} = "\r\n";
		}
	}

	# Return sequence.
	return $self->{'crlf'};
}

# Sets global object variables.
sub _global_variables {
	my $self = shift;
	$self->{'.parameters'} = {};
	$self->{'.query_data'} = $EMPTY_STR;
	return;
}

# Initializating CGI::Pure with something input methods.
sub _initialize {
	my ($self, $init) = @_;

	# Initialize from QUERY_STRING, STDIN or @ARGV.
	if (! defined $init) {
		$self->_common_parse;

	# Initialize from param hash.
	} elsif (ref $init eq 'HASH') {
		foreach my $param (keys %{$init}) {
			$self->_add_param($param, $init->{$param});
		}

	# Inicialize from CGI::Pure object.
	# XXX Mod_perl?
	} elsif (eval { $init->isa('CGI::Pure') }) {
		$self->clone($init);

	# Initialize from a query string.
	} else {
		$self->_parse_params($init);
	}

	return;
}

# Parse multipart data.
sub _parse_multipart {
	my $self = shift;
	my ($boundary) = $ENV{'CONTENT_TYPE'}
		=~ /
			boundary=
			\"?([^\";,]+)\"?
		/msx;
	if (! $boundary) {
		err '400 No boundary supplied for multipart/form-data.';
	}

	# BUG: IE 3.01 on the Macintosh uses just the boundary, forgetting
	# the --
	if (! exists $ENV{'HTTP_USER_AGENT'} || $ENV{'HTTP_USER_AGENT'} !~ m/
		MSIE\s+
		3\.0[12];
		\s*
		Mac
		/imsx) {

		$boundary = q{--}.$boundary;
	}

	$boundary = quotemeta $boundary;
	my $got_data_length = 0;
	my $data = $EMPTY_STR;
	my $read;
	my $CRLF = $self->_crlf;

	READ:
	while (read STDIN, $read, $BLOCK_SIZE) {

		# Adding post data.
		if ($self->{'save_query_data'}) {
			$self->{'.query_data'} .= $read;
		}

		$data .= $read;
		$got_data_length += length $read;

		BOUNDARY:
		while ($data =~ m/^$boundary$CRLF/ms) {
			my $header;

			# Get header, delimited by first two CRLFs we see.
			if ($data !~ m/^([\040-\176$CRLF]+?$CRLF$CRLF)/ms) {
				next READ;
			}
# XXX Proc tohle nemuze byt? /x tam dela nejake potize.
#			if ($data !~ m/^(
#					[\040-\176$CRLF]+?
#					$CRLF
#					$CRLF
#				)/msx) {
#
#				next READ;
#			}
			$header = $1;

			# Unhold header per RFC822.
			(my $unfold = $1) =~ s/$CRLF\s+/\ /gms;

			my ($param) = $unfold =~ m/
					form-data;
					\s+
					name="?([^\";]*)"?
				/msx;
			my ($filename) = $unfold =~ m/
					name="?\Q$param\E"?;
					\s+
					filename="?([^\"]*)"?
				/msx;
			if ($filename) {
				my ($mime) = $unfold =~ m/
						Content-Type:
						\s+
						([-\w\/]+)
					/imsx;

				# Trim off header.
				$data =~ s/^\Q$header\E//ms;

				($got_data_length, $data, my $fh, my $size)
					= $self->_save_tmpfile($boundary,
					$filename, $got_data_length, $data);

				$self->_add_param($param, $filename);

				# Filehandle.
				if ($fh) {
					$self->{'.filehandles'}->{$filename}
						= $fh;
				}

				# Information about file.
				if ($size) {
					$self->{'.tmpfiles'}->{$filename} = {
						'size' => $size,
						'mime' => $mime,
					};
				}
				next BOUNDARY;
			}
			if ($data !~ s/^\Q$header\E(.*?)$CRLF(?=$boundary)//s) {
				next READ;
			}
# XXX /x
#			if ($data !~ s/^
#					\Q$header\E
#					(.*?)
#					$CRLF
#					(?=$boundary)
#				//msx) {
#
#				next READ;
#			}
			my $param_value;
			if ($self->{'utf8'}) {
				$param_value = decode_utf8($1);
			} else {
				$param_value = $1;
			}
			$self->_add_param($param, $param_value);
		}
	}

	# Length of data.
	return $got_data_length;
}

# Parse params from data.
sub _parse_params {
	my ($self, $data) = @_;
	if (! defined $data) {
		return ();
	}

	# Parse params.
	my $pairs_hr = parse_query_string($data);
	foreach my $key (keys %{$pairs_hr}) {

		# Value processing.
		my $value;
		if ($self->{'utf8'}) {
			if (ref $pairs_hr->{$key} eq 'ARRAY') {
				my @decoded = ();
				foreach my $val (@{$pairs_hr->{$key}}) {
					push @decoded, decode_utf8($val);
				}
				$value = \@decoded;
			} else {
				$value = decode_utf8($pairs_hr->{$key});
			}
		} else {
			$value = $pairs_hr->{$key};
		}

		# Add parameter.
		$self->_add_param($key, $value);
	}
	return;
}

# Remove undefined values.
sub _remove_undef {
	my (@values) = @_;
	my @new_values;
	foreach my $value (@values) {
		if (defined $value) {
			push @new_values, $value;
		}
	}
	return @new_values;
}

# Save file from multiform.
sub _save_tmpfile {
	my ($self, $boundary, $filename, $got_data_length, $data) = @_;
	my $fh;
	my $CRLF = $self->_crlf;
	my $file_size = 0;
	if ($self->{'disable_upload'}) {
		err '405 Not Allowed - File uploads are disabled.';
	} elsif ($filename) {
		eval {
			require IO::File;
		};
		if ($EVAL_ERROR) {
			err "500 IO::File is not available $EVAL_ERROR.";
		}
		$fh = new_tmpfile IO::File;
		if (! $fh) {
			err '500 IO::File can\'t create new temp_file.';
		}
	}
	binmode $fh;
	while (1) {
		my $buffer = $data;
		read STDIN, $data, $BLOCK_SIZE;
		if (! $data) {
			$data = $EMPTY_STR;
		}
		$got_data_length += length $data;
		if ("$buffer$data" =~ m/$boundary/ms) {
			$data = $buffer.$data;
			last;
		}

		# BUG: Fixed hanging bug if browser terminates upload part way.
		if (! $data) {
			undef $fh;
			err '400 Malformed multipart, no terminating '.
				'boundary.';
		}

		# We do not have partial boundary so print to file if valid $fh.
		print {$fh} $buffer;
		$file_size += length $buffer;
	}
	$data =~ s/^
		(.*?)
		$CRLF
		(?=$boundary)
	//smx;

	# Print remainder of file if value $fh.
	if ($1) {
		print {$fh} $1;
		$file_size += length $1;
	}

	return $got_data_length, $data, $fh, $file_size;
}

# Escapes uri.
sub _uri_escape {
	my ($self, $string) = @_;
	if ($self->{'utf8'}) {
		$string = uri_escape_utf8($string);
	} else {
		$string = uri_escape($string);
	}
	$string =~ s/\ /\+/gsm;
	return $string;
}

# Unescapes uri.
sub _uri_unescape {
	my ($self, $string) = @_;
	$string =~ s/\+/\ /gsm;
	return uri_unescape($string);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

CGI::Pure - Common Gateway Interface Class.

=head1 SYNOPSIS

 use CGI::Pure;
 my $cgi = CGI::Pure->new(%parameters);
 $cgi->append_param('par', 'value');
 my @par_value = $cgi->param('par');
 $cgi->delete_param('par');
 $cgi->delete_all_params;
 my $query_string = $cgi->query_string;
 $cgi->upload('filename', '~/filename');
 my $mime = $cgi->upload_info('filename', 'mime');
 my $query_data = $cgi->query_data;

=head1 METHODS

=over 8

=item C<new(%parameters)>

 Constructor

=over 8

=item * C<disable_upload>

 Disables file upload.
 Default value is 1.

=item * C<init>

 Initialization variable.
 May be:
 - CGI::Pure object.
 - Hash with params.
 - Query string.
 Default is undef.

=item * C<par_sep>

 Parameter separator.
 Default value is '&'.
 Possible values are '&' or ';'.

=item * C<post_max>

 Maximal post length.
 -1 means no limit.
 Default value is 102400kB

=item * C<save_query_data>

 Flag, that means saving query data.
 When is enable, is possible use query_data method.
 Default value is 0.

=item * C<utf8>

 Flag, that means utf8 CGI parameters handling.
 Default is 1.

=back

=item C<append_param($param, [@values])>

 Append param value.
 Returns all values for param.

=item C<clone($class)>

 Clone class to my class.

=item C<delete_param($param)>

 Delete param.
 Returns undef, when param doesn't exist.
 Returns 1, when param was deleted.

=item C<delete_all_params()>

 Delete all params.

=item C<param([$param], [@values])>

 Returns or sets parameters in CGI.
 params() returns all parameters name.
 params('param') returns parameter 'param' value.
 params('param', 'val1', 'val2') sets parameter 'param' to 'val1' and 'val2'
 values.

=item C<query_data()>

 Gets query data from server.
 There is possible only for enabled 'save_data' flag.

=item C<query_string()>

 Returns actual query string.

=item C<upload($filename, [$write_to])>

 Upload file from tmp.
 upload() returns array of uploaded filenames.
 upload($filename) returns handler to uploaded filename.
 upload($filename, $write_to) uploads temporary '$filename' file to
 '$write_to' file.

=item C<upload_info($filename, [$info])>

 Returns informations from uploaded files.
 upload_info() returns array of uploaded files.
 upload_info('filename') returns size of uploaded 'filename' file.
 upload_info('filename', 'mime') returns mime type of uploaded 'filename' file.

=back

=head1 ERRORS

 new():
         400 Malformed multipart, no terminating boundary.
         400 No boundary supplied for multipart/form-data.
         405 Not Allowed - File uploads are disabled.
         413 Request entity too large: %s bytes on STDIN exceeds post_max !
         500 Bad read! wanted %s, got %s.
         500 IO::File can\'t create new temp_file.
         500 IO::File is not available %s.
         Bad parameter separator '%s'.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 upload():
         Cannot close file '%s': %s.
         Cannot write file '%s': %s.
         File uploads only work if you specify enctype="multipart/form-data" in your form.
         No filehandle for '%s'. Are uploads enabled (disable_upload = 0)? Is post_max big enough?
         No filename submitted for upload to '$writefile'.

 upload_info():
         File uploads only work if you specify enctype="multipart/form-data" in your form.


=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use CGI::Pure;

 # Object.
 my $query_string = 'par1=val1;par1=val2;par2=value';
 my $cgi = CGI::Pure->new(
         'init' => $query_string,
 );
 foreach my $param_key ($cgi->param) {
         print "Param '$param_key': ".join(' ', $cgi->param($param_key))."\n";
 }

 # Output:
 # Param 'par1': val1 val2
 # Param 'par2': value

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use CGI::Pure;

 # Object.
 my $cgi = CGI::Pure->new;
 $cgi->param('par1', 'val1', 'val2');
 $cgi->param('par2', 'val3');
 $cgi->append_param('par2', 'val4');

 foreach my $param_key ($cgi->param) {
         print "Param '$param_key': ".join(' ', $cgi->param($param_key))."\n";
 }

 # Output:
 # Param 'par2': val3 val4
 # Param 'par1': val1 val2

=head1 DEPENDENCIES

L<Class::Utils>,
L<CGI::Deurl::XS>,
L<Error::Pure>,
L<URI::Escape>.

=head1 SEE ALSO

=over

=item L<CGI::Pure::Fast>

Fast Common Gateway Interface Class for CGI::Pure.

=item L<CGI::Pure::Save>

Common Gateway Interface Class for loading/saving object in file.

=back

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2004-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.05

=cut
