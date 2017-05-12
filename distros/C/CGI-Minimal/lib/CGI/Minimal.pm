package CGI::Minimal;

use strict;

# I don't 'use warnings;' here because it pulls in ~ 40Kbytes of code and
# interferes with 5.005 and earlier versions of Perl.
#
# I don't use vars qw ($_query $VERSION $form_initial_read $_BUFFER); for
# because it also pulls in warnings under later versions of perl.
# The code is clean - but the pragmas cause performance issues.

$CGI::Minimal::_query                   = undef;
$CGI::Minimal::form_initial_read        = undef;
$CGI::Minimal::_BUFFER                  = undef;
$CGI::Minimal::_allow_hybrid_post_get   = 0;
$CGI::Minimal::_mod_perl                = 0;
$CGI::Minimal::_no_subprocess_env       = 0;

$CGI::Minimal::VERSION = "1.29";

if (exists ($ENV{'MOD_PERL'}) && (0 == $CGI::Minimal::_mod_perl)) {
	$| = 1;
	my $env_mod_perl = $ENV{'MOD_PERL'};
	if ($env_mod_perl =~ m#^mod_perl/1.99#) { # Redhat's almost-but-not-quite ModPerl2....
		require Apache::compat;
		require CGI::Minimal::Misc;
		require CGI::Minimal::Multipart;
		$CGI::Minimal::_mod_perl = 1;

	} elsif (exists ($ENV{MOD_PERL_API_VERSION}) && ($ENV{MOD_PERL_API_VERSION} == 2)) {
		require Apache2::RequestUtil;
		require Apache2::RequestIO;
		require APR::Pool;
		require CGI::Minimal::Misc;
		require CGI::Minimal::Multipart;
		$CGI::Minimal::_mod_perl = 2;

	} else {
		require Apache;
		require CGI::Minimal::Misc;
		require CGI::Minimal::Multipart;
		$CGI::Minimal::_mod_perl = 1;
	}
}
binmode STDIN;
reset_globals();

####

sub import {
	my $class = shift;
	my %flags = map { $_ => 1 } @_;
	if ($flags{':preload'}) {
		require CGI::Minimal::Misc;
		require CGI::Minimal::Multipart;
	}
	$CGI::Minimal::_no_subprocess_env = $flags{':no_subprocess_env'};
}

####

sub new {
	my $proto = shift;
	my $pkg   = __PACKAGE__;

	if ($CGI::Minimal::form_initial_read) {
		binmode STDIN;
		$CGI::Minimal::_query->_read_form;
		$CGI::Minimal::form_initial_read = 0;
	}
	if (1 == $CGI::Minimal::_mod_perl) {
		Apache->request->register_cleanup(\&CGI::Minimal::reset_globals);

	} elsif (2 == $CGI::Minimal::_mod_perl) {
		Apache2::RequestUtil->request->pool->cleanup_register(\&CGI::Minimal::reset_globals);
	}

	return $CGI::Minimal::_query;
}

####

sub reset_globals {
	$CGI::Minimal::form_initial_read = 1;
	$CGI::Minimal::_allow_hybrid_post_get = 0;
	$CGI::Minimal::_query = {};
	bless $CGI::Minimal::_query;
	my $pkg = __PACKAGE__;

	$CGI::Minimal::_BUFFER = undef;
	max_read_size(1000000);
	$CGI::Minimal::_query->{$pkg}->{'field_names'} = [];
	$CGI::Minimal::_query->{$pkg}->{'field'} = {};
	$CGI::Minimal::_query->{$pkg}->{'form_truncated'} = undef;

	return 1; # Keeps mod_perl from complaining
}

# For backward compatibility 
sub _reset_globals { reset_globals; }

###

sub subprocess_env {
	if (2 == $CGI::Minimal::_mod_perl) {
		Apache2::RequestUtil->request->subprocess_env;
	}
}

###

sub allow_hybrid_post_get {
	if (@_ > 0) {
		$CGI::Minimal::_allow_hybrid_post_get = $_[0];
	} else {
		return $CGI::Minimal::_allow_hybrid_post_get;
	}
}

###

sub delete_all { 
	my $self = shift;
	my $pkg  = __PACKAGE__;
	$CGI::Minimal::_query->{$pkg}->{'field_names'} = [];
	$CGI::Minimal::_query->{$pkg}->{'field'} = {};
	return;
}

####

sub delete {
	my $self = shift;
	my $pkg  = __PACKAGE__;
	my $vars = $self->{$pkg};
	
	my @names_list   = @_;
	my %tagged_names = map { $_ => 1 } @names_list;
	my @parm_names   = @{$vars->{'field_names'}};
	my $fields       = [];
	my $data         = $vars->{'field'};
	foreach my $parm (@parm_names) {
		if ($tagged_names{$parm}) {
			delete $data->{$parm};
		} else {
			push (@$fields, $parm);
		}
	}
	$vars->{'field_names'} = $fields;
	return;
}

####

