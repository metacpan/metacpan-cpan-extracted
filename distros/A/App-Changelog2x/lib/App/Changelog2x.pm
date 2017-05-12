###############################################################################
#
# This file copyright (c) 2008-2009 by Randy J. Ray, all rights reserved
#
# Copying and distribution are permitted under the terms of the Artistic
# License 2.0 (http://www.opensource.org/licenses/artistic-license-2.0.php) or
# the GNU LGPL (http://www.opensource.org/licenses/lgpl-license.php).
#
###############################################################################
#
#   Description:    A wrapper in the App::* space for the core functionality
#                   provided by the changelog2x script.
#
#   Functions:      new
#                   version
#                   default_xslt_path
#                   default_date_format
#                   date_format
#                   xslt_path
#                   application_tokens
#                   format_date
#                   credits
#                   transform_changelog
#
#   Libraries:      XML::LibXML
#                   XML::LibXSLT
#                   DateTime
#                   DateTime::Format::ISO8601
#                   File::Spec
#
#   Global Consts:  $VERSION
#                   URI
#
###############################################################################

package App::Changelog2x;

use 5.008;
use strict;
use warnings;
use vars qw($VERSION $FORMAT $DEFAULT_XSLT_PATH);
use subs qw(new version default_xslt_path default_date_format date_format
            xslt_path application_tokens format_date credits
            transform_changelog);
use constant URI => 'http://www.blackperl.com/2009/01/ChangeLogML';

use File::Spec;

use XML::LibXML;
use XML::LibXSLT;
use DateTime;
use DateTime::Format::ISO8601;

BEGIN
{
    $VERSION = '0.11';

    $DEFAULT_XSLT_PATH = (File::Spec->splitpath(__FILE__))[1];
    $DEFAULT_XSLT_PATH = File::Spec->catdir($DEFAULT_XSLT_PATH, 'changelog2x');
}

###############################################################################
#
#   Sub Name:       new
#
#   Description:    Dead-simple constructor. We're just a plain blessed
#                   hashref, here.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Class to bless into
#                   %args     in      hash      Any data to start off with
#
#   Returns:        object referent
#
###############################################################################
sub new
{
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    # If the user didn't pass the xslt_path argument, set up the default
    $args{xslt_path} ||= [ $self->default_xslt_path ];

    foreach (qw(date_format xslt_path))
    {
        # These are the known parameters; if present, call the method to set
        $self->$_(delete $args{$_}) if $args{$_};
    }

    # Copy over any remaining parameters we don't know verbatim
    for (keys %args)
    {
        $self->{$_} = $args{$_};
    }

    $self;
}

# Encapsulated way of retrieving $VERSION, in case someone sub-classes us
sub version             { $VERSION }

# Likewise access to $DEFAULT_XSLT_PATH
sub default_xslt_path   { $DEFAULT_XSLT_PATH }

# And the default date-format
sub default_date_format { '%A %B %e, %Y, %r TZ_SHORT' }

###############################################################################
#
#   Sub Name:       date_format
#
#   Description:    Get or set a default format string for format_date() to
#                   use. If $format is passed, set that as the new format to
#                   use. If no format is set by the user, falls through to
#                   default_date_format().
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $format   in      scalar    New format string
#
#   Returns:        Date format
#
###############################################################################
sub date_format
{
    my ($self, $format) = @_;

    if ($format)
    {
        $self->{format} =
            ($format eq 'unix') ? '%a %b %d %T TZ_SHORT %Y' : $format;
    }

    $self->{format} || $self->default_date_format;
}

###############################################################################
#
#   Sub Name:       xslt_path
#
#   Description:    Return the path to where XSLT files should be searched for.
#                   If this is not set by the user, then return the value for
#                   default_xslt_path(). If a value is passed for $path, make
#                   that the new XSLT directory.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $paths    in      list      New directories to use.
#
#   Returns:        path
#
###############################################################################
sub xslt_path
{
    my ($self, @paths) = @_;

    if (@paths)
    {
        if (ref($paths[0]) eq 'ARRAY')
        {
            $self->{xslt_path} = [ @{$paths[0]} ];
        }
        else
        {
            unshift(@{$self->{xslt_path}}, @paths);
        }
    }

    wantarray ? @{$self->{xslt_path}} : $self->{xslt_path};
}

###############################################################################
#
#   Sub Name:       application_tokens
#
#   Description:    Get/set the string that should be present in the "credits"
#                   string, identifying the application that is using this
#                   class to transform ChangeLogML.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $tokens   in      scalar    If present, string/tokens to
#                                                 store for later use
#
#   Returns:        application tokens
#
###############################################################################
sub application_tokens
{
    my ($self, $tokens) = @_;

    $self->{application_tokens} = $tokens if $tokens;

    $self->{application_tokens};
}

