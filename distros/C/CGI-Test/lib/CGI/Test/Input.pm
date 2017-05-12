#####################################################################
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#

#
# Abstract representation of the POST input data, which is a list of incoming
# parameters that can be encoded differently.
#

package CGI::Test::Input;

use strict;
use warnings;
no  warnings 'uninitialized';

use Carp;

############################################################
#
# ->new
#
# Creation routine
#
############################################################
sub new
{
    confess "deferred";
}

############################################################
#
# ->_init
#
# Initialization of common attributes
#
############################################################
sub _init
{
    my $this = shift;
    $this->{stale}  = 0;
    $this->{fields} = [];    # list of [name, value]
    $this->{files}  = [];    # list of [name, value, content or undef]
    $this->{length} = 0;
    $this->{data}   = '';
    return;
}

#
# Attribute access
#

############################################################
sub _stale
{
    my $this = shift;
    $this->{stale};
}
############################################################
sub _fields
{
    my $this = shift;
    $this->{fields};
}
############################################################
sub _files
{
    my $this = shift;
    $this->{files};
}
############################################################
sub length
{
    my $this = shift;
    $this->_refresh() if $this->_stale();
    $this->{length};
}
############################################################
sub data
{
    my $this = shift;
    $this->_refresh() if $this->_stale();
    $this->{data};
}

############################################################
#
# ->set_raw_data
#
# Set raw POST data for this input object
#
############################################################
sub set_raw_data {
    my ($this, $data) = @_;

    $this->{data}   = $data;
    $this->{length} = do { use bytes; CORE::length $data };
    $this->{stale}  = 0;

    return $this;
}

############################################################
#
# ->add_widget
#
# Add new input widget.
#
# This routine is called to build input data for POST requests issued in
# response to a submit button being pressed.
#
############################################################
sub add_widget
{
    my $this = shift;
    my ($w) = @_;

    #
    # Appart from the fact that file widgets get inserted in a dedicated list,
    # the processing here is the same.  The 3rd value of the entry for files
    # will be undefined, meaning the file will be read at a later time, when
    # the input data is built.
    #

    my @tuples = $w->submit_tuples;
    my $array  = $w->is_file ? $this->_files : $this->_fields;

    while (my ($name, $value) = splice @tuples, 0, 2)
    {
        $value = '' unless defined $value;
        push @$array, [ $name, $value ];
    }

    $this->{stale} = 1;

    return;
}

############################################################
#
# ->add_field
#
# Add a new name/value pair to the input data.
#
# This routine is meant for manual input data building.
#
############################################################
sub add_field
{
    my $this = shift;
    my ($name, $value) = @_;

    $value = '' unless defined $value;
    push @{$this->_fields}, [ $name, $value ];
    $this->{stale} = 1;

    return;
}

############################################################
#
# ->add_file
#
# Add a new upload-file information to the input data.
# The actual reading of the file is deferred up to the moment where we
# need to build the input data.
#
# This routine is meant for manual input data building.
#
############################################################
sub add_file
{
    my $this = shift;
    my ($name, $value) = @_;

    $value = '' unless defined $value;
    push @{$this->_files}, [ $name, $value ];
    $this->{stale} = 1;

    return;
}

############################################################
#
# ->add_file_now
#
# Add a new upload-file information to the input data.
# The file is read immediately, and can be disposed of once we return.
#
# This routine is meant for manual input data building.
#
############################################################
sub add_file_now
{
    my $this = shift;
    my ($name, $value) = @_;

    croak "unreadable file '$value'" unless -r $value;

    local *FILE;
    open(FILE, $value);
    binmode FILE;

    local $_;
    my $content = '';

    while (<FILE>)
    {
        $content .= $_;
    }
    close FILE;

    push @{$this->_files}, [ $name, $value, $content ];
    $this->{stale} = 1;

    return;
}

sub set_mime_type {
    my ($this, $type) = @_;

    $this->{mime_type} = $type;

    return $this;
}

#
# Interface to be implemented by heirs
#

