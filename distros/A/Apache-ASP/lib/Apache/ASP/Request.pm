
package Apache::ASP::Request;

use Apache::ASP::Collection;
use strict;

sub new {
    my $asp = shift;
    my $r = $asp->{r};

    my $self = bless 
      { 
       asp => $asp,
#       content => undef,
#       Cookies => undef,
#       FileUpload => undef,
#       Form => undef,
#       QueryString => undef,
#       ServerVariables => undef,
       Method => $r->method || 'GET',
       TotalBytes => 0,
      };

    # calculate whether to read POST data here
    my $request_binary_read = &config($asp, 'RequestBinaryRead', undef, 1);
    $asp->{request_binary_read} = $request_binary_read;

    # set up the environment, including authentication info
    my $env = { %{$r->subprocess_env}, %ENV };
    if(&config($asp, 'AuthServerVariables')) {
	if(defined $r->get_basic_auth_pw) {
	    my $c = $r->connection;
	    #X: this needs to be extended to support Digest authentication
	    $env->{AUTH_TYPE} = $c->auth_type;
	    $env->{AUTH_USER} = $c->user;
	    $env->{AUTH_NAME} = $r->auth_name;
	    $env->{REMOTE_USER} = $c->user;
	    $env->{AUTH_PASSWD} = $r->get_basic_auth_pw;
	}
    }
    $self->{'ServerVariables'} = bless $env, 'Apache::ASP::Collection';

    # assign no matter what so Form is always defined
    my $form = {};
    my %upload;
    my $headers_in = $self->{asp}{headers_in};
    if($self->{Method} eq 'POST' and $request_binary_read) {
	$self->{TotalBytes} = defined($ENV{CONTENT_LENGTH}) ? $ENV{CONTENT_LENGTH} : $headers_in->get('Content-Length');
	if($headers_in->get('Content-Type') =~ m|^multipart/form-data|) {
	    # do the logic here so that the normal form POST processing will not
	    # occur either
	    $asp->{file_upload_process} = &config($asp, 'FileUploadProcess', undef, 1);
	    if($asp->{file_upload_process}) {
		if($asp->{file_upload_temp} = &config($asp, 'FileUploadTemp')) {
		    eval "use CGI;";
		} else {
		    # default leaves no temp files for prying eyes
		    eval "use CGI qw(-private_tempfiles);";		
		}
		if($@) { 
		    $self->{asp}->Error("can't use file upload without CGI.pm: $@");
		    goto ASP_REQUEST_POST_READ_DONE;
		}

		# new behavior for file uploads when FileUploadMax is exceeded,
		# before it used to error abruptly, now it will simply skip the file 
		# upload data
		local $CGI::DISABLE_UPLOADS = $CGI::DISABLE_UPLOADS;
		if($asp->{file_upload_max} = &config($asp, 'FileUploadMax')) {
		    if($self->{TotalBytes} > $asp->{file_upload_max} ) {
			$CGI::DISABLE_UPLOADS = 1;
		    }
		}
		
		$asp->{dbg} && $asp->Debug("using CGI.pm version ".
					   (eval { CGI->VERSION } || $CGI::VERSION).
					   " for file upload support"
					  );

		my %form;
		my $q = $self->{cgi} = new CGI;
		$asp->Debug($q->param);
		for(my @names = $q->param) {
		    my @params = $q->param($_);
		    $form{$_} = @params > 1 ? [ @params ] : $params[0];
		    if(ref($form{$_}) eq 'Fh') {
			my $fh = $form{$_};
			binmode $fh if $asp->{win32};
			$upload{$_} = $q->uploadInfo($fh);
			if($asp->{file_upload_temp}) {
			    $upload{$_}{TempFile} = $q->tmpFileName($fh);
			    $upload{$_}{TempFile} =~ s|^/+|/|;
			}
			$upload{$_}{BrowserFile} = "$fh";
			$upload{$_}{FileHandle} = $fh;
			$upload{$_}{ContentType} = $upload{$_}{'Content-Type'};
			# tie the file upload reference to a collection... %upload
			# may be many file uploads note.
			$upload{$_} = bless $upload{$_}, 'Apache::ASP::Collection';
			$asp->{dbg} && $asp->Debug("file upload field processed for \$Request->{FileUpload}{$_}", $upload{$_});
		    }
		}
		$form = \%form;
	    } else {
		$self->{asp}->Debug("FileUploadProcess is disabled, file upload data in \$Request->BinaryRead");
	    }

	} else {
	    # Only tie to STDIN if we have cached contents
	    # don't untie *STDIN until DESTROY, so filtered handlers
	    # have an opportunity to use any cached contents that may exist
	    if(my $len = $self->{TotalBytes}) {
		$self->{content} = $self->BinaryRead($len) || '';
		tie(*STDIN, 'Apache::ASP::Request', $self);
		#AJAX POSTs are ``application/x-www-form-urlencoded; charset=UTF-8'' in Firefox3+
		#by Richard Walsh Nov 25, 2008 (found in nabble)
		if($headers_in->get('Content-Type') =~ m|^application/x-www-form-urlencoded|) {
		    $form = &ParseParams($self, \$self->{content});
		} else {
		    $form = {};
		}
	    }
	}
    }

ASP_REQUEST_POST_READ_DONE:

    $self->{'Form'} = bless $form, 'Apache::ASP::Collection';
    $self->{'FileUpload'} = bless \%upload, 'Apache::ASP::Collection';
    my $query = $r->args();
    my $parsed_query = $query ? &ParseParams($self, \$query) : {};
    $self->{'QueryString'} = bless $parsed_query, 'Apache::ASP::Collection';

    if(&config($asp, 'RequestParams')) {
	$self->{'Params'} = bless { %$parsed_query, %$form }, 'Apache::ASP::Collection';
    } 

    # do cookies now
    my %cookies; 
    if(my $cookie = $headers_in->get('Cookie')) {
	my @parts = split(/;\s*/, ($cookie || ''));
	for(@parts) {	
	    my($name, $value) = split(/\=/, $_, 2);
	    $name = &Unescape($self, $name);
	    
	    next if ($name eq $Apache::ASP::SessionCookieName);
	    next if $cookies{$name}; # skip dup's
	    
	    $cookies{$name} = ($value =~ /\=/) ? 
	      &ParseParams($self, $value) : &Unescape($self, $value);
	}
    }
    $self->{Cookies} = bless \%cookies, 'Apache::ASP::Collection';

    $self;
}

