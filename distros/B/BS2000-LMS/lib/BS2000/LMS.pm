package BS2000::LMS;
#
# Copyright 2003 Thomas Dorner
#
# Author: see end of file
# Created: 24. July 2003
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

=head1 NAME

BS2000::LMS - Perl extension for library access under BS2000

=head1 SYNOPSIS

  use BS2000::LMS;

  $library = new BS2000::LMS '$.SYSLIB.CRTE';
  print $_->{type}, ' ', $_->{name}, "\n"
    foreach ($library->list(type => 'S', name => 'CSTD*'));

=head1 ABSTRACT

This module is a Perl extension to access BS2000 libraries using the
LMS API (Library Maintenance System, Subroutine Interface).  It is only
useful for the BS2000 port of Perl.

=head1 DESCRIPTION

Access to BS2000 libraries in Perl is implemented using accessor
objects.

See the different METHODS for details.

=head2 EXPORT

Several constants originating in the BS2000 system include C<lms.h>
are exported.  They are put into the following groups:

=over

=item I<:returncodes>

for all possible return codes C<LMSUP_OK>, C<LMSUP_TRUNC>,
C<LMSUP_EOF>, C<LMSUP_LMSERR>, C<LMSUP_PARERR>, C<LMSUP_SEQERR> and
C<LMSUP_INTERR>

=item I<:storage_form>

for the different storage forms (full and delta) C<LMSUP_FULL> and
C<LMSUP_DELTA>

=item I<:hold_state>

for the source code control states C<LMSUP_FREE> and C<LMSUP_INHOLD>

=back

An additional group C<:all> gives you access to all, so if you type

  use BS2000::LMS qw(:all);

you may use any of them.

=head1 METHODS

=cut

#########################################################################

use 5.006;
use strict;
use warnings;

our $VERSION = '0.08';

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK =
    qw(LMSUP_OK LMSUP_TRUNC LMSUP_EOF
       LMSUP_LMSERR LMSUP_PARERR LMSUP_SEQERR LMSUP_INTERR
       LMSUP_FULL LMSUP_DELTA LMSUP_FREE LMSUP_INHOLD);
our %EXPORT_TAGS =
    (
     'all'
     => [qw(LMSUP_OK LMSUP_TRUNC LMSUP_EOF
	    LMSUP_LMSERR LMSUP_PARERR LMSUP_SEQERR LMSUP_INTERR
	    LMSUP_FULL LMSUP_DELTA LMSUP_FREE LMSUP_INHOLD)],
     'returncodes'
     => [qw(LMSUP_OK LMSUP_TRUNC LMSUP_EOF
	    LMSUP_LMSERR LMSUP_PARERR LMSUP_SEQERR LMSUP_INTERR)],
     'storage_form'
     => [qw(LMSUP_FULL LMSUP_DELTA)],
     'hold_state'
     => [qw(LMSUP_FREE LMSUP_INHOLD)],
    );

require XSLoader;
XSLoader::load('BS2000::LMS', $VERSION);

use Carp;
use POSIX qw(strftime);

# returncodes (from lms.h):
use constant LMSUP_OK => 0;
use constant LMSUP_TRUNC => 4;	# record truncated (buffer to short)
use constant LMSUP_EOF => 8;	# EOF in element or table of contents
use constant LMSUP_LMSERR => 12; # user error
use constant LMSUP_PARERR => 20; # wrong or insufficient parameters
use constant LMSUP_SEQERR => 24; # wrong sequence of calls
use constant LMSUP_INTERR => 28; # internal LMS (library) error

# storage form (from lms.h):
use constant LMSUP_FULL => 'V';
use constant LMSUP_DELTA => 'D';

# source code control (from lms.h):
use constant LMSUP_FREE => '-';
use constant LMSUP_INHOLD => 'H';

# pseudo constants (never changed, used in regular expressions):
my $bs2_filename_char = '[-A-Z0-9$#@.]'; # max. 41
my $bs2_linkname_char = '[-A-Z0-9$#@]';	# max. 8
my $bs2_elemname_char = '[-A-Z0-9$#@_]'; # max. 132

#########################################################################

=head2 B<new> - create a new LMS accessor object

    $accessor_object =
	new BS2000::LMS $library_name [, $is_linkname_flag ];

  or

    $accessor_object =
	BS2000::LMS->new($library_name [, $is_linkname_flag ]);

Example:

    $library = new BS2000::LMS '$.SYSLIB.CRTE';

  or

    $library = BS2000::LMS->new('LIBLINK1', 1);