############################################################
sub mime_type
{
    my ($this) = @_;

    my $type = $this->{mime_type};

    confess "deferred" unless $type;

    return $type;
}

############################################################
sub _build_data
{
    confess "deferred";
}

#
# Internal routines
#

############################################################
#
# ->_refresh
#
# Recomputes `data' and `length' attributes when stale
#
############################################################
sub _refresh
{
    my $this = shift;

    # internal pre-condition

    my $data = $this->_build_data;    # deferred

    $this->{data}   = $data;
    $this->{length} = CORE::length $data;
    $this->{stale}  = 0;

    return;
}

1;

=head1 NAME

CGI::Test::Input - Abstract representation of POST input

=head1 SYNOPSIS

 # Deferred class, only heirs can be created
 # $input holds a CGI::Test::Input object

 $input->add_widget($w);                     # done internally for you

 $input->add_field("name", "value");         # manual input construction
 $input->add_file("name", "path");           # deferred reading
 $input->add_file_now("name", "/tmp/path");  # read file immediately

 syswrite INPUT, $input->data, $input->length;   # if you really have to

 # $test is a CGI::Test object
 $test->POST("http://server:70/cgi-bin/script", $input);

=head1 DESCRIPTION

The C<CGI::Test::Input> class is deferred.  It is an abstract representation
of HTTP POST request input, as expected by the C<POST> routine of C<CGI::Test>.

Unless you wish to issue a C<POST> request manually to provide carefully
crafted input, you do not need to learn the interface of this hierarchy,
nor even bother knowing about it.

Otherwise, you need to decide which MIME encoding you want, and create an
object of the appropriate type.  Note that file uploading requires the use
of the C<multipart/form-data> encoding:

           MIME Encoding                    Type to Create
 ---------------------------------   ---------------------------
 application/x-www-form-urlencoded   CGI::Test::Input::URL
 multipart/form-data                 CGI::Test::Input::Multipart

Once the object is created, you will be able to add name/value tuples
corresponding to the CGI parameters to submit.

For instance:

    my $input = CGI::Test::Input::Multipart->new();
    $input->add_field("login", "ram");
    $input->add_field("password", "foobar");
    $input->add_file("organization", "/etc/news/organization");

Then, to inspect what is normally sent to the HTTP server:

    print "Content-Type: ", $input->mime_type, "\015\012";
    print "Content-Length: ", $input->length, "\015\012";
    print "\015\012";
    print $input->data;

But usually you'll hand out the $input object to the C<POST> routine
of C<CGI::Test>.

=head1 INTERFACE

=head2 Creation Routine

It is called C<new> as usual.  All subclasses have
the same creation routine signature, which takes no parameter.

=head2 Adding Parameters

CGI parameter are name/value tuples.  In case of file uploads, they can have
a content as well, the value being the file path on the client machine.

=over 4

=item C<add_field> I<name>, I<value>

Adds the CGI parameter I<name>, whose value is I<value>.

=item add_file I<name>, I<path>

Adds the file upload parameter I<name>, located at I<path>.

The file is not read immediately, so it must remain available until
the I<data> routine is called, at least.  It is not an error if the file
cannot be read at that time.

When not using the C<multipart/form-data> encoding, only the name/path
tuple will be transmitted to the script.

=item add_file_now I<name>, I<path>

Same as C<add_file>, but the file is immediately read and can therefore
be disposed of afterwards.  However, the file B<must> exist.

=item add_widget I<widget>

Add any widget, i.e. a C<CGI::Test::Form::Widget> object.  This routine
is called internally by C<CGI::Test> to construct the input data when
submiting a form via POST.

=back

=head2 Generation

=over 4

=item C<data>

Returns the data, under the proper encoding.

=item C<mime_type>

Returns the proper MIME encoding type, suitable for inclusion within
a Content-Type header.

=item C<length>

Returns the data length.

=back

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test(3), CGI::Test::Input::URL(3), CGI::Test::Input::Multipart(3).

=cut