sub DESTROY {
    my $self = shift;

    if($self->{cgi}) {
	# make sure CGI file handles are freed
	$self->{cgi}->DESTROY();
	$self->{cgi} = undef;
    }

    for(keys %{$self->{FileUpload}}) {
	my $upload = $self->{FileUpload}{$_};
	$self->{Form}{$_} = undef;
	if($upload->{FileHandle}) {
	    close $upload->{FileHandle};
	    # $self->{asp}->Debug("closing fh $upload->{FileHandle}");
	}
	$self->{FileUpload}{$_} = undef;
    }

    %$self = ();
}

# just returns itself
sub TIEHANDLE { $_[1] };

# just spill the cache into the scalar, so multiple reads are
# fine... whoever is reading from the cached contents must
# be reading the whole thing just once for this to work, 
# which is fine for CGI.pm
sub READ {
    my $self = $_[0];
    $_[1] ||= '';
    $_[1] .= $self->{content};
    $self->{ServerVariables}{CONTENT_LENGTH};
}

sub BINMODE { };

# COLLECTIONS, normal, Cookies are special, with the dictionary lookup
# directly aliased as this should be faster than autoloading
sub Form { shift->{Form}->Item(@_) }
sub FileUpload { shift->{FileUpload}->Item(@_) }
sub QueryString { shift->{QueryString}->Item(@_) }
sub ServerVariables { shift->{ServerVariables}->Item(@_) }

sub Params {
    my $self = shift; 
    $self->{Params}
      || die("\$Request->Params object does not exist, enable with 'PerlSetVar RequestParams 1'");
    $self->{Params}->Item(@_);
}

sub BinaryRead {
    my($self, $length) = @_;
    my $data;
    return undef unless $self->{TotalBytes};

    if(ref(tied(*STDIN)) && tied(*STDIN)->isa('Apache::ASP::Request')) {
	if($self->{TotalBytes}) {
	    if(defined $length) {
		return substr($self->{content}, 0, $length);
	    } else {
		return $self->{content}
	    }
	} else {
	    return undef;
	}
    } else {
	defined($length) || ( $length = $self->{TotalBytes} );
	my $asp = $self->{asp};
	my $r = $asp->{r};
	if(! $ENV{MOD_PERL}) {
	    my $rv = sysread(*STDIN, $data, $length, 0);
	    $asp->{dbg} && $asp->Debug("read $rv bytes from STDIN for CGI mode, tried $length bytes");
	} else {
	    $r->read($data, $length);
	    $asp->{dbg} && $asp->Debug("read ".length($data)." bytes, tried $length bytes");
	}
	return $data;
    }
}

sub Cookies {
    my($self, $name, $key) = @_;

    if(! $name) {
	$self->{Cookies};
    } elsif($key) {
	$self->{Cookies}{$name}{$key};
    } else {
	# when we just have the name, are we expecting a dictionary or not
	my $cookie = $self->{Cookies}{$name};
	if(ref $cookie && wantarray) {
	    return %$cookie;
	} else {
	    # CollectionItem support here one day, to not return
	    # an undef object, CollectionItem needs tied hash support
	    return $cookie;
	}
    }
}

sub ParseParams {
    my($self, $string) = @_;
    ($string = $$string) if ref($string); ## faster if we pass a ref for a big string

    my %params;
    defined($string) || return(\%params);
    my @params = split /[\&\;]/, $string, -1;

    # we have to iterate through the params here to collect multiple values for 
    # the same param, say from a multiple select statement
    for my $pair (@params) {
	my($key, $value) = map { 
	    # inline for greater efficiency
	    # &Unescape($self, $_) 
	    my $todecode = $_;
	    $todecode =~ tr/+/ /;       # pluses become spaces
	    $todecode =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/ge;
	    $todecode;
	} split (/\=/, $pair, 2);
	if(defined $params{$key}) {
	    my $collect = $params{$key};

	    if(ref $collect) {
		# we have already collected more than one param for that key
		push(@{$collect}, $value);
	    } else {
		# this is the second value for a key we've seen, start array
		$params{$key} = [$collect, $value];
	    }
	} else {
	    # normal use, one to one key value pairs, just set
	    $params{$key} = $value;
	}
    }

    \%params;
}

# unescape URL-encoded data
sub Unescape {
    my $todecode = $_[1];
    $todecode =~ tr/+/ /;       # pluses become spaces
    $todecode =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/ge;
    $todecode;
}

*config = *Apache::ASP::config;

1;