###############################################################################
#
#   Sub Name:       format_date
#
#   Description:    Take a date-string in (ISO 8601 format) and return a
#                   more readable format.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      scalar    Class name or object ref
#                   $date     in      scalar    Date-string in ISO 8601
#                   $to_utc   in      scalar    Boolean flag, whether to
#                                                 convert times to GMT/UTC
#
#   Returns:        Formatted date/time
#
###############################################################################
sub format_date
{
    my ($self, $date, $to_utc) = @_;

    my $dt = DateTime::Format::ISO8601->parse_datetime($date);
    $dt->set_time_zone('UTC') if $to_utc;

    my $string = $dt->strftime($self->date_format);
    if ($string =~ /TZ_/)
    {
        my %tz_edit = ( TZ_LONG  => $dt->time_zone->name,
                        TZ_SHORT => $dt->time_zone->short_name_for_datetime );
        $string =~ s/(TZ_LONG|TZ_SHORT)/$tz_edit{$1}/ge;
    }

    $string;
}

###############################################################################
#
#   Sub Name:       credits
#
#   Description:    Produce a "credits" message for inclusion in transformed
#                   output. Combines app name and version, lib name and
#                   version, etc.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      scalar    Class name or object ref
#
#   Globals:        $cmd
#                   $VERSION
#
#   Returns:        credits string
#
###############################################################################
sub credits
{
    my $self = shift;

    my $credits =
        sprintf("%s/%s, XML::LibXML/%s, XML::LibXSLT/%s, libxml/%s, " .
                "libxslt/%s (with%s exslt)",
                ref($self), $self->version,
                $XML::LibXML::VERSION, $XML::LibXSLT::VERSION,
                XML::LibXML::LIBXML_DOTTED_VERSION(),
                XML::LibXSLT::LIBXSLT_DOTTED_VERSION(),
                (XML::LibXSLT::HAVE_EXSLT() ? '' : 'out'));
    if (my $apptokens = $self->application_tokens)
    {
        $credits = "$apptokens, $credits";
    }

    $credits;
}

###############################################################################
#
#   Sub Name:       transform_changelog
#
#   Description:    Take a filehandle or string for input, a filehandle for
#                   output, filename/string of a XSL transform, and optional
#                   parameters. Process the input according to the XSLT and
#                   stream the results to the output handle.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      scalar    Class name or object ref
#                   $xmlin    in      scalar    Filehandle to read/parse or
#                                                 string
#                   $xmlout   in      ref       Filehandle to output the
#                                                 transformed XML to
#                   $style    in      scalar    Stylesheet, either a string
#                                                 or the name of a file
#                   $params   in      hashref   If present, parameters that
#                                                 should be converted for use
#                                                 in the XSLT and passed in.
#
#   Globals:        URI
#
#   Returns:        Success:    null
#                   Failure:    dies
#
###############################################################################
sub transform_changelog
{
    my ($self, $xmlin, $xmlout, $style, $params) = @_;
    $params ||= {}; # In case they didn't pass any

    our $parser = XML::LibXML->new();
    our $xslt   = XML::LibXSLT->new();

    $parser->expand_xinclude(1);
    $xslt->register_function(URI, 'format-date',
                             sub { $self->format_date(@_) });
    $xslt->register_function(URI, 'credits',
                             sub { $self->credits(@_) });

    our (%params, $xsltc, $source, $stylesheet, $result);

    # If the template isn't already an absolute path, use the root-dir and add
    # the "changelog2" prefix and ".xslt" suffix
    unless ($style =~ /^<\?xml/)
    {
        $xsltc = $self->resolve_template($style)
            or die "Could not resolve style '$style' to a file";
        $style = $xsltc;
    }

    # First copy over and properly setup/escape the parameters, so that XSLT
    # understands them.
    %params = map { XML::LibXSLT::xpath_to_string($_ => $params->{$_}) }
        (keys %$params);

    # Do the steps of parsing XML documents, creating stylesheet engine and
    # applying the transform. Each throws a die on error, so each has to be
    # eval'd to allow for a cleaner error report:
    eval {
        $source = ref($xmlin) ?
            $parser->parse_fh($xmlin) : $parser->parse_string($xmlin);
    };
    die "Error parsing input-XML content: $@" if $@;
    eval {
        $xsltc = ($style =~ /^<\?xml/) ?
            $parser->parse_string($style) : $parser->parse_file($style);
    };
    die "Error parsing the XML of the XSLT stylesheet '$style': $@" if $@;
    eval { $stylesheet = $xslt->parse_stylesheet($xsltc); };
    die "Error parsing the XSLT syntax of the stylesheet: $@" if $@;
    eval { $result = $stylesheet->transform($source, %params); };
    die "Error applying transform to input content: $@" if $@;

    $stylesheet->output_fh($result, $xmlout);
    return;
}

