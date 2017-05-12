#!/usr/bin/perl -s
## 
## CGI::Persistent
## 
## Copyright (c) 1998, Vipul Ved Prakash.  All Rites Reversed. 
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: Persistent.pm,v 0.21 1999/12/07 04:18:30 root Exp root $

package CGI::Persistent; 

use CGI '-no_xhtml'; 
use Persistence::Object::Simple; 
use vars qw(@ISA $VERSION);
use Data::Dumper;
use File::Basename;
@ISA = qw( CGI ); 
$VERSION = '1.11';

sub new { 

    my ( $class, $dope, $id ) = @_ ; 
    $dope = "." unless $dope; 
    my $cgi = new CGI; # print $cgi->header ();
    my $fn  = fileparse($cgi->param( '.id' ) || $id || ''); 

    unless ( $fn ) { 
        my $po = new Persistence::Object::Simple ( __Dope => $dope ); 
        $fn = fileparse $po->{ __Fn };
        $cgi->append( -name => '.id', -values => $fn );
	    undef $po; 
    }

    my $po = new Persistence::Object::Simple __Fn => "$dope/$fn";
    $po->{ __DOPE } = undef; 
    $po->{sessiondir} = $dope;
    my @names = $cgi->param (); 

    my $st = $cgi->param('.sailthru'); 
    unless ( $st ) { 
        for ( @names ) { $po->{$_} = $cgi->param( $_ ) unless $_ eq ".id" }
    } 

    foreach $key ( keys %$po ) { 
        $cgi->param( -name => $key, -values => $po->{$key} )
        unless ( grep /$key/, @names ) || $key eq "__Fn";
    }

    $cgi->{sessiondir} = $po->{sessiondir};

    # Stringify the params. This is black magic to work around an interpreter
    # crash in Data::Dumper.
    foreach my $param ($cgi->param)
    {
        my $s = "param $param is " . $cgi->param($param) . "\n";
    }

    $po->commit ();
    return bless $cgi, $class; 

}

sub delete { 
  
    my ( $self, $param ) = @_; 
    my $fn = join "/", ($self->{sessiondir},$self->param( '.id' )); 
    my $po = new Persistence::Object::Simple __Fn => $fn; 
    delete $po->{ $param }; $po->commit ();  
    $self->SUPER::delete ( $param ); # delete, is like, overloaded. 

}

sub delete_all { 

    my ( $self ) = shift; 
    $fn = join "/", ($self->{sessiondir},$self->param( '.id' )); 
    my $po = new Persistence::Object::Simple __Fn => $fn; 
    $po->expire; 
    $self->SUPER::delete_all ();

}

sub state_url { 

    my ( $self ) = @_; 
    return $self->url ."?.id=".$self->param('.id');

}

sub state_url_thru { 

    my ( $self ) = @_; 
    return $self->url ."?.id=".$self->param('.id')."&.sailthru=1";

}

sub state_field { 

    my ( $self ) = @_; 
    my $id = $self->param ( '.id' ) || "";
    return "<input type=hidden name=\".id\" value=\"$id\">"; 

}

sub state_field_thru { 

    my ( $self ) = @_; 
    my $id = $self->param ( '.id' );
    return "<input type=hidden name=\".id\" value=\"$id\">" . "\n" .
    "<input type=hidden name=\".sailthru\" value=\"1\">"; 

}

1;

=head1 NAME

CGI::Persistent -- Transparent state persistence for CGI applications. 

=head1 SYNOPSIS

    use CGI::Persistent; 

    my $cgi = new CGI::Persistent "/directory";
    print $cgi->header (); 
    my $url = $cgi->state_url (); 
    print "<a href=$url>I am a persistent CGI session.</a>"; 

=head1 SOLUTION TO THE STATELESS PROBLEM

HTTP is a stateless protocol; a HTTP server closes connection after
serving an object. It retains no memory of the request details and doesn't
relate subsequent requests with what it has already served. While this
works well for static resources like HTML pages and image elements,
complex user interactions often require state preservation across multiple
requests and different parts of the web resource. Statefulness on a
stateless server is achieved either through client-side mechanisms like
Netscape cookies or with hidden fields in forms and value-attribute pairs
in the URLs. State preserving URLs are more desirable, because they are
independent of the client configuration, but tend to get unwieldy with
increase in space complexity of the application.

CGI::Persistent solves this problem by introducing persistent CGI sessions
that store their state data on the server side. When a new session starts,
CGI::Persistent automatically generates a unique state identification string
and associates it with a persistent object on the server. The identification
string is used in URLs or forms to refer to the particular session. Request
attributes are transparently committed to the associated object and the
object data is bound to the query.

CGI::Persistent is derived from CGI.pm. CGI.pm methods have been overridden
as appropriate. Very few new methods have been added.  

=head1 METHODS 

=over 4

=item B<new()>

Creates a new CGI object and binds it to its associated persistent state.
A new state image is created if no associated state exists. new() takes
two optional arguments. The first argument is the directory of
persistence, the place where state information is stored. Ideally, this
should be a separate directory dedicated to state files. When a directory
is not specified, the current working directory is assumed.

new() can also take a state id on the argument list instead of getting it
from the query. This might be useful if you are using this module to store
configuration data that you wish to retain across different sessions.

Examples: 

 $q = new CGI::Persistent; 
 $q = new CGI::Persistent "/sessions";
 $q = new CGI::Persistent  undef, "/sessions/924910985.134";

=item B<state_url()>

Returns a URL with the state identification string. This URL should be used
for referring to the persistent session associated with the query.

=item B<state_field()> 

Returns a hidden INPUT type for inclusion in HTML forms. Like state_url(),
this element is used in forms to refer to the associated persistent session.


=item B<delete()>

delete() is an overridden method that deletes a named attribute from the 
query.  The persistent object field associated with the attribute is 
also deleted. 

Important note: Attributes that are NOT explicitly delete()ed will lurk
about and come back to haunt you. Remember to clear control attributes and
other context dependent fields that need clearing. See L<CGI/delete()>.

=item B<delete_all()>

Another overridden method. Deletes all attributes as well as the persistent
disk image of the session. This method should be used when you want to
irrevocably destroy a session. See L<CGI/delete_all()>.

=back

=head1 EXAMPLES

The accompanying CGI example, roach.cgi, illustrates the features of the
module by implementing a multi-page input form.

=head1 SEE ALSO 

CGI(3), 
Persistence::Object::Simple(3)

=head1 LICENSE 

CGI::Persistent is distributed under the same license as Perl itself.

=head1 REVISION HISTORY 

=over 4 

=item 1.00 Released 1998 

=item 1.10 Applies patches from folks at Mitel/SME server. <http://rt.cpan.org/Public/Bug/Display.html?id=30970>

=back

=head1 AUTHOR

Vipul Ved Prakash, mail@vipul.net

=cut
