package AxKit::XSP::QueryParam;
# $Id: QueryParam.pm,v 1.6 2004/01/28 00:35:19 nachbaur Exp $
use Apache;
use Apache::Request;
use Apache::AxKit::Language::XSP::TaglibHelper;
sub parse_char  { Apache::AxKit::Language::XSP::TaglibHelper::parse_char(@_); }
sub parse_start { Apache::AxKit::Language::XSP::TaglibHelper::parse_start(@_); }
sub parse_end   { Apache::AxKit::Language::XSP::TaglibHelper::parse_end(@_); }

@EXPORT_TAGLIB = (
    'exists($name):isreally=paramexists',
    'remove($name)',
    'set($name,$value)',
    'get($name;$index)',
    'count(;$name)',
    'if($name;$value):conditional=1:isreally=ifparam',
    'unless($name;$value):conditional=1:isreally=unlessparam',
    'if_regex($name,$value):conditional=1',
    'unless_regex($name,$value):conditional=1',
    'if_exists($name):conditional=1',
    'unless_exists($name):conditional=1',
    'enumerate(;$name):listtag=param-list:itemtag=param:forcearray=1',
);

@ISA = qw(Apache::AxKit::Language::XSP::TaglibHelper);
$NS = 'http://www.axkit.org/2002/XSP/QueryParam';
$VERSION = "0.02";

use strict;

## Taglib subs

sub if_exists
{
    my ( $name ) = @_;
    if (paramexists($name)) {
        return 1;
    }
    return undef;
}

sub unless_exists
{
    return undef if (if_exists(@_));
    return 1;
}

sub if_regex
{
    my ( $name, $value ) = @_;
    my $r = Apache->request;
    my $req = Apache::Request->instance($r);
    if ($req->param($name) =~ /$value/) {
        return 1;
    }
    return undef;
}

sub unless_regex
{
    return undef if (if_regex(@_));
    return 1;
}

sub ifparam
{
    my ( $name, $value ) = @_;
    my $r = Apache->request;
    my $req = Apache::Request->instance($r);
    if (defined($value)) {
        if ($req->param($name) =~ /^-?\d*\.?\d+$/ and $value =~ /^-?\d*\.?\d+$/) {
            if ($req->param($name) == $value) {
                return 1;
            }
        } else {
            if ($req->param($name) eq $value) {
                return 1;
            }
        }
    } else {
        if ($req->param($name)) {
            return 1;
        }
    }
    return undef;
}

sub unlessparam
{
    return undef if (ifparam(@_));
    return 1;
}

sub paramexists
{
    my ( $name ) = @_;
    my $r = Apache->request;
    my $req = Apache::Request->instance($r);
    my @params = $req->param;
    foreach my $key (@params) {
        return 1 if ($key eq $name);
    }
    return 0;
}

sub remove
{
    my ( $name ) = @_;
    my $r = Apache->request;
    my $req = Apache::Request->instance($r);
    my $table = $req->parms;
    $table->unset($name);
    return undef;
}

sub set
{
    my ( $name, $value ) = @_;
    my $r = Apache->request;
    my $req = Apache::Request->instance($r);
    $req->param($name, $value);
    return undef;
}

sub get
{
    my ( $name, $index ) = @_;
    my $r = Apache->request;
    my $req = Apache::Request->instance($r);
    my @values = $req->param($name);
    if ($index) {
        return $values[$index - 1];
    } else {
        return $values[0];
    }
}

sub enumerate
{
    my ( $name ) = @_;
    my $r = Apache->request;
    my $req = Apache::Request->instance($r);
    my @tree = ();
    if ($name) {
        foreach my $value ($req->param($name)) {
            push @tree, {
                name  => $name,
                value => $value,
            };
        }
    } else {
        foreach my $key ($req->param) {
            foreach my $value ($req->param($key)) {
                push @tree, {
                    name  => $key,
                    value => $value,
                };
            }
        }
    }
    return @tree;
}

sub count
{
    my ( $name ) = @_;
    my $r = Apache->request;
    my $req = Apache::Request->instance($r);
    if ($name) { 
        my @values = $req->param($name);
        return scalar(@values);
    } else {
        my $count = 0;
        foreach my $key ($req->param) {
            foreach my $value ($req->param($key)) {
                $count++;
            }
        }
        return $count;
    }
}

1;

__END__

=head1 NAME

AxKit::XSP::QueryParam - Advanced parameter manipulation taglib

=head1 SYNOPSIS

Add the parm: namespace to your XSP C<<xsp:page>> tag:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:param="http://www.axkit.org/2002/XSP/QueryParam"
    >

And add this taglib to AxKit (via httpd.conf or .htaccess):

    AxAddXSPTaglib AxKit::XSP::QueryParam

=head1 DESCRIPTION

AxKit::XSP::QueryParam is a taglib built around the Apache::Request
module that allows you to manipulate request parameters beyond simple
getting of parameter values.

=head1 Tag Reference

=head2 C<<param:get name="foo" index="1"/>>

Get a value from the given parameter.  The "name" attribute can be passed
as a child element for programattic access to parameter values.  If the index
attribute is supplied, and if multiple parameters are supplied for the
same "name", then the appropriate parameter is returned.  If multiple values
for the same parameter are given, but no index is supplied, the first value is
returned. Now, if you can
understand that convoluted set of instructions, then you're smarter than me!

=head2 C<<param:set name="foo" value="bar"/>>

Set a parameter value.  You can use child elements for both "name" and
"value".  This is very useful when you want to override the parameters
provided by the userr.

=head2 C<<param:remove name="foo"/>>

Remove a parameter.  Surprisingly enough, you can use child elements here
as well.  Are you beginning to notice a pattern?

=head2 C<<param:exists name="foo"/>>

Returns a boolean value representing whether the named parameter exists,
even if it has an empty or false value.  You can use child...oh, nevermind,
you get the idea.

=head2 C<<param:enumerate/>>

Returns an enumerated list of the parameter names present.  Now, it hardly
needs to be said, but unfortunately, it will be said anyway: This tag can
take a name attribute (or, well, see above) supplying the name of the parameter
you want to enumerate.

Why, you may ask, is this necessary?  If multiple parameters are supplied that
all have an identical name, this attribute will allow you to enumerate all the
appropriate name/value pairs for that key name.  It's output is something like the
following:

  <param-list>
    <param id="1">
      <name>foo</name>
      <value>bar</name>
    </param>
    ...
  </param-list>

=head2 C<<param:count name="foo"/>>

Returns the number of parameters provided on the request.  If a name is provided,
the number of parameters supplied for the given name is returned.  If the name is
left out, then the total number of parameters is returned.

=head2 C<<param:if name="foo"></param:if>>

Executes the code contained within the block if the named parameter's value
is true.  You can optionally supply the attribute "value" if you want to evaluate
the value of a parameter against an exact string.

This tag, as well as all the other similar tags mentioned below can be changed to
"unless" to perform the exact opposite (ala Perl's "unless").  All options must
be supplied as attributes; child elements can not be used to supply these values.

=head2 C<<param:if-exists name="foo"></param:if-exists>>

Executes the code contained within the block if the named parameter exists
at all, regardless of it's value.

=head2 C<<param:if-regex name="foo" value="\w+"></param:if-regex>>

Executes the code contained within the block if the named parameter matches
the regular expression supplied in the "value" attribute.  The "value" attribute
is required.

=head1 AUTHOR

Michael A Nachbaur, mike@nachbaur.com

=head1 COPYRIGHT

Copyright (c) 2002-2004 Michael A Nachbaur. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<AxKit>, L<Apache::Request>

=cut
