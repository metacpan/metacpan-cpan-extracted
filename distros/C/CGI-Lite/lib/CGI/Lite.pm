##++
##     CGI Lite v3.01
##
##     see separate CHANGES file for detailed history
##
##     Changes in versions 2.03 and newer copyright (c) 2014-2015 Pete Houston
##
##     Copyright (c) 1995, 1996, 1997 by Shishir Gundavaram
##     All Rights Reserved
##
##     Permission  to  use,  copy, and distribute is hereby granted,
##     providing that the above copyright notice and this permission
##     appear in all copies and in supporting documentation.
##--

###############################################################################

=head1 NAME

CGI::Lite - Process and decode WWW forms and cookies

=head1 SYNOPSIS

    use CGI::Lite ();

    my $cgi = CGI::Lite->new ();

    $cgi->set_directory ('/some/dir') or die "Directory cannot be set.\n";
    $cgi->add_mime_type ('text/csv');

    my $cookies = $cgi->parse_cookies;
    my $form    = $cgi->parse_new_form_data;

    my $status  = $cgi->is_error;
    if ($status) {
        my $message = $cgi->get_error_message;
        die $message;
    }

=head1 DESCRIPTION

This module can be used to decode form data, query strings, file uploads
and cookies in a very simple manner.

It has only one dependency and is therefore relatively fast to
instantiate. This makes it well suited to a non-persistent CGI scenario.

=head1 METHODS

Here are the methods used to process the forms and cookies:



=head2 new

The constructor takes no arguments and returns a new CGI::Lite object.

=head2 parse_form_data

This handles the following types of requests: GET, HEAD and POST.
By default, CGI::Lite uses the environment variable REQUEST_METHOD to 
determine the manner in which the query/form information should be 
decoded. However, it may also be passed a valid request 
method as a scalar string to force CGI::Lite to decode the information in 
a specific manner. 

	my $params = $cgi->parse_form_data ('GET');

For multipart/form-data, uploaded files are stored in the user selected 
directory (see L<set_directory|/set_directory>). If timestamp mode is on (see 
L<add_timestamp|/add_timestamp>), the files are named in the following format:

    timestamp__filename

where the filename is specified in the "Content-disposition" header.
I<NOTE:>, the browser URL encodes the name of the file. This module
makes I<no> effort to decode the information for security reasons.
However, this can be achieved by creating a subroutine and then using
the L<filter_filename|/filter_filename> method.

Returns either a hash or a reference to the hash, which contains
all of the key/value pairs. For fields that contain file information,
the value contains either the path to the file, or the filehandle 
(see the L<set_file_type|/set_file_type> method).

=head2 parse_new_form_data

As for parse_form_data, but clears the CGI object state before processing 
the request. This is useful in persistent applications (e.g. FCGI), where
the CGI object is reused for multiple requests. e.g.

    my $CGI = CGI::Lite->new ();
    while (FCGI::accept > 0)
    {
        my $query = $CGI->parse_new_form_data ();
        # process query
    }

=head2 parse_cookies

Decodes and parses cookies passed by the browser. This method works in 
much the same manner as L<parse_form_data|/parse_form_data>. As these two data sources
are treated the same internally, users who wish to extract form and
cookie data separately might find it easiest to call
parse_cookies first and then parse_new_form_data in order to retrieve
two distinct hashes (or hashrefs).

=head2 is_error

This method is used to check for any potential errors after calling
either L<parse_form_data|/parse_form_data> or L<parse_cookies|/parse_cookies>.

    my $form = $cgi->parse_form_data ();
    my $went_wrong = $cgi->is_error ();

Returns 0 if there is no error, 1 otherwise.

=head2 get_error_message

If an error occurs when parsing form/query information or cookies, this
method may be used to retrieve the error message. Remember, the presence
of any errors can be checked by calling the L<is_error|/is_error> method.

    my $msg = $cgi->get_error_message ();

Returns the error message as a plain text string.

=head2 set_platform

This method is used to set the platform on which the web server is
running. CGI::Lite uses this information to translate end-of-line
(EOL) characters for uploaded files (see the L<add_mime_type|/add_mime_type> and
L<remove_mime_type|/remove_mime_type> methods) so that they are accounted for properly on
that platform.

    $cgi->set_platform ($platform);

$platform can be any of (case insensitive):

    Unix                                  EOL: \012      = \n
    Windows, Windows95, DOS, NT, PC       EOL: \015\012  = \r\n
    Mac or Macintosh                      EOL: \015      = \r

"Unix" is the default.

Returns undef.

=head2 set_size_limit

