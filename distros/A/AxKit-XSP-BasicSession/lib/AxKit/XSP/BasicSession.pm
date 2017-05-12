package AxKit::XSP::BasicSession;
# $Id: BasicSession.pm,v 1.12 2004/09/16 23:20:46 nachbaur Exp $

use Apache;
use Apache::AxKit::Language::XSP::TaglibHelper;
use Apache::Session;
use Date::Format;
sub parse_char  { Apache::AxKit::Language::XSP::TaglibHelper::parse_char(@_); }
sub parse_start { Apache::AxKit::Language::XSP::TaglibHelper::parse_start(@_); }
sub parse_end   { Apache::AxKit::Language::XSP::TaglibHelper::parse_end(@_); }

@EXPORT_TAGLIB = (
    'get_attribute($name)',
    'set_attribute($name,$value)',
    'remove_attribute($name)',
    'get_id()',
    'get_creation_time(;$as,$format)',
    'get_last_accessed_time(;$as,$format)',
    'invalidate()',
    'is_new()',
    'if($name;$value):conditional=1:isreally=ifkey',
    'unless($name;$value):conditional=1:isreally=unlesskey',
    'if_regex($name,$value):conditional=1',
    'unless_regex($name,$value):conditional=1',
    'if_exists($name):conditional=1',
    'unless_exists($name):conditional=1',
    'enumerate():listtag=session-keys=key=1',
    'exists($name):isreally=keyexists',
    'count()',
);

@ISA = qw(Apache::AxKit::Language::XSP::TaglibHelper);
$NS = 'http://www.axkit.org/2002/XSP/BasicSession';
$VERSION = "0.22";

use strict;

## Constructor used from within providers, or raw-perl code.  This is mainly
# intended for code writers who want to access these methods from within perl
# code, but don't want to use the full package name prefixed to the method calls.
sub new
{
    my $pkg = shift;
    my $class = ref($pkg) || $pkg;
    my $self = {};
    return bless $self, $class;
}

# This private function is used by other methods in this class to determine
# if the method in question is being called as a method from within user-
# constructed perl code, or from an XSP taglib.  If called from perl code,
# and the method is invoked as $obj->methodName(), the $self object must
# be shifted off the argument list.
sub _calledAsMethod
{
    my $arg = shift;
    if (ref($arg) and UNIVERSAL::isa($arg, 'AxKit::XSP::BasicSession')) {
        return 1;
    } else {
        return 0;
    }
}

## Taglib subs

sub get_attribute
{
    my $self = shift if (_calledAsMethod(@_));
    my ( $attribute ) = @_;
    #
    # Trim unnecessary whitespace
    $attribute =~ s/^\s*//;
    $attribute =~ s/\s*$//;

    #
    # Throw the session key's value back at the user
    return $Apache::AxKit::Plugin::BasicSession::session{$attribute};
}

sub get_id
{
    my $self = shift if (_calledAsMethod(@_));
    #
    # Hurl the Session ID to the user
    return $Apache::AxKit::Plugin::BasicSession::session{_session_id};
}

# I've changed the API for this particular tag.  The Cocoon XSP definition for get-creation-time
# really stinks.  The default first of all, is "long", which is basically number of seconds since
# epoch.  It also has support for "node" output, which basically is the same as "long", except it
# outputs the value in a hard-coded XML tag.  If there's any merit to the node output, someone
# please tell me; otherwise, I'll leave it out.
sub get_creation_time
{
    my $self = shift if (_calledAsMethod(@_));
    my ( $as, $format ) = @_;
    return _get_time( $as, $Apache::AxKit::Plugin::BasicSession::session{_creation_time}, $format );
}

sub get_last_accessed_time
{
    my $self = shift if (_calledAsMethod(@_));
    my ( $as, $format ) = @_;
    return _get_time( $as, $Apache::AxKit::Plugin::BasicSession::session{_last_accessed_time}, $format );
}

#
# This function takes in the time, how it needs to be displayed,
# and optionally a format to display it with (not in that order).
# This is a generic routine used by the get_*_time functions.
sub _get_time
{
    my $self = shift if (_calledAsMethod(@_));
    my ( $as, $time, $format ) = @_;
    #
    # Default to "string", since thats how most people will want it
    $as = 'string' unless ( $as );

    #
    # Return the time as-is if they want the long format
    if ( $as eq 'long' )
    {
        return $time;
    }
    
    #
    # Return the string format
    elsif ( $as eq 'string' )
    {
        #
        # Defaults to a string like "Wed Jun 13 15:57:06 EDT 2001"
        my $str_format = $format || '%a %b %d %H:%M:%S %Z %Y';
        return time2str($str_format, $time);
    }
}