This is the constructor for a a new LMS accessor object.  The first
parameter is the mandatory name of the library.	 If the first
parameter should specify a BS2000 link name, the optional second
parameter must be set to true.

An accessor object contains the following important elements:

=over

=item I<link_name>

the link name if the library is accessed by link name (empty
otherwise)

=item I<name>

the name of the library if it is not accessed by link name (empty
otherwise)

=item I<return_code>

the last return code set by a call to the LMS API (see also the method
C<rc_message> described later)

=item I<plam_message>

the last PLAM (program library access method) message set by a call to
the LMS API (see also the methods C<message> and C<rc_message>
described later)

=item I<lms_message>

the last LMS message set by a call to the LMS API (see also the
methods C<message> and C<rc_message> described later)

=item I<dms_message>

the last DMS message set by a call to the LMS API (see also the
methods C<message> and C<rc_message> described later)

=item I<lms_version>

the version of the LMS API used

=back

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my %accessor_object = ();
    local $_;

    # clone object (if applicable):
    if (ref($this))
    {
	$accessor_object{$_} = $this->{$_} foreach (keys %$this);
	# don't use linkname for clone (unless real name is unknown):
	$accessor_object{link_name} = '' if $accessor_object{name} ne '';
    }
    # otherwise, analyze parameters:
    else
    {
	my ($library_name, $is_linkname) = @_;
	$accessor_object{link_name} = $is_linkname ? $library_name : '';
	$accessor_object{name} = $is_linkname ? '' : $library_name;
	croak $accessor_object{link_name}, ' is not a valid link name'
	    unless $accessor_object{link_name}
		=~ m/^$bs2_linkname_char{0,8}$/o;
    }

    # subprogram access identification - initial value is error value:
    $accessor_object{accessor_id} = 0xFFFFFFFF;
    # initialise the important control block values of the accessor object:
    $accessor_object{return_code} = 0;
    $accessor_object{plam_message} = 0;
    $accessor_object{lms_message} = 0;
    $accessor_object{dms_message} = 0;
    $accessor_object{lms_version} = '???';

    # now call the library function via XS module:
    my $rc = lms_init(\%accessor_object);
    die 'LMS init failded (internal error?)' unless defined $rc;
    croak 'LMS init failed (', message(\%accessor_object), ')'
	if $rc == 0xFFFFFFFF;
    $accessor_object{accessor_id} = $rc;

    # now we're finished:
    bless \%accessor_object, $class;
}
sub DESTROY
{
    my $this = shift;
    my $rc = lms_end($this);
    die 'LMS end failded (internal error?)' unless defined $rc;
    croak 'LMS end failed (', $this->message(), ')'
	unless $rc == 0;
}

#########################################################################

=head2 B<message> - return string containing the last messages set

    $last_message = $accessor_object->message();

Example:

    warn $library->message();

This method returns a string with the message codes of the last call
to the LMS subprogram library.	Only message codes different from 0
are included.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub message
{
    my ($this) = @_;
    local $_;

    my $message_string = '';
    foreach ('plam', 'lms', 'dms')
    {
	my $key = $_.'_message';
	$message_string .=
	    sprintf("%s message code %s%04d, ",
		    uc($_), substr(uc($_), 0, 3), $this->{$key})
		if $this->{$key};
    }
    chop $message_string; chop $message_string;
    return $message_string;
}

#########################################################################

=head2 B<rc_message> - return string with last return code / messages

    $last_message = $accessor_object->rc_message();

Example:

    warn $library->rc_message();

This method returns a string with the return code and the message
codes of the last call to the LMS subprogram library.  Only message
codes different from 0 are included.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub rc_message
{
    my ($this) = @_;
    local $_;

    my $message_string = $this->message();
    return 'RC '.$this->{return_code}.
	( $message_string ? ', '.$message_string : '' );
}

#########################################################################

=head2 B<list> - return array of library elements (table of contents)

    @toc = $accessor_object->list(%selection_hash);

Example:

    @toc = $library->list(type => 'S', name => 'CSTD*');
    print $_->{type}, ' ', $_->{name}, "\n" foreach (@toc);

This method returns an array of elements of the table of contents of
the library (or an C<undef> in case of errors).  Each element in this
array is a reference to a hash holding an attribute of the library
element (see below).  The optional parameters of the method are used
to select specific elements of the whole table of contents.  They are:

=over

=item I<type>

to select a specific type of library element, e.g. C<'S'> for source
elements

=item I<name>