To set a specific limit on the total size of the request (in bytes) call
this method with that size as the sole argument. A size of zero
effectively disables POST requests. To specify an unlimited size (the
default) use an argument of -1.

    my $size_limit = $cgi->set_size_limit (10_000_000);

Returns the new value if provided, otherwise the existing value.

=head2 deny_uploads

To prevent any file uploads simply call this method with an argument of
1. To enable them again, use an argument of zero.

    my $deny_uploads = $cgi->deny_uploads (1);

Returns the new value if provided, otherwise the existing value.

=head2 force_unique_cookies

It is generally considered a mistake to send an HTTP request with
multiple cookies of the same name. However, the RFC is somewhat vague
regarding how servers are expected to handle such an eventuality.
CGI::Lite has always allowed such multiple values and returned them as
an arrayref to be entirely consistent with the same treatment of
form/query data.

To override the default behaviour this method may be called with a
single integer argument before the call to L<parse_cookies|/parse_cookies>. An argument
of 1 means that the first cookie value will be used and the others
discarded. An argument of 2 means that the last cookie value will be
used and the others discarded. An argument of 3 means that an arrayref
will be returned as usual but an error raised to indicate the situation.
An argument of 0 (or any other value) sets it back to the default.

    $cgi->force_unique_cookies (1);
    $cgi->parse_cookies;

Note that if there is already an item of data in the CGI::Lite object
which matches the name of a cookie then the subsequent L<parse_cookies|/parse_cookies>
call will treat the new cookie value as another data item and the resulting
behaviour will be affected by this method. This is another reason to
call L<parse_cookies|/parse_cookies> before L<parse_form_data|/parse_form_data>.

Returns the new value if provided, otherwise the existing value.

=head2 set_directory

Used to set the directory where the uploaded files will be stored 
(only applies to the I<multipart/form-data> encoding scheme).

    my $tmpdir = '/some/dir';
    $cgi->set_directory ($tmpdir) or
        die "Directory $tmpdir cannot be used.\n";

This function should be called I<before> L<parse_form_data|/parse_form_data>, 
or else the directory defaults to "/tmp". If the application cannot 
write to the directory for whatever reason, an error status is returned.

Returns 0 on error, 1 otherwise.

=head2 close_all_files

    $cgi->close_all_files;

All uploaded files that are opened as a result of calling L<set_file_type|/set_file_type>
with the "handle" argument can be closed in one shot by calling this
method which takes no arguments and returns undef.

=head2 add_mime_type

By default, EOL characters are translated for all uploaded files
with specific MIME types (i.e. text/plain, text/html, etc.).
This method can be used to add to the list of MIME types. For example,
if you want CGI::Lite to translate EOL characters for uploaded
files of I<application/mac-binhex40>, then you would do this:

    $cgi->add_mime_type ('application/mac-binhex40');

Returns 1 if this MIME type is newly added, 0 otherwise.

=head2 remove_mime_type

This method is the converse of L<add_mime_type|/add_mime_type>. It allows for the
removal of a particular MIME type. For example, if you do not want 
CGI::Lite to translate EOL characters for uploaded files of type I<text/html>, 
then you would do this:

    $cgi->remove_mime_type ('text/html');

Returns 1 if this MIME type is newly deleted, 0 otherwise.

=head2 get_mime_types

Returns the list of the 
MIME types for which EOL translation is performed.

    my @mimelist = $cgi->get_mime_types ();

=head2 get_upload_type

Returns the MIME type of uploaded data. Takes the field name as a scalar
argument. This previously undocumented function was named print_mime_type
prior to version 3.0.

    my $this_type = $cgi->get_upload_type ($field);

Returns the MIME type as a scalar string if single valued, an arrayref
if multi-valued or undef if the argument does not exist or has no type.

=head2 set_file_type

The I<names> of uploaded files are returned by default when
the L<parse_form_data|/parse_form_data> method is called . But if this method is passed the string "handle" as its argument beforehand then
the I<handles> to the files are returned instead. However, the name
of each handle still corresponds to the filename.

    # $fh has been set to one of 'handle' or 'file'
    $cgi->set_file_type ($fh);

This function should be called I<before> any call to L<parse_form_data|/parse_form_data>, or 
else it will have no effect.

=head2 add_timestamp

By default, a timestamp is added to the front of uploaded files. 
However, there is the option of completely turning off timestamp mode
(value 0), or adding a timestamp only for existing files (value 2).

    $cgi->add_timestamp ($tsflag);	
    # where $tsflag takes one of these values
    #       0 = no timestamp
    #       1 = timestamp all files (default)
    #       2 = timestamp only if file exists

=head2 filter_filename