###############################################################################
#
#   Sub Name:       resolve_template
#
#   Description:    Resolve a non-absolute template name to a complete file.
#                   This may include adding "changelog2" and ".xslt" to the
#                   string. If the name is already absolute or starts with a
#                   '.', it is returned unchanged.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $template in      scalar    Name to resolve
#
#   Returns:        Success:    full path
#                   Failure:    empty string
#
###############################################################################
sub resolve_template
{
    my ($self, $template) = @_;

    return $template if ((substr($template, 0, 1) eq '.') ||
                         File::Spec->file_name_is_absolute($template));

    my @paths = $self->xslt_path;
    my $candidate;

    $template = "changelog2$template.xslt" unless ($template =~ /\.xslt?/i);

    for (@paths)
    {
        $candidate = File::Spec->catfile($_, $template);
        last if -f $candidate;
        undef $candidate;
    }

    $candidate;
}

1;

__END__

=head1 NAME

App::Changelog2x - A wrapper-class for the functionality of changelog2x

=head1 SYNOPSIS

    use App::Changelog2x;

    my $app = App::Changelog2x->new(xslt_path => [ ... ]);

    $app->transform_changelog(...);

=head1 DESCRIPTION

This class provides the core functionality for the B<changelog2x>
application. It manages a list of search-paths for locating XSLT stylesheets
and performs the transformation of ChangeLogML content using the
B<XML::LibXML> and B<XML::LibXSLT> modules.

The transformation of content via XSLT is augmented by the registering of
some functions into the XML namespace associated with ChangeLogML, before the
B<XML::LibXSLT> instance performs the transformation.

=head1 METHODS

The following methods are available:

=over 4

=item new [ARGS]

This is the constructor for the class. An optional list of key/value pairs
may passed as arguments. The recognized arguments are:

=over 8

=item application_tokens

=item date_format

=item xslt_path

These parameters are stored on the new object by called the corresponding
accessor method (defined below) with the value of the parameter. This allows
sub-classes of this class to implement different methods if they desire.
The default behavior is to just store the values on the hash reference with
the parameter names as keys.

=back

Any other key/value pairs are stored on the hash reference unchanged.

=item version

Returns the current version of this module (used in the C<credits> method,
below).

=item default_date_format

Returns the default date format, a string that is passed to the C<strftime>
method of B<DateTime>. The default format is a slightly more-verbose
version of the UNIX "date" format, with full day- and month-names and a
12-hour clock rather than 24-hour. A typical date formatted this way would
look like this:

    Friday September 19, 2008, 02:23:12 AM -0700

=item default_xslt_path

Returns the default path to use when searching for XSLT stylesheets that are
not already absolute-path filenames. The default path for this module is a
directory called C<changelog2x> that resides in the same directory as this
module.

=item date_format [FORMAT]

Get or set the date-format to use when C<format_date> is called. If the user
does not explicitly set a format, the value returned by C<default_date_format>
is used.

See L<DateTime/"strftime Patterns"> for a description of the formatting
codes to use in a format string.

One special value is recognized: C<unix>. If C<date_format> is called with
this value as a format string, a pre-defined format is used that emulates the
UNIX C<date> command as closely as possible (but see L</CAVEATS> for notes
on B<DateTime> limitations with regards to timezone names and the special
patterns recognized in date format strings to try and work around this). A
string formatted this way looks like this:

    Mon Aug 10 09:21:46 -0700 2009

=item xslt_path [DIRS]

Get or set the directories to use when searching for XSLT stylesheets that are
not specified by absolute pathname.

If the user passes one or more directories, they are added at the head of the
list of paths stored by the object and used internally to resolve templates
that are not absolute paths.

If the user passes a list-reference, its contents become the new search path
(completely replacing the existing set of directories).

If no values are passed, the return value is either a list-reference to the
array of search paths (in scalar context) or the full list itself (in
array context).

=item application_tokens [STRING]

Get or set the string identifying the application that is using this class
to transform ChangeLogML content. If the user sets a value with this
accessor (or by passing this parameter to the constructor), it is included
in the string produced by the C<credits> method (detailed below). If the
user does not set this string, nothing is added to the credits.

=item format_date ISO_8601_DATE

Takes a string containing a date in ISO 8601 format, and re-formats it
according to the format pattern specified by either C<date_format> or
C<default_date_format>. Returns the (re-)formatted date.

This method is not generally intended for end-user utilization. It is bound
to the ChangeLogML namespace URI with the name C<format-date> for use by the
XSLT processor.

=item credits

Produces a string listing the names and versions of all components used in
the rendering of the ChangeLogML. This consists of:

    app/ver, mod/ver, LibXML/ver, LibXSLT/ver,
    libxml/ver, libxslt/ver ({ with | without } exslt)