to select elements with a specific name

=item I<version>

to select elements with a specific version, use C<'~'> for latest???

=item I<user_date>

to select elements with a specific date set by some user.  You may use:

=over

=item

a single date using the format C<YYYY-MM-DD*> with C</> (single
character) or C<*> (any characters) as wildcards anywhere in the
string

=item

a range using C<< <YYYY-MM-DD:YYYY-MM-DD>* >>

=back

Note that you must add the trailing C<*> as a julian day may follow
the "normal" date.

=item I<user_time>

to select elements with a specific time set by some user.  You may use
C</> and C<*> as wildcards but I<you can't use a C<:> anywhere in this
string>!  In addition you may use an hourly range of C<< <HH:HH>* >>.

=item I<creation_date>

to select elements with a specific creation date (see user_date for
details of the format)

=item I<creation_time>

to select elements with a specific creation time (see user_time for
details of the format)

=item I<modification_date>

to select elements with a specific modification date (see user_date for
details of the format)

=item I<modification_time>

to select elements with a specific modification time (see user_time
for details of the format)

=item I<access_date>

to select elements with a specific access date (see user_date for
details of the format)

=item I<access_time>

to select elements with a specific access time (see user_time for
details of the format)

=item I<mode_set>

to select elements with a specific (unix like) protection mode (this
is translated into the various BS2000 protection flags).  Only set
bits are checked, the protection for unset bits is ignored.

=item I<mode_unset>

to select elements with a specific (unix like) protection mode (this
is translated into the various BS2000 protection flags).  This is the
inverse of C<mode_set>.  Only unset bits are checked, the protection
for set bits is ignored.

Example:

If you want to select elements which may be read, but not executed by
members of the user group, you would write:

$library->list(mode_set => 040, mode_unset => 010);

If both C<mode_set> and C<mode_unset> refer to a specific bit,
C<mode_unset> is used.

NOTE: Both C<mode_set> and C<mode_unset> only work, if protection
flags are actually used for an element.  Otherwise the element is
I<always> selected!

=item I<hold_state>

to select elements with a specific hold state (C<'-'> for free, C<'H'>
for held)

=item I<min_element_size>

to select elements with a specific minimal element size (in PAM pages
= 2K)

=item I<max_element_size>

to select elements with a specific maximal element size (in PAM pages
= 2K)

=item I<from_index>

shorten the result to a sublist starting with this index

=item I<to_index>

shorten the result to a sublist ending with this index

=back

In all selection strings C</> (single character) and C<*> (any string
including an empty one) may be used as wildcards, unless specified
otherwise.

A library element in the result (a reference to a hash) is described
by the following attributes (each attribute is a key of the hash):

=over

=item I<type>

the type of the library element, e.g. C<'S'> for source elements

=item I<name>

the (main) name of the element

=item I<version>

the version number of the element (An element may be included in a
library more than once with different version numbers!)

=item I<storage_form>

the storage form of the element, that is C<LMSUP_DELTA> (C<'D'>) for a
delta and C<LMSUP_FULL> ('C<V'>) (german 'voll') for an element stored
as it is

=item I<secondary_name>

a secondary reference name for the element

=item I<secondary_attribute>

a secondary ??? name for the element???

=item I<user_date>

a specific date set for this element by some user of the form
YYYY-MM-DDjjj (jjj is the optional julian day of the year)

=item I<user_time>

a specific time set for this element by some user of the form HH:MM:SS

=item I<creation_date>

the creation date of an element (see user_date for details of the
format)

=item I<creation_time>

the creation time of an element

=item I<modification_date>

the date of the last modification of an element (see user_date for
details of the format)

=item I<modification_time>

the time of the last modification of an element

=item I<access_date>

the date of the last access to an element (see user_date for details
of the format)

=item I<access_time>

the time of the last access to an element

=item I<mode>

the (unix like) protection mode of the element (this is translated
from the various BS2000 protection flags)

=item I<hold_state>

the hold state of the element (C<LMSUP_FREE> respective C<'-'> for
free and C<LMSUP_INHOLD> respective C<'H'> for held)

=item I<holder>

the user ID of the holder (only valid if hold_state is held)

=item I<element_size>

the size of the element in PAM pages of 2 KB

=back

ToDo: Parameter-Checks???

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub list
{
    my $this = shift;
    my %args = @_;
    my $ra_toc = lms_list($this, \%args);
    defined $ra_toc  or  return undef;
    die 'result is not a reference to an array (internal error? ',
	$this->rc_message(), ')'
	    unless 'ARRAY' eq ref($ra_toc);
    return @$ra_toc;
}