This method is used to change the manner in which uploaded
files are named. For example, if you want uploaded filenames
to be all upper case, you can use the following code:

    $cgi->filter_filename (\&make_uppercase);
    $cgi->parse_form_data;

    # ...

    sub make_uppercase
    {
        my $file = shift;

        $file =~ tr/a-z/A-Z/;
        return $file;
    }

This method is perhaps best used to sanitise filenames for a specific
O/S or filesystem e.g. by removing spaces or leading hyphens, etc.

=head2 set_buffer_size

This method allows fine-grained control of the buffer size used internally
when dealing with multipart form data. However, the I<actual> buffer
size that the algorithm uses I<can> be up to 3x the value specified
as the argument. This ensures that boundary strings are not "split"
between multiple reads. So, take this into consideration when setting
the buffer size.

    my $size = $cgi->set_buffer_size (4096);

The buffer size may not be set below 256 bytes nor above the total amount 
of multipart form data. The default value is 1024 bytes. 

Returns the buffer size.

=head2 get_ordered_keys

Returns either a reference to an array or an array itself consisting
of the form fields/cookies in the order they were parsed.

    my $keys = $cgi->get_ordered_keys;
    my @keys = $cgi->get_ordered_keys;

=head2 print_data

Displays all the key/value pairs (either form data or cookie information)
in an ordered fashion to standard output. It is mainly useful for
debugging. There are no arguments and no return values.

=head2 wrap_textarea

This is a method to wrap a long string into one that is separated by EOL
characters (see L<set_platform|/set_platform>) at fixed lengths.  The two arguments
to be passed to this method are the string and the length at which the
line separator is to be added.

    my $new_string = $cgi->wrap_textarea ($string, $length);

Returns the modified string.

=head2 get_multiple_values

The values returned by the parsing methods in this module for multiple
fields with the same name are given as array references. This utility
method exists to convert either a scalar value or an array reference
into a list thus removing the need for the user to determine whether the
returned value for any field is a reference or a scalar.

    @all_values = $cgi->get_multiple_values ($reference);

It is only provided as a convenience to the user and is not used
internally by the module itself.

Returns a list consisting of the multiple values.

=head2 browser_escape

Certain characters have special significance within HTML. These
characters are: <, >, &, ", # and %. To display these "special"
characters, they can be escaped using the following notation "&#NNN;"
where NNN is their ASCII code.  This utility method does just that.

    $escaped_string = $cgi->browser_escape ($string);

Returns the escaped string.

=head2 url_encode

This method will URL-encode a string passed as its argument. It may be
used to encode any data to be passed as a query string to a CGI
application, for example.

    $encoded_string = $cgi->url_encode ($string);

Returns the URL-encoded string.

=head2 url_decode

This method is used to URL-decode a string. 

    $decoded_string = $cgi->url_decode ($string);

Returns the URL-decoded string.

=head2 is_dangerous

This method checks for the existence of dangerous meta-characters.

    $status = $cgi->is_dangerous ($string);

Returns 1 if such characters are found, 0 otherwise.



=head1 DEPRECATED METHODS

The following methods and subroutines are deprecated. Please do not use
them in new code and consider excising them from old code. They will be
removed in a future release.

=over 4

=item B<return_error>

    $cgi->return_error ('error 1', 'error 2', 'error 3');

You can use this method to print errors to standard output (ie. as part of
the HTTP response) and exit. B<This method is deprecated as of version 3.0.>
The same functionality can be achieved with:

    print ('error 1', 'error 2', 'error 3');
    exit 1;

=item B<create_variables>

B<This method is deprecated as of version 3.0.> It runs contrary to the
principles of structured programming and has really nothing to do with
CGI form or cookie handling. It is retained here for backwards
compatibility but will be removed entirely in later versions.

    %form = ('name'   => 'alan wells',
             'sport'  => 'track and field',
             'events' => '100m');

    $cgi->create_variables (\%hash);

This converts a hash ref into scalars named for its keys and this
example will create three scalar variables: $name, $sport and $events. 

=back

=head1 OBSOLETE METHODS/SUBROUTINES

The following methods and subroutines were deprecated in the 2.x branch
and have now been removed entirely from the module.

=over 4

=item B<escape_dangerous_chars>

The use of this subroutine had been strongly discouraged for more than a
decade (See
L<https://web.archive.org/web/20100627014535/http://use.perl.org/~cbrooks/journal/10542>
and L<http://www.securityfocus.com/archive/1/311414> for an
advisory by Ronald F. Guilmette.) It has been removed as of version 3.0.

=item B<print_form_data>

Use L<print_data|/print_data> instead.

=item B<print_cookie_data>

Use L<print_data|/print_data> instead.

=back

Compatibility note: in 2.x and older versions the following were to be used as
subroutines rather than methods:

=over 4

=item browser_escape

