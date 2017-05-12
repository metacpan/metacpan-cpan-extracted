package Apache::Request::I18N;

use 5.008;
use strict;
use warnings;

use Apache::Request 0.32;
use Carp;
use Encode qw(decode_utf8 encode_utf8);

our @ISA = 'Apache::Request';

our $VERSION = '0.08';


=head1 NAME

Apache::Request::I18N - Internationalization extension to Apache::Request


=head1 SYNOPSIS

  use Apache::Request::I18N;
  my $apr = Apache::Request::I18N->new($r, DECODE_PARMS => 'utf-8');

Or, add something like this to your Apache F<httpd.conf>:

  PerlModule Apache::Request::I18N;

  <Location ...>
  SetHandler  perl-script
  PerlHandler Apache::Request::I18N <your other handlers ...>
  PerlSetVar  DecodeParms  utf-8
  </Location>


=head1 DESCRIPTION

I<Apache::Request::I18N> adds transparent support over I<Apache::Request> for
internationalized GET/POST parameters.  Form field names and values are
automatically decoded and converted either to Perl's internal UTF-8 format, or
to another character encoding.

Since this module inherits from I<Apache::Request>, it can be used as a
drop-in replacement.  (It is not a B<perfect> replacement, though; see
L<"COMPATIBILITY ISSUES"> below.)  It can also be used in a I<PerlHandler>
directive, in which case all subsequent handlers will -- if they play nicely
-- automatically see the converted names and values.


=head1 CONSTRUCTORS

=over 2

=item new( REQ [, OPTIONS ] )

Creates and returns a new I<Apache::Request::I18N> object.  REQ is the
I<Apache> or I<Apache::Request> associated with the current request.

OPTIONS is an optional list of name/value pairs.  Each option also has a
corresponding I<mod_perl> variable (listed in parentheses) that can be set via
I<PerlSetVar> in F<httpd.conf>.  Values in OPTIONS take precedence.  The
available options are:

=over 4

=item DECODE_PARMS (I<DecodeParms>)

I<Required>.  Declares the character encoding that will be used by default
when decoding form field names and values.  This character encoding must be
supported by the I<Encode> module (see L<Encode::Supported> for more details).

=item ENCODE_PARMS (I<EncodeParms>)

Declares the character encoding that will be used to re-encode form field
names and values.  If omitted, names and values will be in Perl's own internal
UTF-8 format.

=back

I<Apache::Request> options can also be included (although they will be ignored
if REQ is already an I<Apache::Request> object).

=cut

sub new {
	my ($class, $r, %args) = @_;

	my $self = bless {
			_decode_parms => delete $args{DECODE_PARMS}
					|| $r->dir_config('DecodeParms'),
			_encode_parms => delete $args{ENCODE_PARMS}
					|| $r->dir_config('EncodeParms'),
		}, $class;
	
	croak "The DECODE_PARMS parameter is currently required"
		unless $self->decode_parms;
	
	$r = Apache::Request->new($r, %args)
		unless $r->isa('Apache::Request');

	$self->{_r} = $r;

	$self->_mangle_parms;

	return $self;
}

=item instance( REQ [, OPTIONS ] )

Equivalent to the I<instance>() method in I<Apache::Request>, except that this
method will return a I<Apache::Request::I18N> object.  Subsequent calls to
I<< Apache::Request->instance >>() will also return the same object.  It is
allowed to call I<< Apache::Request->instance >>() beforehand.

=cut

sub instance {
	my ($class, $r, @args) = @_;

	return unless defined $r;

	my $apreq = $r->pnotes('apreq');

	# Instanciate ourself if necessary; we don't check isa($class) because
	# that only requires reblessing, handled below.
	unless ($apreq && $apreq->isa(__PACKAGE__)) {
		$apreq = $class->new($apreq || $r, @args);
		$r->pnotes('apreq', $apreq);
	}

	# Rebless if we've been called from a subclass
	if ($apreq && ! $apreq->isa($class)) {
		bless $apreq, $class;
	}

	return $apreq;
}

=back

=head1 METHODS