(line broken for clarity only, the string has no embedded newlines)

where:

=over 8

=item app/ver

The value of C<application_tokens>, if set by the user. If this was not set
there is no content added, not even the comma.

=item mod/ver

The name of the class this object is a referent of (C<ref $self>), and the
value of the C<version> method.

=item LibXML/ver

The string C<XML::LibXML> and the version of B<XML::LibXML> used at run-time.

=item LibXSLT/ver

The string C<XML::LibXSLT> and the version of B<XML::LibXSLT> used at run-time.

=item libxml/ver

The string C<libxml> and the version of the B<libxml2> C library linked in to
B<XML::LibXML>.

=item libxslt/ver

The string C<libxslt> and the version of the B<libxslt> C library linked in to
B<XML::LibXSLT>.

Additionally, whether B<libxslt> was built with support for EXSLT is denoted
at the end of this string by one of C<(with exslt)> or C<(without exslt)>.

=back

This method is not generally intended for end-user utilization. It is bound
to the ChangeLogML namespace URI with the name C<credits> for use by the
XSLT processor.

=item transform_changelog INPUT, OUTPUT, STYLE [, PARAMS]

This method performs the actual transformation of ChangeLogML content. There
are three required parameters and one optional parameter:

=over 8

=item INPUT

This parameter must be either an open filehandle or a string containing the
ChangeLogML XML content to be transformed. If the value is not a reference,
it is assumed to be XML content.

=item OUTPUT

This parameter must be an open filehandle, to which the transformed XML
content is written. This may be any object that acts like a filehandle;
an B<IO::File> instance, the result of an C<open> call, etc.

=item STYLE

This parameter specifies the XSLT stylesheet to use. This may be a filename
path or a string.  A "string" is defined as a value consisting of only
alphanumeric characters (those matching the Perl C<\w> regular expression
character class).

If the value of this parameter matches the pattern C<^\w+$>, then the string
is used to construct a path to a XSLT file. The file is assumed to be named
"changelog2I<< string >>.xslt", and is looked for in the directory declared as
the root for templates (see the C<xslt_path> and C<default_xslt_path>
methods).

If the parameter does not match the pattern, it is assumed to be a file name.
If it is not an absolute path, it is searched for using the set of XSLT
directories. As a special case, if the path starts with a C<.> character, it
is not converted to an absolute path.

Once the full path and name of the file has been determined, if it cannot be
opened or read an error is reported.

=item PARAMS

This parameter is optional. If it is passed, it must be a hash-reference.
The keys of the hash table represent parameters to the XSLT stylesheet, and
the values of the hash are the corresponding values for the stylesheet
parameters.

See L<changelog2x> for a detailed list of the stylesheet parameters
recognized by the XSLT stylesheets bundled with this distribution.

=back

If an error occurs during any of the processing stages, C<die> is called
with the error message from B<XML::LibXML> or B<XML::LibXSLT>, whichever
was the source of the problem.

=item resolve_template TEMPLATE

Takes a template/stylesheet name and resolves it to a full (absolute) file
name. If the value passed in does not end in either C<.xsl> or C<.xslt>
(case-insensitive), then the value is augmented to C<changelog2TEMPLATE.xslt>
before searching for it. This is the naming-pattern used by the default
templates packaged with this distribution (C<html>, C<text>, etc.). All
directories currently in the XSLT search path (as set by B<xslt_path>) are
searched, in order, for the file. The first occurance of the file is used.

If no match is found for TEMPLATE, a null string is returned. If TEMPLATE is
already an absolute path, or if the first character of the string is C<.>,
then it is considered to already be an absolute path and is returned
unchanged.

=back

=head1 CAVEATS

The B<DateTime> package does not attempt to map timezone values to the old
3-letter codes that were once the definitive representation of timezones.
Because timezones are now much more granular in definition, a timezone offset
cannot be canonically mapped to a specific name. The only timezone that can be
canonically mapped is UTC. Thus, for now, timezones in dates are given as their
offsets from UTC, unless the date is being rendered in UTC directly.

=head1 SEE ALSO

L<changelog2x>, L<https://sourceforge.net/projects/changelogml>

=head1 AUTHOR

Randy J. Ray C<< <rjray@blackperl.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-changelog2x at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Changelog2x>. I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Changelog2x>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Changelog2x>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Changelog2x>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Changelog2x>

=back

=head1 COPYRIGHT & LICENSE

This file and the code within are copyright (c) 2008 by Randy J. Ray.

Copying and distribution are permitted under the terms of the Artistic
License 2.0 (L<http://www.opensource.org/licenses/artistic-license-2.0.php>) or
the GNU LGPL 2.1 (L<http://www.opensource.org/licenses/lgpl-2.1.php>).