=item url_encode

=item url_decode

=item is_dangerous

=back

They will still work as such and are still exported
by default. Users are encouraged to migrate to the new method calls
instead as both the export and subroutine interface will be retired in
future. Non-method use currently triggers a warning.

=head1 VERSIONS

This module maintained backwards compatibility with versions of
Perl back to 5.002 for a very long time. Such stability is a welcome
attribute but it restricts the code by disallowing access to features
introduced into the language since 1996.

With this in mind, there are two maintained branches of this module going
forwards. The 2.x branch will retain the backwards compatibility but
will not have any new features introduced. Changes to this legacy branch
will be bug fixes only. The new 3.x branch will be the main release and
will require a more modern perl (5.6.0 is now the bare minimum). The
3.x branch has new features and has removed some of the legacy code
including some methods which had been deprecated for more than a decade.
The attention of users wishing to upgrade from 2.x to 3.x is drawn to
the L</DEPRECATED METHODS> and L</OBSOLETE METHODS/SUBROUTINES> sections of this
document.

Requests for new features in the 3.x branch should be made via
the request tracker at L<https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Lite>

=head1 SEE ALSO

If you're looking for more comprehensive CGI modules, you can either use
the CGI::* modules or L<CGI.pm|CGI>. 

L<CGI::Lite::Request> uses some similar method names to CGI.pm thus allowing
easy transition between the two. It uses CGI::Lite as a dependency.

L<CGI::Simple>, L<CGI::Minimal> and L<CGI::Thin> are alternative
lightweight CGI implementations.

=head1 REPOSITORY

L<https://github.com/openstrike/perl-CGI-Lite>

=head1 MAINTAINER

Maintenance of this module as of May 2014 has been taken over by Pete Houston
<cpan@openstrike.co.uk>.

=head1 ACKNOWLEDGMENTS

The author (Shishir) thanks the following for finding bugs
and offering suggestions:

=over 4

=item Eric D. Friedman (friedman@uci.edu)   

=item Thomas Winzig (tsw@pvo.com)

=item Len Charest (len@cogent.net)

=item Achim Bohnet (ach@rosat.mpe-garching.mpg.de)

=item John E. Townsend (John.E.Townsend@BST.BLS.com)

=item Andrew McRae (mcrae@internet.com)

=item Dennis Grant (dg50@chrysler.com)

=item Scott Neufeld (scott.neufeld@mis.ussurg.com)

=item Raul Almquist (imrs@ShadowMAC.org)

=item and many others!

=back

The present maintainer wishes to thank the previous maintainers:
Smylers, Andreas, Ben and Shishir.

=head1 COPYRIGHT INFORMATION
    
Copyright (c) 1995, 1996, 1997 by Shishir Gundavaram.
All Rights Reserved.

Changes in versions 2.03 onwards are copyright 2014, 2015 by Pete Houston.

Permission to use, copy, and  distribute  is  hereby granted,
providing that the above copyright notice and this permission
appear in all copies and in supporting documentation.

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

###############################################################################

package CGI::Lite;

use strict;
use warnings;

require 5.6.0;

use Symbol;    # For _create_handles and create_variables

##++
## Global Variables
##--

BEGIN {
	our @ISA    = 'Exporter';
	our @EXPORT = qw/browser_escape url_encode url_decode is_dangerous/;
}

our $VERSION = '3.01';

##++
##  Start
##--

sub new
{
	my $class = shift;

	my $self = {
		multipart_dir   => '/tmp',
		file_type       => 'name',
		platform        => 'Unix',
		buffer_size     => 1024,
		timestamp       => 1,
		filter          => undef,
		web_data        => {},
		ordered_keys    => [],
		all_handles     => [],
		error_status    => 0,
		error_message   => undef,
		file_size_limit => 2097152,    # Unused as yet
		size_limit      => -1,
		deny_uploads    => 0,
		unique_cookies  => 0,
	};

	$self->{convert} = {
		'text/html'  => 1,
		'text/plain' => 1
	};

	$self->{file} = {Unix => '/',    Mac => ':',    PC => '\\'};
	$self->{eol}  = {Unix => "\012", Mac => "\015", PC => "\015\012"};

	bless ($self, $class);
	return $self;
}

sub Version
{
	return $VERSION;
}

sub deny_uploads
{
	my ($self, $newval) = @_;
	if (defined $newval) {
		$self->{deny_uploads} = $newval ? 1 : 0;
	}
	return $self->{deny_uploads};
}

sub set_size_limit
{
	my ($self, $limit) = @_;
	return unless defined $limit;
	if ($limit =~ /^[0-9]+$/) {
		$self->{size_limit} = $limit;
	} else {
		$self->{size_limit} = -1;
	}
	return $self->{size_limit};
}