#########################################################################

=head2 B<add> - add an element to the library

    $bytes_added = $accessor_object->add($input_file, %element_info);

Example:

    $timestamp = localtime
    $library->add("myinclude.h", type => 'S', name => 'myinclude.h',
		  user_date => strftime("%Y-%m-%d", $timestamp),
		  user_time => strftime("%H:%M:%S", $timestamp))
        or  die 'error adding myinclude.h: ', $library->rc_message();
    $library->add(["<:encoding(ascii)", "somefile.asc"],
		  type => 'S', name => 'somefile')
        or  die 'error adding somefile.asc: ', $library->rc_message();

This method adds an element to the library.  The element may be an
existing element (which gets a new version) or a new one.  $input_file
may be a reference to a list which is then passed unmodified to the
normal Perl open function.  So (starting with Perl 5.8) any PerlIO
attribute may be used to convert from a specific character set.
Regardless, writing is always done using raw binary IO.  This means
that library elements are always in written in EBCDIC.  The following
attributes may be set for the element (the first two attributes are
mandatory):

=over

=item I<type>

the type of the element, e.g. C<'S'> for a source element (mandatory)

=item I<name>

the name of the element (mandatory)

=item I<version>

the version of the element

=item I<user_date>

the non-system-set-date for the element.  The valid format is
YYYY-MM-DD or the string "now" (localtime, this also sets
I<user_time>).

=item I<user_time>

the non-system-set-time for the element.  Valid formats are HH:MM:SS,
HH:MM or the string "now" (localtime, this also sets I<user_date>).

=back

