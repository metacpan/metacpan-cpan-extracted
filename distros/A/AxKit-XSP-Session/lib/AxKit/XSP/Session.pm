
package AxKit::XSP::Session;
use strict;
use Apache::AxKit::Language::XSP;
use Apache::Session;
use Date::Format;
use Apache;
use Carp;

use vars qw/@ISA $NS $VERSION $SESSION/;

@ISA = ('Apache::AxKit::Language::XSP');
$NS = 'http://www.apache.org/1999/XSP/Session';

$VERSION = "0.11";

## Taglib subs

sub get_attribute
{
    my ( $attribute ) = @_;
    $attribute =~ s/^\s*//;
    $attribute =~ s/\s*$//;
    my $r = Apache->request;
    my $session = $r->pnotes('xsp_session');
    return $session->{$attribute};
}

sub get_attribute_names
{
    my $r = Apache->request;
    my $session = $r->pnotes('xsp_session');
    return keys(%$session);
}

sub get_id
{
    my $r = Apache->request;
    my $session = $r->pnotes('xsp_session');
    return $session->{_session_id};
}

# I've changed the API for this particular tag.  The Cocoon XSP definition for get-creation-time
# really stinks.  The default first of all, is "long", which is basically number of seconds since
# epoch.  It also has support for "node" output, which basically is the same as "long", except it
# outputs the value in a hard-coded XML tag.  If there's any merit to the node output, someone
# please tell me; otherwise, I'll leave it out.
sub get_creation_time
{
    my ( $as ) = @_;
    my $r = Apache->request;
    my $session = $r->pnotes('xsp_session');
    return _get_time( $as, $session->{_creation_time} );
}

# Ahh, the wonders of "Copy-Paste(tm)" technology!  Since it's late at night, and this
# XSP taglib is just a means-to-an-end for me, I'm just copying the 'get_creation_time'
# subroutine.  If anyone feels so inclined, you're welcome to clean this up. :)
sub get_last_accessed_time
{
    my ( $as ) = @_;
    my $r = Apache->request;
    # This isn't necessary anymore
    # TODO update the documentation to reflect this
    #return undef unless ( $r->dir_config( 'UseSessionAccessTimestamp' ) =~ /on/i );

    my $session = $r->pnotes('xsp_session');
    return _get_time( $as, $session->{_last_accessed_time} );
}

sub _get_time
{
    my ( $as, $time ) = @_;
    $as = 'string' unless ( $as );
    my $formatted_time = undef;
    if ( $as eq 'long' )
    {
        return $time;
    }
    elsif ( $as eq 'string' )
    {
        # Outputs a string like "Wed Jun 13 15:57:06 EDT 2001"
        return time2str('%a %b %d %H:%M:%S %Z %Y', $time);
    }
}

sub set_attribute
{
    my ( $attribute, $value ) = @_;
    $attribute =~ s/^\s*//;
    $attribute =~ s/\s*$//;
    $value =~ s/^\s*//;
    $value =~ s/\s*$//;
    # exit out if they try to set any magic keys
    return if ( $attribute =~ /^_/ );
    #print STDERR "set-attribute: \$attribute=\"$attribute\", \$value=\"$value\".\n";

    my $r = Apache->request;
    my $session = $r->pnotes('xsp_session');
    $session->{$attribute} = $value;
    return;
}

sub remove_attribute
{
    my ( $attribute ) = @_;
    $attribute =~ s/^\s*//;
    $attribute =~ s/\s*$//;
    # exit out if they try to set any magic keys
    return if ( $attribute =~ /^_/ );
    #print STDERR "remove-attribute: \$attribute=\"$attribute\".\n";

    my $r = Apache->request;
    my $session = $r->pnotes('xsp_session');
    delete $session->{$attribute};
    #print STDERR "remove-attribute: value=\"" . $session->{$attribute} . "\".\n";
    return;
}

sub invalidate
{
    my $r = Apache->request;
    my $session_obj = $r->pnotes('xsp_session_ref');
    $session_obj->delete;
    return;
}

## Parser subs