sub set_directory
{
	my ($self, $directory) = @_;

	return 0 unless $directory;
	stat ($directory);

	if ((-d _) && (-r _) && (-w _)) {
		$self->{multipart_dir} = $directory;
		return (1);

	} else {
		return (0);
	}
}

sub add_mime_type
{
	my ($self, $mime_type) = @_;

	if ($mime_type and not exists $self->{convert}->{$mime_type}) {
		return $self->{convert}->{$mime_type} = 1;
	}
	return 0;
}

sub remove_mime_type
{
	my ($self, $mime_type) = @_;

	if ($self->{convert}->{$mime_type}) {
		delete $self->{convert}->{$mime_type};
		return (1);

	} else {
		return (0);
	}
}

sub get_mime_types
{
	my $self = shift;

	return (sort keys %{$self->{convert}});
}

sub set_platform
{
	my ($self, $platform) = @_;

	return unless defined $platform;
	if ($platform =~ /^(?:PC|NT|Windows(?:95)?|DOS)/i) {
		$self->{platform} = 'PC';
	} elsif ($platform =~ /^Mac(?:intosh)?/i) {
		$self->{platform} = 'Mac';
	} else {
		$self->{platform} = 'Unix';
	}
}

sub set_file_type
{
	my ($self, $type) = @_;

	if ($type =~ /^handle$/i) {
		$self->{file_type} = 'handle';
	} else {
		$self->{file_type} = 'name';
	}
}

sub add_timestamp
{
	my ($self, $value) = @_;

	unless ($value == 0 or $value == 1 or $value == 2) {
		$self->{timestamp} = 1;
	} else {
		$self->{timestamp} = $value;
	}
}

sub force_unique_cookies
{
	my ($self, $value) = @_;

	if (defined $value) {
		if ($value =~ /^[1-3]$/) {
			$self->{unique_cookies} = $value;
		} else {
			$self->{unique_cookies} = 0;
		}
	}
	return $self->{unique_cookies};
}

sub filter_filename
{
	my ($self, $subroutine) = @_;

	$self->{filter} = $subroutine;
}

sub set_buffer_size
{
	my ($self, $buffer_size) = @_;
	my $content_length;

	$content_length = $ENV{CONTENT_LENGTH} || return (0);

	if ($buffer_size < 256) {
		$self->{buffer_size} = 256;
	} elsif ($buffer_size > $content_length) {
		$self->{buffer_size} = $content_length;
	} else {
		$self->{buffer_size} = $buffer_size;
	}

	return ($self->{buffer_size});
}

sub parse_new_form_data

# Reset state before parsing (for persistant CGI objects, e.g. under FastCGI)
# BDL
{
	my ($self, @param) = @_;

	# close files (should happen anyway when 'all_handles' is cleared...)
	$self->close_all_files ();

	$self->{web_data}      = {};
	$self->{ordered_keys}  = [];
	$self->{all_handles}   = [];
	$self->{error_status}  = 0;
	$self->{error_message} = undef;

	$self->parse_form_data (@param);
}

sub parse_form_data
{
	my ($self, $user_request) = @_;
	my ($request_method, $content_length, $content_type, $query_string,
		$boundary, $post_data, @query_input);

	# Force into object method
	unless (ref ($self)) { $self = $self->new; }
	$request_method = $user_request        || $ENV{REQUEST_METHOD} || '';
	$content_length = $ENV{CONTENT_LENGTH} || 0;
	$content_type   = $ENV{CONTENT_TYPE};

	# If we've set a size limit, check that it has not been exceeded
	if ($self->{size_limit} > -1 and $content_length > $self->{size_limit}) {
		$self->_error ("Content lenth $content_length exceeds limit of "
			  . $self->{size_limit});
		return;
	}

	if ($request_method =~ /^(get|head)$/i) {

		$query_string = $ENV{QUERY_STRING};
		$self->_decode_url_encoded_data (\$query_string, 'form');

		return wantarray ? %{$self->{web_data}} : $self->{web_data};

	} elsif ($request_method =~ /^post$/i) {

		if (!$content_type
			|| ($content_type =~ /^application\/x-www-form-urlencoded/)) {

			read (STDIN, $post_data, $content_length);
			$self->_decode_url_encoded_data (\$post_data, 'form');

			return wantarray ? %{$self->{web_data}} : $self->{web_data};

		} elsif ($content_type =~ /multipart\/form-data/) {

			if ($self->{deny_uploads}) {
				$self->_error ("multipart/form-data unacceptable when "
					  . "deny_uploads is set");
				return;
			}
			($boundary) = $content_type =~ /boundary=(\S+)$/;
			$self->_parse_multipart_data ($content_length, $boundary);

			return wantarray ? %{$self->{web_data}} : $self->{web_data};

		} else {
			$self->_error ('Invalid content type!');
		}

	} else {

		##++
		##  Got the idea of interactive debugging from CGI.pm, though it's
		##  handled a bit differently here. Thanks Lincoln!
		##--

		print "[ Reading query from standard input. Press ^D to stop! ]\n";

		@query_input = <>;
		chomp (@query_input);

		$query_string = join ('&', @query_input);
		$query_string =~ s/\\(.)/sprintf ('%%%02X', ord ($1))/eg;

		$self->_decode_url_encoded_data (\$query_string, 'form');

		return wantarray ? %{$self->{web_data}} : $self->{web_data};
	}
}