The method returns the number of bytes written or -1 in case of
errors.  Note that newlines are counted even though they are not
really written (each line is a record), so you should get the size of
the original file.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub add
{
    my $this = shift;
    my $filename = shift;
    my %args = @_;
    local $_;

    # check parameters 1:
    defined $args{name}  or  croak "element name not defined";
    defined $args{type}  or  croak "element type not defined";
    $args{version} = '*HIGH' unless defined $args{version};
    # handle 'now':
    if ((defined $args{user_date}  and  $args{user_date} eq 'now')  or
	(defined $args{user_time}  and  $args{user_time} eq 'now'))
    {
	my $timestamp = localtime;
	$args{user_date} = strftime("%Y-%m-%d", $timestamp);
	$args{user_time} = strftime("%H:%M:%S", $timestamp);
    }
    # check parameters 2:
    croak 'invalid date', $args{user_date}
	if (defined $args{user_date}  and
	    $args{user_date}
	    !~ m/^\d{4}-(?:0[13578]|1[02])-(?:0[1-9]|[12]\d|3[01])$/  and
	    $args{user_date}
	    !~ m/^\d{4}-(?:0[469]|11)-(?:0[1-9]|[12]\d|30)$/  and
	    $args{user_date} !~ m/^\d{4}-02-(?:0[1-9]|[12]\d)$/);
    croak 'invalid time', $args{user_time}
	if  defined $args{user_time}  and
	    $args{user_time} !~ m/^(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?$/;
    # open output and input:
    my @input_file;
    if (ref($filename) eq '')
    {
	die 'LMS add failded (internal error?)'
	    unless $filename =~ m/^(?:>\s*)?(.*)$/;
	@input_file = ('<', $1);
    }
    elsif (ref($filename) eq 'ARRAY')
    { @input_file = @$filename; }
    else
    { croak '1st parameter of LMS::add neither scalar nor array!'; }
    open INPUT, $input_file[0], $input_file[1]  or
	croak "Can't open '", $input_file[-1], "' as input: $!";
    my $record_access_id = lms_open_put($this, \%args);
    defined $record_access_id  or
	croak "Can't open element ", $args{name}, ',', $args{type}, ': ',
	    $this->message();
    return -1 unless $this->{return_code} == LMSUP_OK;
    # read and write each record:
    my $bytes_written = 0;
    while (<INPUT>)
    {
	chomp;
	my $record_length = lms_write($this, $record_access_id, $_);
	die 'LMS put failded (internal error?)'
	    unless defined $record_length  and  $record_length > 0;
	$this->{return_code} == LMSUP_OK  or
	    croak "Error writing ", $args{name}, ',', $args{type}, ': ',
		$this->message();
	$bytes_written += $record_length + 1;
    }
    # close input and output, return size:
    close INPUT  or  croak "Can't close '", $filename, "': $!";
    lms_close($this, $record_access_id, 1)  or
	croak "Can't close element ", $args{name}, ',', $args{type}, ': ',
	    $this->message();
    return -1 unless $this->{return_code} == LMSUP_OK;
    return $bytes_written;
}

#########################################################################

=head2 B<extract> - extract an element from the library

    $bytes_extracted = $accessor_object->extract($output_file,
						 %element_descriptor);

Example:

    $timestamp = localtime
    $library->extract("myinclude.h", type => 'S', name => 'myinclude.h')
        or  die 'error extracting myinclude.h: ', $library->rc_message();
    $library->extract(["<:encoding(ascii)", "somefile.asc"],
		      type => 'S', name => 'somefile')
        or  die 'error extracting somefile.asc: ', $library->rc_message();

This method extracts an element from the library.  $output_file may be
a reference to a list which is then passed unmodified to the normal
Perl open function.  So (starting with Perl 5.8) any PerlIO attribute
may be used to convert to a specific character set.  Reading is always
done using raw binary IO though.  The following attributes are used to
specify the element:

=over

=item I<type>

the type of the element, e.g. C<'S'> for a source element

=item I<name>

the name of the element

=item I<version>

the version of the element (this is an optional attribute, the default
is C<'*HIGH'> for the newest version)

=back

The method returns the size of the element read or -1 in case of
errors.

NOTE: Only elements with normal records (up to 32 KB - 4 bytes) may be
extracted, elements with I<B-records> can not be extracted (yet?).

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub extract
{
    my $this = shift;
    my $filename = shift;
    my %args = @_;
    local $_;

    # check parameters:
    defined $args{name}  or  croak "element name not defined";
    defined $args{type}  or  croak "element type not defined";
    $args{version} = '*HIGH' unless defined $args{version};
    # open output and input:
    my @output_file;
    if (ref($filename) eq '')
    {
	die 'LMS extract failded (internal error?)'
	    unless $filename =~ m/^(?:>\s*)?(.*)$/;
	@output_file = ('>', $1);
    }
    elsif (ref($filename) eq 'ARRAY')
    { @output_file = @$filename; }
    else
    { croak '1st parameter of LMS::add neither scalar nor array!'; }
    open OUTPUT, $output_file[0], $output_file[1]  or
	croak "Can't open '", $output_file[-1], "' as output: $!";
    my $record_access_id = lms_open_get($this, \%args);
    defined $record_access_id  or
	croak "Can't open element ", $args{name}, ',', $args{type}, ': ',
	    $this->message();
    return -1 unless $this->{return_code} == LMSUP_OK;
    # read and write each record:
    my $bytes_read = 0;
    my $content = '';
    while (1)
    {
	my $record_length = lms_read($this, $record_access_id, \$content);
	die 'LMS get failded (internal error?)' unless defined $record_length;
	last if $record_length < 0  or  $this->{return_code} == LMSUP_EOF;
	$this->{return_code} == LMSUP_OK  or
	    croak "Error reading ", $args{name}, ',', $args{type}, ': ',
		$this->message();
	print OUTPUT $content, "\n";
	$bytes_read += $record_length + 1;
    }
    # close output and input, return size:
    close OUTPUT  or  croak "Can't close '", $filename, "': $!";
    lms_close($this, $record_access_id)  or
	croak "Can't close element ", $args{name}, ',', $args{type}, ': ',
	    $this->message();
    return -1 unless $this->{return_code} == LMSUP_OK;
    return $bytes_read;
}

#########################################################################
#########################################################################
#########	internal methods / functions following		#########
#########################################################################
#########################################################################

# none yet
#########################################################################
# call:									#
#	function($param_1, $param_2);					#
# parameters:								#
#	$param_1	parameter 1					#
#	$param_2	parameter 2					#
# description:								#
#	This function/method ...					#
# global variables used:						#
#	-								#
# returns:								#
#	-								#
#########################################################################

#########################################################################
#########################################################################
#########	final initialisations and self checks		#########
#########################################################################
#########################################################################

lms_assertions();
1;

__END__

=head1 KNOWN BUGS

The functionality is still limited to a few methods.

=head1 SEE ALSO

the Fujitsu-Siemens documentation B<Library Management System,
Subroutine Interface> (LMS_UPS.PDF, search on
http://www.fujitsu-siemens.com)

=head1 AUTHOR

Thomas Dorner E<lt>Thomas.Dorner@start.deE<gt> or E<lt>Thomas.Dorner@gmx.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Thomas Dorner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