sub parse_start {
    my ($e, $tag, %attribs) = @_; 
    #warn "Checking: $tag\n";

    if ($tag eq 'get-attribute') 
    {
        my $code = '{ my ($name);';
        if ( $attribs{name} )
        {
            $code .= '$name = q|' . $attribs{name} . '|;';
        }
        return $code;
    }

    elsif ($tag eq 'name')
    {
        return '$name = ""';
    }

    elsif ($tag eq 'value')
    {
        return '$value = ""';
    }

    elsif ($tag eq 'get-id')
    {
        return q|{ AxKit::XSP::Session::get_id(); }|;
    }

    elsif ($tag eq 'get-creation-time')
    {
        my $code = '{ my $as = ';
        if ( defined( $attribs{as} ) )
        {
            $code .= 'q|' . $attribs{as} . '|;';
        }
        else
        {
            $code .= 'undef;';
        }
        $code .= ' AxKit::XSP::Session::get_creation_time( $as ); }';
    }

    elsif ($tag eq 'get-last-accessed-time')
    {
        my $code = '{ my $as = ';
        if ( defined( $attribs{as} ) )
        {
            $code .= 'q|' . $attribs{as} . '|;';
        }
        else
        {
            $code .= 'undef;';
        }
        $code .= ' AxKit::XSP::Session::get_last_accessed_time( $as ); }';
    }

    elsif ($tag eq 'invalidate')
    {
        return q|{ AxKit::XSP::Session::invalidate(); }|;
    }

    elsif ($tag eq 'remove-attribute')
    {
        my $code = '{ my ($name);';
        if ( $attribs{name} )
        {
            $code .= '$name = q|' . $attribs{name} . '|;';
        }
        return $code;
    }

    elsif ($tag eq 'set-attribute')
    {
        my $code = '{ my ($name, $value);';
        if ( $attribs{name} )
        {
            $code .= '$name = q|' . $attribs{name} . '|;';
        }
        if ( $attribs{value} )
        {
            $code .= '$value = q|' . $attribs{value} . '|;';
        }
        return $code;
    }

    else {
        die "Unknown session tag: $tag";
    }
}

sub parse_char {
    my ($e, $text) = @_;
    return '' unless $text =~ /\S/;

    $text =~ s/\|/\\\|/g;
    $text =~ s/\\$/\\\\/gsm;
    return " . q|$text| ";
}

sub parse_end {
    my ($e, $tag) = @_;

    if ($tag =~ /name|value/)
    {
        return ';';
    }

    elsif ($tag eq 'get-attribute')
    {
        return 'AxKit::XSP::Session::get_attribute($name);}' . "\n";
    }

    elsif ($tag eq 'remove-attribute')
    {
        return 'AxKit::XSP::Session::remove_attribute($name);}' . "\n";
    }

    elsif ($tag eq 'set-attribute')
    {
        return 'AxKit::XSP::Session::set_attribute($name, $value);}' . "\n";
    }

    return ";";
}

sub parse_comment {
    # compat only
}

sub parse_final {
   # compat only
}

1;
                
__END__

=head1 NAME

AxKit::XSP::Session - Session wrapper tag library for AxKit eXtesible Server Pages.

=head1 SYNOPSIS

Add the session: namespace to your XSP C<<xsp:page>> tag:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:session="http://www.apache.org/1999/XSP/Session"
    >

And add this taglib to AxKit (via httpd.conf or .htaccess):

    AxAddXSPTaglib AxKit::XSP::Session

=head1 DESCRIPTION

The XSP session: taglib provides basic session object operations to
XSP, using the Cocoon2 Session taglib specification.  I tried to stay
as close to the Cocoon2 specification as possible, for compatibility
reasons.  However, there are some tags that either didn't make sense to
implement, or I augmented since I was there.

Keep in mind, that currently this taglib does not actually create or
fetch your session for you.  That has to happen outside this taglib.
This module relies on the $r->pnotes() table for passing the session
object around.

Special thanks go out to Kip Hampton for creating AxKit::XSP::Sendmail, from
which I created AxKit::XSP::Session.

=head1 Tag Reference

=head2 C<<session:get-attribute>>