sub parse_cookies
{
	my $self = shift;
	my $cookies;

	$cookies = $ENV{HTTP_COOKIE} || return;

	$self->_decode_url_encoded_data (\$cookies, 'cookies');

	return wantarray ? %{$self->{web_data}} : $self->{web_data};
}

sub get_ordered_keys
{
	my $self = shift;

	return wantarray ? @{$self->{ordered_keys}} : $self->{ordered_keys};
}

sub print_data
{
	my $self = shift;

	my $eol = $self->{eol}->{$self->{platform}};

	foreach my $key (@{$self->{ordered_keys}}) {
		my $value = $self->{web_data}->{$key};

		if (ref $value) {
			print "$key = @$value$eol";
		} else {
			print "$key = $value$eol";
		}
	}
}

sub get_upload_type
{
	my ($self, $field) = @_;

	return ($self->{'mime_types'}->{$field});
}

sub wrap_textarea
{
	my ($self, $string, $length) = @_;
	my ($new_string, $platform, $eol);

	$length     = 70 unless ($length);
	$platform   = $self->{platform};
	$eol        = $self->{eol}->{$platform};
	$new_string = $string || return;

	$new_string =~ s/[\0\r]\n?/ /sg;
	$new_string =~ s/(.{0,$length})\s/$1$eol/sg;

	return $new_string;
}

sub get_multiple_values
{
	my ($self, $array) = @_;

	return (ref $array) ? (@$array) : $array;
}

sub create_variables
{
	my ($self, $hash) = @_;
	my ($package, $key, $value);

	$package = $self->_determine_package;

	while (($key, $value) = each %$hash) {
		my $this = Symbol::qualify_to_ref ($key, $package);
		$$$this = $value;
	}
}

sub is_error
{
	my $self = shift;

	if ($self->{error_status}) {
		return (1);
	} else {
		return (0);
	}
}

sub get_error_message
{
	my $self = shift;

	return $self->{error_message} if ($self->{error_message});
}

sub return_error
{
	my ($self, @messages) = @_;

	print "@messages\n";

	exit (1);
}

##++
##  Exported Subroutines and Methods
##--