# Sets an attribute into the given session.
sub set_attribute
{
    my $self = shift if (_calledAsMethod(@_));
    my ( $attribute, $value ) = @_;
    
    #
    # Trim any left/right whitespace that may have been crammed in
    # along with the XML tag.
    $attribute =~ s/^\s*//;
    $attribute =~ s/\s*$//;
    $value =~ s/^\s*//;
    $value =~ s/\s*$//;

    #
    # exit out if they try to set any magic keys
    return if ( $attribute =~ /^_/ );

    #
    # Shove the new value into our session hash
    $Apache::AxKit::Plugin::BasicSession::session{$attribute} = $value;
    return;
}

sub remove_attribute
{
    my $self = shift if (_calledAsMethod(@_));
    my ( $attribute ) = @_;
    #
    # Trim whitespace, yadda yadda.
    $attribute =~ s/^\s*//;
    $attribute =~ s/\s*$//;

    # exit out if they try to set any magic keys
    return if ( $attribute =~ /^_/ );

    # 
    # Toast the appropriate key
    delete $Apache::AxKit::Plugin::BasicSession::session{$attribute};
    return;
}

sub is_new
{
    my $self = shift if (_calledAsMethod(@_));
    return $Apache::AxKit::Plugin::BasicSession::session{_creation_time} == $Apache::AxKit::Plugin::BasicSession::session{_last_accessed_time};
}

sub invalidate
{
    my $self = shift if (_calledAsMethod(@_));
    # Invalidate the session by deleting the tied object.  See Apache::Session
    tied(%Apache::AxKit::Plugin::BasicSession::session)->delete;
    return;
}

sub if_exists
{
    my $self = shift if (_calledAsMethod(@_));
    my ( $name ) = @_;
    $name =~ s/^\s*//;
    $name =~ s/\s*$//;
    return exists($Apache::AxKit::Plugin::BasicSession::session{$name});
}

sub unless_exists
{
    my $self = shift if (_calledAsMethod(@_));
    my ( $name ) = @_;
    $name =~ s/^\s*//;
    $name =~ s/\s*$//;
    return !exists($Apache::AxKit::Plugin::BasicSession::session{$name});
}

sub if_regex
{
    my $self = shift if (_calledAsMethod(@_));
    my ( $name, $value ) = @_;
    $name =~ s/^\s*//;
    $name =~ s/\s*$//;
    return $Apache::AxKit::Plugin::BasicSession::session{$name} =~ /$value/;
}

sub unless_regex
{
    my $self = shift if (_calledAsMethod(@_));
    return !if_regex(@_);
}

sub ifkey
{
    my $self = shift if (_calledAsMethod(@_));
    my ( $name, $value ) = @_;
    $name =~ s/^\s*//;
    $name =~ s/\s*$//;
    if (defined($value)) {
        return $Apache::AxKit::Plugin::BasicSession::session{$name} ? 1 : 0;
    } else {
        return $Apache::AxKit::Plugin::BasicSession::session{$name} eq $value;
    }
}

sub unlesskey
{
    my $self = shift if (_calledAsMethod(@_));
    return !ifkey(@_);
}

sub enumerate
{
    my $self = shift if (_calledAsMethod(@_));
    # Iterate through the hash keys, and return only the hash keys
    # that don't start with "_".  There's most likely a mroe efficient
    # way of handling this, but I'll get to it later (Patches welcome).
    my @results = ();
    foreach my $key (keys %Apache::AxKit::Plugin::BasicSession::session) {
        push @results, {
            name => $key,
            value => $Apache::AxKit::Plugin::BasicSession::session{$key},
        };
    }
    return @results;
}

sub keyexists
{
    my $self = shift if (_calledAsMethod(@_));
    my ( $name ) = @_;
    $name =~ s/^\s*//;
    $name =~ s/\s*$//;
    return exists($Apache::AxKit::Plugin::BasicSession::session{$name});
}

sub count
{
    my $self = shift if (_calledAsMethod(@_));
    return scalar(keys(%Apache::AxKit::Plugin::BasicSession::session));
}

1;

__END__

=head1 NAME

AxKit::XSP::BasicSession - Session wrapper tag library for AxKit eXtesible Server Pages.

=head1 SYNOPSIS

Add the session: namespace to your XSP C<E<lt>xsp:pageE<gt>> tag:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:session="http://www.axkit.org/2002/XSP/BasicSession"
    >

And add this taglib to AxKit (via httpd.conf or .htaccess):

    AxAddXSPTaglib AxKit::XSP::BasicSession

You'll also need to set up Apache::AxKit::Plugin::BasicSession, as
described on its pod page.

=head1 DESCRIPTION

The XSP session: taglib provides basic session object operations to
XSP, using the Cocoon2 Session taglib specification.  I tried to stay
as close to the Cocoon2 specification as possible, for compatibility
reasons.  However, there are some tags that either didn't make sense to
implement, or I augmented since I was there.

Keep in mind, that currently this taglib does not actually create or
fetch your session for you.  That has to happen outside this taglib -
see Apache::AxKit::Plugin::BasicSession.  This module relies on the
$r->pnotes() table for passing the session object around.