This is the most used tag.  It accepts either an attribute or child node
called 'name'.  The value passed in 'name' is used as the key to retrieve
data from the session object.

=head2 C<<session:set-attribute>>

Similar to :get-attribute, this tag will set an attribute.  It accepts an
additional parameter (as an attribute or child node) called 'value'.  You
can intermix attribute and child nodes for either parameter, so its pretty
flexible.  NOTE: this is different from Cocoon2, where the value is a child
text node only.

=head2 C<<session:get-id>>

Gets the SessionID used for the current session.  This value is read-only.

=head2 C<<session:get-creation-time>>

Returns the time the current session was created.  Cocoon2's way of handling
this is pretty wierd, so I didn't implement it 100% to spec.  This tag takes
an optional parameter of 'as', which allows you to choose your date format.
Your only options are "string" and "long", where the string output is a human-readable
string representation (e.g. "Fri Nov 23 15:38:13 PST 2001").  "long", contrary
to what you would expect, is the number of seconds since epoch.  The Cocoon2 spec
makes "long" the default, while mine specifies "string" as default.

=head2 C<<session:get-last-accessed-time>>

Similar to :get-creation-time, except it returns the time since this session
was last accessed (duh).

=head2 C<<session:remove-attribute>>

Removes an attribute from the session object.  Accepts either an attribute or
child node called 'name' which indicates which session attribute to remove.

=head2 C<<session:invalidate>>

Invalidates, or permanently removes, the current session from the datastore.
Not all Apache::Session implementations support this, but it works just beautifully
under Apache::Session::File (which is what I used for my testing).

=head1 Unsupported Tags

The following is a list of Cocoon2 Session taglib tags that I do not support
in this implementation.

=head2 C<<session:is-new>>

The Cocoon2 documentation describes this as "Indicates whether this session was just created."
This parameter is a part of the J2SE Servlet specification, but is not provided
AFAIK by Apache::Session.  To implement this would involve putting in some
strange "magic" value in the session object, and that didn't sit well with me.
I'll probably implement this in the next version however.

=head2 C<<session:get-creation-time>>, C<<session:get-last-accessed-time>>

I don't support the "node" "as" attribute type, which is supposed to output something
similar to this:

    <session:creation-time>1006558479</session:creation-time>

=head2 C<<session:get-max-inactive-interval>>, C<<session:set-max-inactive-interval>>

This is described in Cocoon2 as:

  Gets the minimum time, in seconds, that the server will maintain this session between client requests.

I am not aware of any built-in Apache::Session support for this, but it could be
usefull to implement this in the future.

=head2 C<<xsp:page>>

Under the Cocoon2 taglib, you can enable support for automatically creating sessions
on-demand by putting 'create-session="true"' in the <xsp:page> node, like:

  <xsp:page language="Perl" xmlns:xsp="http://apache.org/xsp/core/v1"
    xmlns:session="http://www.apache.org/1999/XSP/Session"
    create-session="true">

This would be B<<really>> neat to have support for, but I couldn't figure out
how to do this in AxKit.  Maybe the next release?

=head1 EXAMPLE

  <session:invalidate/>
  SessionID: <xsp:expr><session:get-id/></xsp:expr>
  Creation Time: <xsp:expr><session:get-creation-time/></xsp:expr>
    (Unix Epoch) <xsp:expr><session:get-creation-time as="long"/></xsp:expr>
  <session:set-attribute name="foo" value="bar"/>
  <session:set-attribute name="baz">
    <session:value>boo</session:value>
  </session:set-attribute>
  <session:set-attribute>
    <session:name>baa</session:name>
    <session:value>bob</session:value>
  </session:set-attribute>
  <session:remove-attribute name="foo"/>

=head1 ERRORS

To tell you the truth, I haven't tested this enough to know what happens when it fails.
I'll update this if any glaring problems are found.

=head1 AUTHOR

Michael A Nachbaur, mike@nachbaur.com

=head1 COPYRIGHT

Copyright (c) 2001 Michael A Nachbaur. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

AxKit, Apache::Session, Cocoon2 Session Taglib (http://xml.apache.org/cocoon2/userdocs/xsp/session.html)

=cut