sub browser_escape
{
	my ($self, $string) = @_;

	unless (eval { $self->isa ('CGI::Lite'); }) {
		my @rep = caller;
		warn "Non-method use of browser_escape is deprecated "
		  . "in $rep[0] at line $rep[2] of $rep[1]\n";
		$string = $self;
	}
	$string =~ s/([<&"#%>])/sprintf ('&#%d;', ord ($1))/ge;

	return $string;
}

sub url_encode
{
	my ($self, $string) = @_;

	unless (eval { $self->isa ('CGI::Lite'); }) {
		my @rep = caller;
		warn "Non-method use of url_encode is deprecated "
		  . "in $rep[0] at line $rep[2] of $rep[1]\n";
		$string = $self;
	}

	$string =~ s/([^-.\w ])/sprintf('%%%02X', ord $1)/ge;
	$string =~ tr/ /+/;

	return $string;
}

sub url_decode
{
	my ($self, $string) = @_;

	unless (eval { $self->isa ('CGI::Lite'); }) {
		my @rep = caller;
		warn "Non-method use of url_decode is deprecated "
		  . "in $rep[0] at line $rep[2] of $rep[1]\n";
		$string = $self;
	}

	$string =~ tr/+/ /;
	$string =~ s/%([\da-fA-F]{2})/chr (hex ($1))/eg;

	return $string;
}

sub is_dangerous
{
	my ($self, $string) = @_;

	unless (eval { $self->isa ('CGI::Lite'); }) {
		my @rep = caller;
		warn "Non-method use of is_dangerous is deprecated "
		  . "in $rep[0] at line $rep[2] of $rep[1]\n";
		$string = $self;
	}

	if ($string =~ /[;<>\*\|`&\$!#\(\)\[\]\{\}:'"]/) {
		return (1);
	} else {
		return (0);
	}
}

##++
##  Internal Methods
##--

sub _error
{
	my ($self, $message) = @_;

	$self->{error_status}  = 1;
	$self->{error_message} = $message;
}

sub _determine_package
{
	my $self = shift;
	my ($frame, $this_package, $find_package);

	$frame = -1;
	($this_package) = split (/=/, $self);

	do {
		$find_package = caller (++$frame);
	} until ($find_package !~ /^$this_package/);

	return ($find_package);
}

##++
##  Decode URL encoded data
##--

sub _decode_url_encoded_data
{
	my ($self, $reference_data, $type) = @_;
	return unless ($$reference_data);

	my (@key_value_pairs, $delimiter);

	@key_value_pairs = ();

	if ($type eq 'cookies') {
		$delimiter = qr/[;,]\s*/;
	} else {

		# Only other option is form data
		$delimiter = qr/[;&]/;
	}

	@key_value_pairs = split ($delimiter, $$reference_data);

	foreach my $key_value (@key_value_pairs) {
		my ($key, $value) = split (/=/, $key_value, 2);

		# avoid 'undef' warnings for "key=" BDL Jan/99
		$value = '' unless defined $value;

		# avoid 'undef' warnings for bogus URLs like 'foobar.cgi?&foo=bar'
		next unless defined $key;

		if ($type eq 'cookies') {

			# Strip leading/trailling whitespace as per RFC 2965
			$key   =~ s/^\s+|\s+$//g;
			$value =~ s/^\s+|\s+$//g;
		}

		$key   = $self->url_decode ($key);
		$value = $self->url_decode ($value);

		if (defined ($self->{web_data}->{$key})) {
			if ($type eq 'cookies' and $self->{unique_cookies} > 0) {
				if ($self->{unique_cookies} == 1) {
					next;
				} elsif ($self->{unique_cookies} == 2) {
					$self->{web_data}->{$key} = $value;
					next;
				} else {
					$self->_error ("Multiple instances of cookie $key");
				}
			}
			$self->{web_data}->{$key} = [$self->{web_data}->{$key}]
			  unless (ref $self->{web_data}->{$key});

			push (@{$self->{web_data}->{$key}}, $value);
		} else {
			$self->{web_data}->{$key} = $value;
			push (@{$self->{ordered_keys}}, $key);
		}
	}

	return;
}

##++
##  Methods dealing with multipart data
##--

sub _parse_multipart_data
{
	my ($self, $total_bytes, $boundary) = @_;
	my $files = {};
	$boundary = quotemeta ($boundary);

	eval {

		my ($seen,      $buffer_size, $byte_count,    $platform,
			$eol,       $handle,      $directory,     $bytes_left,
			$new_data,  $old_data,    $this_boundary, $current_buffer,
			$changed,   $store,       $disposition,   $headers,
			$mime_type, $convert,     $field,         $file,
			$new_name,  $full_path
		);

		$seen        = {};
		$buffer_size = $self->{buffer_size};
		$byte_count  = 0;
		$platform    = $self->{platform};
		$eol         = $self->{eol}->{$platform};
		$directory   = $self->{multipart_dir};

		while (1) {
			if (   ($byte_count < $total_bytes)
				&& (length ($current_buffer || '') < ($buffer_size * 2))) {

				$bytes_left = $total_bytes - $byte_count;
				$buffer_size = $bytes_left if ($bytes_left < $buffer_size);

				read (STDIN, $new_data, $buffer_size);
				$self->_error ("Oh, Oh! I'm upset! Can't read what I want.")
				  if (length ($new_data) != $buffer_size);

				$byte_count += $buffer_size;

				if ($old_data) {
					$current_buffer = join ('', $old_data, $new_data);
				} else {
					$current_buffer = $new_data;
				}

			} elsif ($old_data) {
				$current_buffer = $old_data;
				$old_data       = undef;

			} else {
				last;
			}

			$changed = 0;

			##++
			##  When Netscape Navigator creates a random boundary string, you
			##  would expect it to pass that _same_ value in the environment
			##  variable CONTENT_TYPE, but it does not! Instead, it passes a
			##  value that has the first two characters ("--") missing.
			##--

			if ($current_buffer =~
				/(.*?)((?:\015?\012)?-*$boundary-*[\015\012]*)(?=(.*))/os) {

				($store, $this_boundary, $old_data) = ($1, $2, $3);

				if ($current_buffer =~
					/[Cc]ontent-[Dd]isposition: ([^\015\012]+)\015?\012  # Disposition
					(?:([A-Za-z].*?)(?:\015?\012))?                     # Headers
					(?:\015?\012)                                       # End
					(?=(.*))                                            # Other Data
					/xs
				  ) {

					($disposition, $headers, $current_buffer) = ($1, $2, $3);
					$old_data = $current_buffer;

					$headers ||= '';
					($mime_type) = $headers =~ /[Cc]ontent-[Tt]ype: (\S+)/;

					$self->_store ($platform, $file, $convert, $handle, $eol,
						$field, \$store, $seen);

					close ($handle) if (ref ($handle) and fileno ($handle));

					if ($mime_type && $self->{convert}->{$mime_type}) {
						$convert = 1;
					} else {
						$convert = 0;
					}

					$changed = 1;

					($field) = $disposition =~ /name="([^"]+)"/;
					++$seen->{$field};

					unless ($self->{'mime_types'}->{$field}) {
						$self->{'mime_types'}->{$field} = $mime_type;
					} elsif (ref $self->{'mime_types'}->{$field}) {
						push @{$self->{'mime_types'}->{$field}}, $mime_type;
					} else {
						$self->{'mime_types'}->{$field} = 
							[$self->{'mime_types'}->{$field}, $mime_type];
					}

					if ($seen->{$field} > 1) {
						$self->{web_data}->{$field} =
						  [$self->{web_data}->{$field}]
						  unless (ref $self->{web_data}->{$field});
					} else {
						push (@{$self->{ordered_keys}}, $field);
					}

					if (($file) = $disposition =~ /filename="(.*)"/) {
						$file =~ s|.*[:/\\](.*)|$1|;

						$new_name =
						  $self->_get_file_name ($platform, $directory, $file);

						if (ref $self->{web_data}->{$field}) {
							push @{$self->{web_data}->{$field}}, $new_name
						} else {
							$self->{web_data}->{$field} = $new_name;
						}

						$full_path =
						  join ($self->{file}->{$platform}, $directory,
							$new_name);

						open ($handle, '>', $full_path)
						  or $self->_error ("Can't create file: $full_path!");

						$files->{$new_name} = $full_path;
					}
				} elsif ($byte_count < $total_bytes) {
					$old_data = $this_boundary . $old_data;
				}

			} elsif ($old_data) {
				$store    = $old_data;
				$old_data = $new_data;

			} else {
				$store          = $current_buffer;
				$current_buffer = $new_data;
			}

			unless ($changed) {
				$self->_store ($platform, $file, $convert, $handle, $eol,
					$field, \$store, $seen);
			}
		}

		close ($handle) if ($handle and fileno ($handle));

	};    # End of eval

	$self->_error ($@) if $@;

	$self->_create_handles ($files) if ($self->{file_type} eq 'handle');
}

sub _store
{
	my ($self, $platform, $file, $convert, $handle, $eol, $field, $info, $seen)
	  = @_;

	if ($file) {
		if ($convert) {
			if ($platform eq 'PC') {
				$$info =~ s/\015(?=[^\012])|(?<=[^\015])\012/$eol/og;
			} else {
				$$info =~ s/\015\012/$eol/og;
				$$info =~ s/\015/$eol/og if ($platform ne 'Mac');
				$$info =~ s/\012/$eol/og if ($platform ne 'Unix');
			}
		}

		binmode $handle;
		print $handle $$info;

	} elsif ($field) {
		if ($seen->{$field} > 1) {
			$self->{web_data}->{$field}->[$seen->{$field} - 1] .= $$info;
		} else {
			$self->{web_data}->{$field} .= $$info;
		}
	}
}

sub _get_file_name
{
	my ($self, $platform, $directory, $file) = @_;
	my ($filtered_name, $filename, $timestamp, $path);

	$filtered_name = &{$self->{filter}}($file)
	  if (ref ($self->{filter}) eq 'CODE');

	$filename = $filtered_name || $file;
	$timestamp = time . '__' . $filename;

	if (!$self->{timestamp}) {
		return $filename;

	} elsif ($self->{timestamp} == 1) {
		return $timestamp;

	} else {    # $self->{timestamp} must be 2
		$path = join ($self->{file}->{$platform}, $directory, $filename);

		return (-e $path) ? $timestamp : $filename;
	}
}

sub _create_handles
{
	my ($self, $files) = @_;
	my ($package, $handle, $name, $path);

	$package = $self->_determine_package;

	while (($name, $path) = each %$files) {
		$handle = Symbol::qualify_to_ref ($name, $package);
		open ($handle, '<', $path)
		  or $self->_error ("Can't read file: $path! $!");

		push (@{$self->{all_handles}}, $handle);
	}
}

sub close_all_files
{
	my $self = shift;

	foreach my $handle (@{$self->{all_handles}}) {
		close $handle;
	}
}

1;

