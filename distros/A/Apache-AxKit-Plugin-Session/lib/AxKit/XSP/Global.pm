# Axkit::XSP::Global - application global variable management
package AxKit::XSP::Global;
use strict;
use Apache::AxKit::Language::XSP::SimpleTaglib;
use Apache::AxKit::Plugin::Session;
our $VERSION = 0.98;
our $NS = 'http://www.creITve.de/2002/XSP/Global';

sub start_document {
        return 'use Apache::AxKit::Plugin::Session;'."\n".
               'use Time::Piece;'."\n";
}

sub start_xml_generator {
        return 'my $global = Apache->request->pnotes("GLOBAL");'."\n\n";
}

package AxKit::XSP::Global::Handlers;

sub get_attribute : XSP_attribOrChild(name) XSP_exprOrNode(attribute) XSP_nodeAttr(name,$attr_name)
{
        return '$attr_name =~ s/^(_|auth_|X)/X\1/; $$global{$attr_name};';
}
*get_value = \&get_attribute;

sub get_attribute_names : XSP_exprOrNodelist(name)
{
        return 'map { m/^(?:_|auth_)/?():substr($_,0,1) eq "X"?substr($_,1):$_ } keys %$global';
}
*get_value_names = \&get_attribute_names;

sub get_creation_time : XSP_attrib(as) XSP_exprOrNode(creation-time)
{
        my ($e, $tag, %attribs) = @_;
        if ($attribs{'as'} eq 'string') {
                return 'localtime($$global{"_creation_time"})->strftime("%a %b %d %H:%M:%S %Z %Y");';
        } else {
                return '$$global{"_creation_time"};';
        }
}

sub remove_attribute : XSP_attribOrChild(name)
{
        return '$attr_name =~ s/^(_|auth_|X)/X\1/; delete $$global{$attr_name};';
}
*remove_value = \&remove_attribute;

sub set_attribute : XSP_attribOrChild(name) XSP_captureContent
{
        return '$attr_name =~ s/^(_|auth_|X)/X\1/; $$global{$attr_name} = $_;';
}
*put_value = \&set_attribute;

1;

__END__

=head1 NAME

AxKit::XSP::Global - Application global variables tag library for AxKit eXtensible Server Pages.

=head1 SYNOPSIS

Add the global: namespace to your XSP C<<xsp:page>> tag:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:global="http://www.creITve.de/2002/XSP/Session"
    >

Add this taglib to AxKit (via httpd.conf or .htaccess):

    AxAddXSPTaglib AxKit::XSP::Global

=head1 DESCRIPTION

The XSP globals taglib provides basic application global variable
operations to XSP similar to the Cocoon2 Session taglib specification.
The global variables provided by this taglib have limited persistance. They may
get removed on server restarts or storage cleanups. Don't use them for
persistent data which belongs into some kind of tatabase. Example uses:
tracking of logged in users (The Auth taglib does that), accumulating daily
statistics, changing global application state for limited time.

This taglib works in conjunction with Apache::AxKit::Plugin::Session,
which does all the hard work. There are several configuration variants
available, see the man page for details.

=head1 Tag Reference

All tags returning a value look at the attribute 'as' to determine the type
of result. If it equals 'node', the result gets placed inside an XML node
with a name like the original tag minus 'get-'.
Any other value results in a behaviour similar to putting <xsp:expr> around
the string representation of the output, which means that usually the right thing
happens.

Tags that return a list create multiple XML nodes (for 'as="node"') or a concatenation
of the values without any separator.

Tags that use their contents as input should only get text nodes (including
<xsp:expr>-style tags). Attribute nodes as mentioned in the description may be used,
of course.

All tags ignore leading and trailing white space.

=head2 C<<global:get-attribute>>

This tag retrieves an attribute value.  It accepts either an attribute or
child node called 'name'.  The value passed as 'name' determines the key
to retrieve data from the global storage.

=head2 C<<global:set-attribute>>

This tag sets an attribute value.  It accepts either an attribute or
child node called 'name'.  The value passed in 'name' determines the key
to store the contents of this tag into the global storage.

=head2 C<<global:get-creation-time>>

Returns the time the current storage got created. This can happen after server
restarts or after 'hot' storage cleanups. For this tag, the "as" attribute has
two more values: 'long' (default) returns the time as seconds since 1970-01-01,
00:00 UTC; 'string' returns a textual representation of the date and time.

=head2 C<<global:remove-attribute>>

Removes an attribute from the global storage.  It accepts either an attribute or
child node called 'name' which indicates which attribute to remove.

=head1 BUGS

This software has beta quality. Use with care and contact the author if any problems occur.

=head1 AUTHOR

Jörg Walter <jwalt@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002 Jörg Walter.
All rights reserved. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

AxKit, Apache::Session, Apache::AxKit::Plugin::Session, AxKit::XSP::Auth, AxKit::XSP::Session,
Cocoon2 Session Logicsheet L<http://xml.apache.org/cocoon2/userdocs/xsp/session.html>

=cut