Special thanks go out to Kip Hampton for creating AxKit::XSP::Sendmail, from
which I created AxKit::XSP::BasicSession.

=head1 Tag Reference

=head2 C<E<lt>session:get-attributeE<gt>>

This is the most used tag.  It accepts either an attribute or child node
called 'name'.  The value passed in 'name' is used as the key to retrieve
data from the session object.

=head2 C<E<lt>session:set-attributeE<gt>>

Similar to :get-attribute, this tag will set an attribute.  It accepts an
additional parameter (as an attribute or child node) called 'value'.  You
can intermix attribute and child nodes for either parameter, so its pretty
flexible.  NOTE: this is different from Cocoon2, where the value is a child
text node only.

=head2 C<E<lt>session:get-idE<gt>>

Gets the SessionID used for the current session.  This value is read-only.

=head2 C<E<lt>session:get-creation-timeE<gt>>

Returns the time the current session was created.  Cocoon2's way of handling
this is pretty wierd, so I didn't implement it 100% to spec.  This tag takes
an optional parameter of 'as', which allows you to choose your date format.
Your only options are "string" and "long", where the string output is a human-readable
string representation (e.g. "Fri Nov 23 15:38:13 PST 2001").  "long", contrary
to what you would expect, is the number of seconds since epoch.  The Cocoon2 spec
makes "long" the default, while mine specifies "string" as default.

=head2 C<E<lt>session:get-last-accessed-timeE<gt>>

Similar to :get-creation-time, except it returns the time since this session
was last accessed (duh).

=head2 C<E<lt>session:remove-attributeE<gt>>

Removes an attribute from the session object.  Accepts either an attribute or
child node called 'name' which indicates which session attribute to remove.

=head2 C<E<lt>session:invalidateE<gt>>

Invalidates, or permanently removes, the current session from the datastore.
Not all Apache::Session implementations support this, but it works just beautifully
under Apache::Session::File (which is what I used for my testing).

=head2 C<E<lt>session:exists name="foo"/E<gt>>

Returns a boolean value representing whether the indicated session key exists,
even if it has an empty or false value.

=head2 C<E<lt>session:enumerate/E<gt>>

Returns an enumerated list of the session keys present.  It's output is something
like the following:

  <session-keys>
    <key id="1">
      <name>foo</name>
      <value>bar</name>
    </key>
    ...
  </session-keys>

=head2 C<E<lt>session:count/E<gt>>

Returns the number of session keys that have been set for this particular session.

=head2 C<E<lt>session:is-newE<gt>>

This tag returns a boolean value indicating if this session is a newly-created session.

=head2 C<E<lt>session:if name="foo"E<gt></session:ifE<gt>>

Executes the code contained within the block if the named key's value
is true.  You can optionally supply the attribute "value" if you want to evaluate
the value of a key against an exact string.

This tag, as well as all the other similar tags mentioned below can be changed to
"unless" to perform the exact opposite (ala Perl's "unless").  All options must
be supplied as attributes; child elements can not be used to supply these values.

=head2 C<E<lt>session:if-exists name="foo"E<gt></session:if-existsE<gt>>

Executes the code contained within the block if the named session key exists
at all, regardless of it's value.

=head2 C<E<lt>session:if-regex name="foo" value="\w+"E<gt></session:if-regexE<gt>>

Executes the code contained within the block if the named session key matches
the regular expression supplied in the "value" attribute.  The "value" attribute
is required.

=head1 OBJECT-ORIENTED INTERFACE

There are times when using this module that you might wish to access the
BasicSession methods directly from Perl, rather than using the XSP taglib
interfaces.  You may be within an <xsp:logic> block and not want the verbosity
of a full XML tag, or you might have a heterogenous site with some XSP, some Perl
providers.  Whatever the reason, the OO interface to BasicSession will work for you.

Simply create a new BasicSession object by invoking the C<new> constructor on it:

  my $bs = new AxKit::XSP::BasicSession;

Once you have this object created, you can call any of the standard taglib
methods by using the taglib name, transposing any "-" characters to underscores.

The following is a list of the various methods available:

=over 4

=item get_attribute($name)

=item get_id()

=item get_creation_time([$as, [$format]])

=item get_last_accessed_time([$as, [$format]])

=item set_attribute($name, $value)

=item remove_attribute($name)

=item is_new($name)

=item invalidate()

=item if_exists($name)

=item unless_exists($name)

=item if_regex($name, $regex)

=item unless_regex($name, $regex)

=item ifkey($name, $value)

=item unlesskey($name, $value)

=item enumerate()

=item keyexists($name)

=item count()

=back

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

Copyright (c) 2001-2004 Michael A Nachbaur. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<AxKit>, L<Apache::Session>, L<Apache::AxKit::Plugin::BasicSession>

=cut