Almost all I<Apache::Request> methods are supported (see L<"COMPATIBILITY
ISSUES"> below for a list of exceptions), and will properly return values
according to ENCODE_PARMS.  (I<Apache> methods, like I<args>(), are not
affected by this module.)

All arguments passed to a method must be encoded to ENCODE_PARMS beforehand,
unless ENCODE_PARMS is empty.  This also applies to each key/value of any
I<Apache::Table> passed to I<parms>().

=cut

sub param {
	my $self = shift;

	# If the parameters are already encoded (ie. EncodeParms is not blank)
	# then our job is done.  Otherwise, we have to decode from UTF-8.
	#
	# TODO: Should we bother to re-encode?
	return $self->SUPER::param(@_) if $self->encode_parms;

	# param() is identical to parms() in scalar context
	return $self->parms if !wantarray && !@_;

	# Encode everything back to UTF-8.  (The second argument may be an
	# array reference.)
	my @args = map ref($_)
				? [ map encode_utf8($_), @$_ ]
				: encode_utf8($_),
			@_;

	# param() is context-sensitive
	if (wantarray) {
		return map decode_utf8($_), $self->SUPER::param(@args);
	} else {
		return decode_utf8 scalar $self->SUPER::param(@args);
	}
}

sub parms {
	my $self = shift;

	# parms() in list context returns an Apache::Table, which cannot
	# handle wide characters, so we croak if ENCODE_PARMS is empty.
	# (Maybe we could subclass Apache::Table and perform some magic?)

	carp 'Calling parms() with empty ENCODE_PARMS is unsupported'
		unless $self->encode_parms;
	
	return $self->SUPER::parms(@_);
}

sub upload {
	my ($self, $arg) = @_;

	my $upload_class = ref($self);
	$upload_class =~ s/\bRequest\b/Upload/;
	unless ($upload_class->isa('Apache::Upload::I18N')) {
		no strict 'refs';
		carp "\@$upload_class\::ISA should contain Apache::Upload::I18N";
		push @{"$upload_class\::ISA"}, 'Apache::Upload::I18N';
	}
	
	# upload(UPLOAD) is implemented, but undefined, so there's little
	# harm in not supporting it...
	if (UNIVERSAL::isa($arg, 'Apache::Upload')) {
		carp 'Calling upload($upload) is unsupported';
		return $self->SUPER::upload($arg);
	}

	unless ($self->{_uploads}) {
		my @uploads = $self->SUPER::upload;
		my %uploads;
		foreach (@uploads) {
			$upload_class->rebless($_, $self);
			push @{ $uploads{ $_->name } }, $_;
		}
		$self->{_uploads} = \@uploads;
		$self->{_uploads_hash} = \%uploads;
	}

	if (defined $arg) {
		my $uploads = $self->{_uploads_hash}{$arg};
		return unless $uploads;
		return wantarray ? @$uploads : $uploads->[0];
	} else {
		return wantarray
			? @{ $self->{_uploads} }
			: $self->{_uploads}[0];
	}
}

=head2 Additional methods

=over

=item decode_parms()

=item encode_parms()

Returns the current DECODE_PARMS or ENCODE_PARMS value.

=cut

sub decode_parms { $_[0]->{_decode_parms} }
sub encode_parms { $_[0]->{_encode_parms} }

=back

=cut


# Our core decode/encode functions.  If encode_parms is empty, we still need
# to encode to UTF-8, since libapreq won't handle wide characters.
sub _decode { Encode::decode($_[2] || $_[0]->decode_parms,  $_[1]) }
sub _encode { Encode::encode($_[0]->encode_parms || 'utf8', $_[1]) }

# Handling of Content-Disposition parameter values (form field names and
# filenames in multipart/form-data) is a bit tricky.  RFC 2047 clearly states
# (section 5) that parameter values cannot contain any encoded-word; however,
# RFC 1867 actually recommended using encoded-word for such purposes, and
# there are reports of browsers doing just that.  So, we support it anyway.
#
# Many browsers don't even bother encoding parameter values, and send them in
# whatever encoding is used for the contents of each HTTP entity.  So, if we
# can't find any encoded-word, we try the usual decoding method.
#
# Proper encoding of parameter values is defined in RFC 2184; unfortunately,
# libapreq does not recognize this format, so we can't support it.

{{
my $SPACE	 = '\040';
my $CTL		 = '\000-\037\377';
my $especials	 = quotemeta '()<>@,;:\\"/[]?.=';

my $token	 = qr/ [^ $SPACE $CTL $especials ]+ /x;
my $charset	 = $token;
my $language	 = $token;
my $encoding	 = $token;
my $encoded_text = qr/ [ \041-\076 \100-\176 ]+ /x;
my $encoded_word = qr/ =\? $charset (?: \* $language )? \? $encoding \?
							$encoded_text \?= /x;

sub _decode_value {
	my ($self, $value) = @_;

	if ($value =~ /$encoded_word/o) {
		return Encode::decode('MIME-Header', $value);
	} else {
		return $self->_decode($value);
	}
}
}}

# Decode all parameters, and re-encode them in ENCODE_PARMS (or UTF-8 if no
# ENCODE_PARMS has been defined, in which case we'll decode them back when
# they are read).

use Apache::Table;
use HTTP::Headers::Util qw(split_header_words);
sub _mangle_parms {
	my ($self) = @_;

	# Remember which arguments were passed on the query string
	# 
	# This used to call Apache->args, but it doesn't behave so well with
	# ill-formed query strings.  Apache::Request->query_params would be
	# nice, but it was introduced in 1.3, and Debian sarge only has 1.1.
	my %args = map { defined $_ ? $_ : '' }
			map Apache::unescape_url_info(defined $_ ? $_ : ''),
				map /^([^=]*)(?:=(.*))?/,
					split /[&;]+/ => $self->query_string;

	# Extract the Content-Type charset for x-www-form-urlencoded
	my ($is_urlenc, $charset);
	my ($ctype) = split_header_words($self->header_in('Content-Type'));
	if ($ctype->[0] && $ctype->[0] eq 'application/x-www-form-urlencoded') {
		$is_urlenc = 1;
		my %tmp = @$ctype;
		$charset = $tmp{charset};
	}

	my $old_parms = $self->SUPER::parms;
	my $new_parms = new Apache::Table $self, scalar keys %$old_parms;

	$old_parms->do( sub {
		my ($key, $val) = @_;

		# POSTed multipart/form-data form field names are supplied as
		# a Content-Disposition parameter, so they are handled
		# differently.

		if ($is_urlenc || $args{$key}) {
			$key = $self->_decode($key, $charset);
		} else {
			$key = $self->_decode_value($key);
		}

		# Same thing for filenames

		if ($self->SUPER::upload($key)) {
			$val = $self->_decode_value($val)
		} else {
			$val = $self->_decode($val, $charset);
		}

		$_ = $self->_encode($_) foreach $key, $val;

		$new_parms->add($key, $val);

		return 1;
	} );

	$self->{_old_parms} = $old_parms;
	$self->SUPER::parms($new_parms);
}


package Apache::Upload::I18N;

use Carp;
use Scalar::Util qw(refaddr);

our @ISA = 'Apache::Upload';

=head1 FILE UPLOADS

Uploads returned by the I<upload>() method are I<Apache::Upload::I18N>
objects; they behave like I<Apache::Upload> objects, and their I<name>() and
I<filename>() methods will return values according to ENCODE_PARMS.

(This is however not the case within the upload hook; see L<"BUGS"> below.)

=cut

# Apache::Upload objects are C structs, and no mechanism is provided to
# subclass them.  We therefore maintain a parallel storage area where each
# object can stash additional information about itself.

{
	my %stashes;

	sub _stash { $stashes{refaddr $_[0]} ||= {} }
	sub _delete_stash { delete $stashes{refaddr $_[0]} }
}

# Each upload object is reblessed into Apache::Upload::I18N, and remembers its
# new name and filename through its stash area.  ($req is needed so we know
# which encoding is used.)

sub rebless {
	my ($class, $upload, $req) = @_;

	return undef unless $upload;

	bless $upload, $class;

	my ($name, $filename) = ($upload->_old_name, $upload->_old_filename);
	foreach ($name, $filename) {
		$_ = $req->_decode_value($_);
		$_ = $req->_encode($_) if $req->encode_parms;
	}

	my $stash = $upload->_stash;
	%$stash = ( name => $name, filename => $filename );

	return $upload;
}

sub DESTROY { $_[0]->_delete_stash }

sub name          { $_[0]->_stash->{name}     }
sub filename      { $_[0]->_stash->{filename} }
sub _old_name     { $_[0]->SUPER::name        }
sub _old_filename { $_[0]->SUPER::filename    }

sub next { carp "next() is not supported"; $_[0]->SUPER::next }


package Apache::Request::I18N;

=head1 HANDLER

This module provides a simple Apache handler that can be used in a
I<PerlHandler> directive.  This is useful when used in combination with other
handlers, which will then automatically access the decoded values.  (This
works as long as each handler takes care to call B<instance>() instead of
creating a new object.)

For example, you can use this module in combination with Mason:

  SetHandler  perl-script
  PerlHandler +Apache::Request::I18N +HTML::Mason::ApacheHandler
  PerlSetVar  DecodeParms  EUC-JP

Each Mason component will now see its arguments as true Perl character
strings instead of EUC-JP bytes strings.

=cut

use Apache::Constants 'DECLINED';
sub handler($$) {
	my ($class, $r) = @_;

	$class->instance($r);

	DECLINED;
}


1;

__END__

=head1 COMPATIBILITY ISSUES

=over

=item *

Calling I<parms>() is not supported if ENCODE_PARMS is empty, as
I<Apache::Table> cannot handle character strings.  This also applies to
calling I<param>() in scalar context.

=item *

Query parameter keys may or may not be case-insensitive, depending on their
contents and on ENCODE_PARMS.

=item *

Calling I<next>() on an upload object is not currently supported.

=back


=head1 BUGS

=over

=item *

When using the B<multipart/form-data> encoding, the proper encoding of form
field names and filenames as specified by RFC 2184 is currently not supported.
(This is due to a limitation in I<libapreq>.)

Conversely, since some user-agents are known to encode such values via RFC
2047, we attempt decoding if possible.  This means that a value supplied by a
standard-compliant user-agent may be wrongly decoded.

=item *

When using the B<multipart/form-data> encoding, each form field value may have
its character encoding specified via the I<charset> parameter of its
I<Content-Type> header.  This value is currently ignored.  (This is due to a
limitation in I<libapreq>.)

Similarly, the I<Content-Transfer-Encoding> header is also ignored.

=item *

When using upload hooks, the upload object supplied to UPLOAD_HOOK will not
have had its I<name>() and I<filename>() decoded yet.

=item *

When using the B<multipart/form-data> encoding, this module will get confused
if a form field appears in both the query string B<and> the request body.  In
other words, don't try to do this:

  <FORM METHOD=post ENCTYPE="multipart/form-data"
  	ACTION=".../my_script?foo=1">
  <INPUT NAME="foo" ...>
  ...

You should also avoid mixing file uploads and regular input within a single
field name.  In other words, don't try this either:

  <INPUT TYPE=text NAME="foo">
  <INPUT TYPE=file NAME="foo">

=item *

Since all query parameter keys are stored in encoded form within an
I<Apache::Table> (which is case-insensitive), it is possible for two distinct
keys to be fused together if their encoded representations are similar.
  
=back


=head1 TODO

=over

=item *

Allow changing DECODE_PARMS and ENCODE_PARMS after the object has been
created.

=for comment
Note that doing so within a Mason component will have no effect, as Mason will
have already parsed and remembered all form fields.

=for comment
We should probably make _mangle_parms lazy, and only call it from param() and
such.

=item *

Automatically decode the contents of a B<text/*> file upload if a charset has
been provided.

=for comment
This should probably be optional, since we wouldn't know what to do with an
upload that doesn't have a charset.  (Neither DECODE_PARMS nor the local
native charset would be appropriate here.)  Besides, if ENCODE_PARMS was
defined, we'll still return a handle that spits out wide characters.  (Come to
think of it, do any user-agents even bother providing a charset anyway?)

=item *

Allow for more than one DECODE_PARMS, and try to guess which one is
appropriate.

=item *

Use the I<User-Agent> header to figure out how far from the standards we must
stray.

=item *

Write a short text about the various standards and issues.


=head1 SEE ALSO

 <http://ppewww.ph.gla.ac.uk/~flavell/charset/form-i18n.html>

 RFC 1522 - MIME (Multipurpose Internet Mail Extensions) Part Two: Message Header Extensions for Non-ASCII Text
 RFC 1806 - Communicating Presentation Information in Internet Messages: The Content-Disposition Header [2.3]
 RFC 1866 - Hypertext Markup Language - 2.0 [8.2.1]
 RFC 1867 - Form-based File Upload in HTML [3.3, 5.11]
 RFC 2047 - MIME (Multipurpose Internet Mail Extensions) Part Three: Message Header Extensions for Non-ASCII Text [5]
 RFC 2070 - Internationalization of the Hypertext Markup Language [5.2]
 RFC 2183 - Communicating Presentation Information in Internet Messages: The Content-Disposition Header Field [2, 2.3]
 RFC 2231 - MIME Parameter Value and Encoded Word Extensions: Character Sets, Languages, and Continuations
 RFC 2388 - Returning Values from Forms: multipart/form-data

=head1 AUTHOR

Frédéric Brière, E<lt>fbriere@fbriere.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2006 by Frédéric Brière

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
