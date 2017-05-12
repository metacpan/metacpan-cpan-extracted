package Data::Validate::URI;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
use AutoLoader 'AUTOLOAD';

use Data::Validate::Domain;
use Data::Validate::IP;

@ISA = qw(Exporter);



# no functions are exported by default.  See EXPORT_OK
@EXPORT = qw();

@EXPORT_OK = qw(
		is_uri
		is_http_uri
		is_https_uri
		is_web_uri
		is_tel_uri
);

%EXPORT_TAGS = ();

$VERSION = '0.07';


# No preloads

1;
__END__

=head1 NAME

Data::Validate::URI - common url validation methods

=head1 SYNOPSIS

  use Data::Validate::URI qw(is_uri);
  
  if(is_uri($suspect)){
  	print "Looks like an URI\n";
  } else {
  	print "Not a URI\n";
  }

  # or as an object
  my $v = Data::Validate::URI->new();
  
  die "not a URI" unless ($v->is_uri('foo'));

=head1 DESCRIPTION

This module collects common URI validation routines to make input validation,
and untainting easier and more readable. 

All functions return an untainted value if the test passes, and undef if
it fails.  This means that you should always check for a defined status explicitly.
Don't assume the return will be true.

The value to test is always the first (and often only) argument.

There are a number of other URI validation modules out there as well (see below.)
This one focuses on being fast, lightweight, and relatively 'real-world'.  i.e.
it's good if you want to check user input, and don't need to parse out the URI/URL
into chunks.

Right now the module focuses on HTTP URIs, since they're arguably the most common.
If you have a specialized scheme you'd like to have supported, let me know.

=head1 FUNCTIONS

=cut

# -------------------------------------------------------------------------------

=pod

=over 4

=item B<new> - constructor for OO usage

  new(%options);

=over 4

=item I<Description>

Returns a Data::Validator::URI object.  This lets you access all the validator function
calls as methods without importing them into your namespace or using the clumsy
Data::Validate::URI::function_name() format.

=item I<Arguments>

=over 4

=item %options

Options to be passed into the underlying Data::Validate::Domain module

=back

=item I<Returns>

Returns a Data::Validate::URI object

=back

=cut