sub param {
	my $self = shift;
	my $pkg = __PACKAGE__;

	if (1 < @_) {
		my $n_parms = @_;
		if (($n_parms % 2) == 1) {
			require Carp;
			Carp::confess("${pkg}::param() - Odd number of parameters (other than 1) passed");
		}

		my $parms = { @_ };
		require CGI::Minimal::Misc;
		$self->_internal_set($parms);
		return;

	} elsif ((1 == @_) and (ref ($_[0]) eq 'HASH')) {
		my $parms = shift;
		require CGI::Minimal::Misc;
		$self->_internal_set($parms);
		return;
	}

	# Requesting parameter values

	my $vars = $self->{$pkg};
	my @result = ();
	if ($#_ == -1) {
		@result = @{$vars->{'field_names'}};

	} else {
		my ($fname) = @_;
		if (defined($vars->{'field'}->{$fname})) {
			@result = @{$vars->{'field'}->{$fname}->{'value'}};
		}
	}

	if    (wantarray)     { return @result;    }
	elsif ($#result > -1) { return $result[0]; }
	return;
}

####

sub raw {
	return if (! defined $CGI::Minimal::_BUFFER);
	return $$CGI::Minimal::_BUFFER;
}

####

sub truncated {
	my $pkg = __PACKAGE__;
	shift->{$pkg}->{'form_truncated'};
}

####

sub max_read_size {
	my $pkg = __PACKAGE__;
	$CGI::Minimal::_query->{$pkg}->{'max_buffer'} = $_[0];
}

####
# Wrapper for form reading for GET, HEAD and POST methods

sub _read_form {
	my $self = shift;

	my $pkg  = __PACKAGE__;
	my $vars = $self->{$pkg};

	$vars->{'field'} = {};
	$vars->{'field_names'} = [];

	my $req_method=$ENV{"REQUEST_METHOD"};
	if ((2 == $CGI::Minimal::_mod_perl) and (not defined $req_method)) {
		$req_method = Apache2::RequestUtil->request->method;
	}

	if (! defined $req_method) {
		my $input = <STDIN>;
		$input = '' if (! defined $input);
		$ENV{'QUERY_STRING'} = $input;
		chomp $ENV{'QUERY_STRING'};
		$self->_read_get;
		return;
	}
	if ($req_method eq 'POST') {
		$self->_read_post; 
		if ($CGI::Minimal::_allow_hybrid_post_get) {
			$self->_read_get;
		}
	} elsif (($req_method eq 'GET') || ($req_method eq 'HEAD')) {
		$self->_read_get;
	} else {
		my $package = __PACKAGE__;
		require Carp;
		Carp::carp($package . " - Unsupported HTTP request method of '$req_method'. Treating as 'GET'");
		$self->_read_get;
	}
}

####
# Performs form reading for POST method

sub _read_post {
	my $self = shift;
	my $pkg  = __PACKAGE__;
	my $vars = $self->{$pkg};

	my $r;
	if (2 == $CGI::Minimal::_mod_perl) {
		$r = Apache2::RequestUtil->request;
	}

	my $read_length = $vars->{'max_buffer'};
	my $clen = $ENV{'CONTENT_LENGTH'};
	if ((2 == $CGI::Minimal::_mod_perl) and (not defined $clen)) {
		$clen = $r->headers_in->get('Content-Length');
	}
	if ($clen < $read_length) {
		$read_length = $clen;
	}

	my $buffer = '';
	my $read_bytes = 0;
	if ($read_length) {
		if (2 == $CGI::Minimal::_mod_perl) {
			$read_bytes = $r->read($buffer,$read_length,0);
		} else {
			$read_bytes = read(STDIN, $buffer, $read_length,0);
		}
	}
	$CGI::Minimal::_BUFFER = \$buffer;
	$vars->{'form_truncated'} = ($read_bytes < $clen) ? 1 : 0;

	my $content_type = defined($ENV{'CONTENT_TYPE'}) ? $ENV{'CONTENT_TYPE'} : '';
	if ((!$content_type) and (2 == $CGI::Minimal::_mod_perl)) {
		$content_type = $r->headers_in->get('Content-Type');
	}

	# Boundaries are supposed to consist of only the following
	# (1-70 of them, not ending in ' ') A-Za-z0-9 '()+,_-./:=?

	if ($content_type =~ m/^multipart\/form-data; boundary=(.*)$/i) {
		my $bdry = $1;
		require CGI::Minimal::Multipart;
		$self->_burst_multipart_buffer ($buffer,$bdry);

	} else {
		$self->_burst_URL_encoded_buffer($buffer,'[;&]');
	}
}

####
# GET and HEAD

sub _read_get {
	my $self = shift;

	my $buffer = '';
	my $req_method = $ENV{'REQUEST_METHOD'};
	if (1 == $CGI::Minimal::_mod_perl) {
		$buffer = Apache->request->args;
	} elsif (2 == $CGI::Minimal::_mod_perl) {
		my $r = Apache2::RequestUtil->request;
		$buffer = $r->args;
		$r->discard_request_body();
                unless (exists($ENV{'REQUEST_METHOD'}) || $CGI::Minimal::_no_subprocess_env) {
			$r->subprocess_env;
		}
		$req_method = $r->method unless ($req_method);
	} else {
		$buffer = $ENV{'QUERY_STRING'} if (defined $ENV{'QUERY_STRING'});
	}
	if ($req_method ne 'POST') {
		$CGI::Minimal::_BUFFER = \$buffer;
	}
	$self->_burst_URL_encoded_buffer($buffer,'[;&]');
}

####
# Bursts URL encoded buffers
#  $buffer -  data to be burst
#  $spliton   - split pattern

sub _burst_URL_encoded_buffer {
	my $self = shift;
	my $pkg = __PACKAGE__;
	my $vars = $self->{$pkg};

	my ($buffer,$spliton)=@_;

	my ($mime_type) = "text/plain";
	my ($filename) = "";

	my @pairs = $buffer ? split(/$spliton/, $buffer) : ();

	foreach my $pair (@pairs) {
		my ($name, $data) = split(/=/,$pair,2);

		$name = '' unless (defined $name);
		$name =~ s/\+/ /gs;
		$name =~ s/%(?:([0-9a-fA-F]{2})|u([0-9a-fA-F]{4}))/
		defined($1)? chr hex($1) : _utf8_chr(hex($2))/ge;
		$data = '' unless (defined $data);
		$data =~ s/\+/ /gs;
		$data =~ s/%(?:([0-9a-fA-F]{2})|u([0-9a-fA-F]{4}))/
		defined($1)? chr hex($1) : _utf8_chr(hex($2))/ge;

		if (! defined ($vars->{'field'}->{$name}->{'count'})) {
			push (@{$vars->{'field_names'}},$name);
			$vars->{'field'}->{$name}->{'count'} = 0;
		}
		my $record  = $vars->{'field'}->{$name};
		my $f_count = $record->{'count'};
		$record->{'count'}++;
		$record->{'value'}->[$f_count] = $data;
		$record->{'filename'}->[$f_count]  = $filename;
		$record->{'mime_type'}->[$f_count] = $mime_type;
	}
}

####
#
# _utf8_chr() taken from CGI::Util
# Copyright 1995-1998, Lincoln D. Stein.  All rights reserved.  
sub _utf8_chr {
	my $c = shift(@_);
	return chr($c) if $] >= 5.006;

	if ($c < 0x80) {
		return sprintf("%c", $c);
	} elsif ($c < 0x800) {
		return sprintf("%c%c", 0xc0 | ($c >> 6), 0x80 | ($c & 0x3f));
	} elsif ($c < 0x10000) {
		return sprintf("%c%c%c",
					   0xe0 |  ($c >> 12),
					   0x80 | (($c >>  6) & 0x3f),
					   0x80 | ( $c & 0x3f));
	} elsif ($c < 0x200000) {
		return sprintf("%c%c%c%c",
					   0xf0 |  ($c >> 18),
					   0x80 | (($c >> 12) & 0x3f),
					   0x80 | (($c >>  6) & 0x3f),
					   0x80 | ( $c & 0x3f));
	} elsif ($c < 0x4000000) {
		return sprintf("%c%c%c%c%c",
					   0xf8 |  ($c >> 24),
					   0x80 | (($c >> 18) & 0x3f),
					   0x80 | (($c >> 12) & 0x3f),
					   0x80 | (($c >>  6) & 0x3f),
					   0x80 | ( $c & 0x3f));

	} elsif ($c < 0x80000000) {
		return sprintf("%c%c%c%c%c%c",
					   0xfc |  ($c >> 30),
					   0x80 | (($c >> 24) & 0x3f),
					   0x80 | (($c >> 18) & 0x3f),
					   0x80 | (($c >> 12) & 0x3f),
					   0x80 | (($c >> 6)  & 0x3f),
					   0x80 | ( $c & 0x3f));
	} else {
		return _utf8_chr(0xfffd);
	}
}

####

sub htmlize {
	my $self = shift;

	my ($s)=@_;
	return ('') if (! defined($s));
	$s =~ s/\&/\&amp;/gs;
	$s =~ s/>/\&gt;/gs;
	$s =~ s/</\&lt;/gs;
	$s =~ s/"/\&quot;/gs;
	$s;
}

####

sub url_encode {
	my $self = shift;
	my ($s)=@_;
	return '' if (! defined ($s));
	$s= pack("C*", unpack("C*", $s));
	$s=~s/([^-_.a-zA-Z0-9])/sprintf("%%%02x",ord($1))/eg;
	$s;
}

####

sub param_mime     { require CGI::Minimal::Multipart; &_internal_param_mime(@_);      }
sub param_filename { require CGI::Minimal::Multipart; &_internal_param_filename(@_);  }
sub date_rfc1123   { require CGI::Minimal::Misc; &_internal_date_rfc1123(@_);         }
sub dehtmlize      { require CGI::Minimal::Misc; &_internal_dehtmlize(@_);            }
sub url_decode     { require CGI::Minimal::Misc; &_internal_url_decode(@_);           }
sub calling_parms_table { require CGI::Minimal::Misc; &_internal_calling_parms_table(@_); }

####

1;