sub new{
	my $class = shift;
	
	return bless {@_}, $class;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_uri> - is the value a well-formed uri?

  is_uri($value);

=over 4

=item I<Description>

Returns the untainted URI if the test value appears to be well-formed.  Note that
you may really want one of the more practical methods like is_http_uri or is_https_uri,
since the URI standard (RFC 3986) allows a lot of things you probably don't want.

=item I<Arguments>

=over 4

=item $value

The potential URI to test.

=back

=item I<Returns>

Returns the untainted URI on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

This function does not make any attempt to check whether the URI is accessible
or 'makes sense' in any meaningful way.  It just checks that it is formatted
correctly.

=back

=cut

sub is_uri{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	
	return unless defined($value);
	
	# check for illegal characters
	return if $value =~ /[^a-z0-9\:\/\?\#\[\]\@\!\$\&\'\(\)\*\+\,\;\=\.\-\_\~\%]/i;
	
	# check for hex escapes that aren't complete
	return if $value =~ /%[^0-9a-f]/i;
	return if $value =~ /%[0-9a-f](:?[^0-9a-f]|$)/i;
	
	# from RFC 3986
	my($scheme, $authority, $path, $query, $fragment) = _split_uri($value);
	
	# scheme and path are required, though the path can be empty
	return unless (defined($scheme) && length($scheme) && defined($path));
	
	# if authority is present, the path must be empty or begin with a /
	if(defined($authority) && length($authority)){
		return unless(length($path) == 0 || $path =~ m!^/!);
	
	} else {
		# if authority is not present, the path must not start with //
		return if $path =~ m!^//!;
	}
	
	# scheme must begin with a letter, then consist of letters, digits, +, ., or -
	return unless lc($scheme) =~ m!^[a-z][a-z0-9\+\-\.]*$!;
	
	# re-assemble the URL per section 5.3 in RFC 3986
	my $out = $scheme . ':';
	if(defined $authority && length($authority)){
		$out .= '//' . $authority;
	}
	$out .= $path;
	if(defined $query && length($query)){
		$out .= '?' . $query;
	}
	if(defined $fragment && length($fragment)){
		$out .= '#' . $fragment;
	}
	
	return $out;
	
}

# -------------------------------------------------------------------------------

sub _test_uri {
	# 1 = HTTP only
	# 2 = HTTPS only
	# 3 = both HTTP and HTTPS are allowed
	my $allowed_scheme = shift;
	my $value = shift;
	my $options = shift // {};
	
	return unless is_uri($value);
	
	my($scheme, $authority, $path, $query, $fragment) = _split_uri($value);
	
	return unless $scheme;
	
	if($allowed_scheme == 1) {
		return unless lc($scheme) eq 'http';
	} elsif ($allowed_scheme == 2) {
		return unless lc($scheme) eq 'https'
	} elsif ($allowed_scheme == 3) {
		return unless lc($scheme) =~ m/^https?$/;
	} else {
		return;
	}
	
	# fully-qualified URIs must have an authority section that is
	# a valid host
	return unless($authority);
	
	# allow a port component
	my($port) = $authority =~ /:(\d+)$/;
	$authority =~ s/:\d+$//;
	
	# modifying this to allow the (discouraged, but still legal) use of IP addresses
	unless(Data::Validate::Domain::is_domain($authority, $options) || Data::Validate::IP::is_ipv4($authority)){
		return;
	}
	
	# re-assemble the URL per section 5.3 in RFC 3986
	my $out = $scheme . ':';
	$out .= '//' . $authority;
	
	$out .= ':' . $port if $port;
	
	$out .= $path;
	
	if(defined $query && length($query)){
		$out .= '?' . $query;
	}
	if(defined $fragment && length($fragment)){
		$out .= '#' . $fragment;
	}
	
	return $out;
}

=pod

=item B<is_http_uri> - is the value a well-formed HTTP uri?

  is_http_uri($value, \%options);

=over 4

=item I<Description>

Specialized version of is_uri() that only likes http:// urls.  As a result, it can
also do a much more thorough job validating.  Also, unlike is_uri() it is more
concerned with only allowing real-world URIs through.  Things like relative
hostnames are allowed by the standards, but probably aren't wise.  Conversely,
null paths aren't allowed per RFC 2616 (should be '/' instead), but are allowed
by this function.

This function only works for fully-qualified URIs.  /bob.html won't work.  
See RFC 3986 for the appropriate method to turn a relative URI into an absolute 
one given its context.

Returns the untainted URI if the test value appears to be well-formed.

Note that you probably want to either call this in combo with is_https_uri(). i.e.

print "Good" if(is_http_uri($uri) || is_https_uri($uri));

or use the convenience method is_web_uri which is equivalent and faster, because
it does the work only once.

=item I<Arguments>

=over 4

=item $value

The potential URI to test.

=item \%options

Options to be passed into the underlying Data::Validate::Domain module. If
called as a method, the options are ignored.

=back

=item I<Returns>

Returns the untainted URI on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

This function does not make any attempt to check whether the URI is accessible
or 'makes sense' in any meaningful way.  It just checks that it is formatted
correctly.

=back

=cut

sub is_http_uri{
	my $self = shift if ref($_[0]);
	my $value = shift;
	$self //= shift;

	return _test_uri(1, $value, $self);
}


# -------------------------------------------------------------------------------

=pod

=item B<is_https_uri> - is the value a well-formed HTTPS uri?

  is_https_uri($value. \%options);

=over 4

=item I<Description>

See is_http_uri() for details.  This version only likes the https URI scheme.
Otherwise it's identical to is_http_uri()

=item I<Arguments>

=over 4

=item $value

The potential URI to test.

=item \%options

Options to be passed into the underlying Data::Validate::Domain module. If
called as a method, the options are ignored.

=back

=item I<Returns>

Returns the untainted URI on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

This function does not make any attempt to check whether the URI is accessible
or 'makes sense' in any meaningful way.  It just checks that it is formatted
correctly.

=back

=cut

sub is_https_uri{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	$self //= shift;
	
	return _test_uri(2, $value, $self);
}


# -------------------------------------------------------------------------------

=pod

=item B<is_web_uri> - is the value a well-formed HTTP or HTTPS uri?

  is_web_uri($value, \%options);

=over 4

=item I<Description>

This is just a convinience method that combines is_http_uri and is_https_uri
to accept most common real-world URLs. But it's faster, because it does the
work only once.

=item I<Arguments>

=over 4

=item $value

The potential URI to test.

=item \%options

Options to be passed into the underlying Data::Validate::Domain module. If
called as a method, the options are ignored.

=back

=item I<Returns>

Returns the untainted URI on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

This function does not make any attempt to check whether the URI is accessible
or 'makes sense' in any meaningful way.  It just checks that it is formatted
correctly.

=back

=cut

sub is_web_uri{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	$self //= shift;

	return _test_uri(3, $value, $self);
}

# -------------------------------------------------------------------------------

=pod

=item B<is_tel_uri> - is the value a well-formed telephone uri?

  is_tel_uri($value);

=over 4

=item I<Description>

Specialized version of is_uri() that only likes tel: urls.  As a result, it can
also do a much more thorough job validating according to RFC 3966.

Returns the untainted URI if the test value appears to be well-formed.

=item I<Arguments>

=over 4

=item $value

The potential URI to test.

=back

=item I<Returns>

Returns the untainted URI on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

This function does not make any attempt to check whether the URI is accessible
or 'makes sense' in any meaningful way.  It just checks that it is formatted
correctly.

=back

=cut

sub is_tel_uri{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	
	# extracted from http://tools.ietf.org/html/rfc3966#section-3

	my $hex_digit = '[a-fA-F0-9]'; # strictly hex digit does not allow lower case letters according to http://tools.ietf.org/html/rfc2234#section-6.1
	my $reserved = '[;/?:@&=+$,]';
	my $alphanum = '[A-Za-z0-9]';
	my $visual_separator = '[\-\.\(\)]';
	my $phonedigit_hex = '(?:' . $hex_digit . '|\*|\#|' . $visual_separator . ')';
	my $phonedigit = '(?:' . '\d' . '|' . $visual_separator . ')';
	my $param_unreserved = '[\[\]\/:&+$]';
	my $pct_encoded = '\\%' . $hex_digit . $hex_digit;
	my $mark = "[\-_\.!~*'()]";
	my $unreserved = '(?:' . $alphanum . '|' . $mark . ')';
	my $paramchar = '(?:' . $param_unreserved . '|' . $unreserved . '|' . $pct_encoded . ')';
	my $pvalue = $paramchar . '{1,}';
	my $pname = '(?:' . $alphanum . '|\\-){1,}';
	my $uric = '(?:' . $reserved . '|' . $unreserved . '|' . $pct_encoded . ')';
	my $alpha = '[A-Za-z]';
	my $toplabel = '(?:' . $alpha . '|' . $alpha . '(?:' . $alphanum . '|' . '\\-){0,}' . $alpha . ')';
	my $domainlabel = '(?:' . $alphanum . '|' . $alphanum . '(?:' . $alphanum . '|\\-){0,}' . $alphanum . ')';
	my $domainname = '(?:' . $domainlabel . '\\.){0,}' . $toplabel . '\\.{0,1}';

	# extracted from http://tools.ietf.org/html/rfc4694#section-4
	my $npdi = ';npdi';
	my $hex_phonedigit = '(?:' . $hex_digit . '|' . $visual_separator . ')';
	my $global_hex_digits = '\\+' . '\\d{1,3}' . $hex_phonedigit . '{0,}';
	my $global_rn = $global_hex_digits;
	my $rn_descriptor = '(?:' . $domainname . '|' . $global_hex_digits . ')';
	my $rn_context = ';rn-context=' . $rn_descriptor;
	my $local_rn = $hex_phonedigit . '{1,}' . $rn_context;
	my $global_cic = $global_hex_digits;
	my $cic_context = ';cic-context=' . $rn_descriptor;
	my $local_cic = $hex_phonedigit . '{1,}' . $cic_context;
	my $cic = ';cic=' . '(?:' . $global_cic . '|' . $local_cic . '){0,1}';
	my $rn = ';rn=' . '(?:' . $global_rn . '|' . $local_rn . '){0,1}';

	if ($value =~ /$rn.*$rn/xsm) {
		return;
	}
	if ($value =~ /$npdi.*$npdi/xsm) {
		return;
	}
	if ($value =~ /$cic.*$cic/xsm) {
		return;
	}
	my $parameter = '(?:;' . $pname . '(?:=' . $pvalue . ')|' . $rn . '|' . $cic . '|' . $npdi . ')';

	# end of http://tools.ietf.org/html/rfc4694#section-4

	my $local_number_digits = '(?:' . $phonedigit_hex . '{0,}' . '(?:' . $hex_digit . '|\*|\#)' . $phonedigit_hex . '{0,})';
	my $global_number_digits = '\+' . $phonedigit . '{0,}' . '[0-9]' . $phonedigit . '{0,}';
	my $descriptor = '(?:' . $domainname . '|' . $global_number_digits . ')';
	my $context = ';phone\-context=' . $descriptor;
	my $extension = ';ext=' . $phonedigit . '{1,}';
	my $isdn_subaddress = ';isub=' . $uric . '{1,}';

	# extracted from http://tools.ietf.org/html/rfc4759
	my $enum_dip_indicator = ';enumdi';
	if ($value =~ /$enum_dip_indicator.*$enum_dip_indicator/xsm) { # http://tools.ietf.org/html/rfc4759#section-3
		return;
	}

	# extracted from http://tools.ietf.org/html/rfc4904#section-5
	my $trunk_group_unreserved = '[/&+$]';
	my $escaped = '\\%' . $hex_digit . $hex_digit; # according to http://tools.ietf.org/html/rfc3261#section-25.1
	my $trunk_group_label = '(?:' . $unreserved . '|' . $escaped . '|' . $trunk_group_unreserved . '){1,}';
	my $trunk_group = ';tgrp=' . $trunk_group_label; 
	my $trunk_context = ';trunk\-context=' . $descriptor;


	my $par = '(?:' . $parameter . '|' . $extension . '|' . $isdn_subaddress . '|' . $enum_dip_indicator . '|' . $trunk_context . '|' . $trunk_group . ')';
	my $local_number = $local_number_digits . $par . '{0,}' . $context . $par . '{0,}';
	my $global_number = $global_number_digits . $par . '{0,}';
	my $telephone_subscriber = '(?:' . $global_number . '|' . $local_number . ')';
	my $telephone_uri = 'tel:' . $telephone_subscriber;

	if ($value =~ /^($telephone_uri)$/xsm) {
		my ($untainted) = ($1);
		return $untainted;
	} else {
		return;
	}
}

# internal URI spitter method - direct from RFC 3986
sub _split_uri{
	my $value = shift;
	
	my @bits = $value =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;
	
	return @bits;
}
	

=pod

=back

=head1 SEE ALSO

L<URI>, RFC 3986, RFC 3966, RFC 4694, RFC 4759, RFC 4904

=head1 AUTHOR

Richard Sonnen <F<sonnen@richardsonnen.com>>.

is_tel_uri by David Dick <F<ddick@cpan.org>>.


=head1 COPYRIGHT

Copyright (c) 2005 Richard Sonnen. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
