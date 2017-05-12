package Apache::AxKit::Provider::XMLDOMProvider;

use base qw(Apache::AxKit::Provider);
use 5.008004;
use strict;
use warnings;
use Apache;
use Apache::Log;
use Apache::AxKit::Exception;
use Apache::AxKit::Provider::File;
use XML::LibXML;
use LWP::UserAgent;
use Time::Piece;
# only used for debugging
#use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter Apache::AxKit::Provider);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Apache::AxKit::Provider::XMLDOMProvider ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    new init process exists mtime get_fh get_strref key get_styles get_ext_ent_handler
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    new init process exists mtime get_fh get_strref key get_styles get_ext_ent_handler
);

our $VERSION = '0.03';

# sub: init
# here we do some initialization stuff.
sub init {
    my $self = shift;
    my $r = $self->{apache};
    my $mtime_element = $r->dir_config('RemoteXMLmTimeElement');

    # prepare remote XML
    my $url = $r->dir_config('RemoteXML');
    # append query if defined
    my $query = $r->args();
    if ( defined $query ) {
	$url .= "?" . $query;
    }

    # get xml with substitute request
    my $ua = LWP::UserAgent->new();
    $ua->timeout(10);
    my $response = $ua->get($url);

    # store some stuff for later use
    $self->{response} = $response; 
    $self->{xmlfile} = $url;
    $self->{id} = $url;
    $self->{mtime_element} = $mtime_element;
}

# sub: get_fh
# we don't want to handle files, so we just throw an exception here.
sub get_fh {
    throw Apache::AxKit::Exception::IO( -text => "Can't get filehandle for XMLDOMProvider (not yet implemented)!" );
}

# sub: get_strref
# since we refused to work with file handles, we HAVE to define this.
# returns a string containing the remote XML-DOM
sub get_strref {
    my $self = shift;
    my $response = $self->{response};
    my $string = $response->content();

    # debug
    #my $h = $response->server;
    #throw Apache::AxKit::Exception::Error(-text => "Last Modified Header: \"$h\"");

    # some XML validation
    my $parser = XML::LibXML->new();
    $parser->validation(0);
    $parser->load_ext_dtd(0);
    $parser->expand_xinclude(0);
    $parser->expand_entities(0);
    my $dom;
    eval {
	$dom = $parser->parse_string($string);
    };
    if ($@) {
	throw Apache::AxKit::Exception::Error( -text => "Input must be well-formed XML: $@" );
    }

    # if everything went fine, return xml-string-reference
    return \$string;
}

# sub: mtime
# we want to cache our stuff; the mtime is determined
# from the mdate (YYYY-MM-DD hh:mm) element "<mdate></mdate>" placed
# somewhere in the remote XML-DOM;
# CAUTION: do not provide multiple mdate elements in one single XML-DOM;
# if mdate is not provided, we refuse to cache
sub mtime {
    my $self = shift;
    my $mtime_element = $self->{mtime_element};

    # debug
    #print STDERR Dumper( $self->{id} );

    # return cached mtime, if this is the second call per request
    return $self->{mtime}->{$self->{id}} if defined $self->{mtime}->{$self->{id}};

    # mtime stuff
    # twiggle out mdate from string-content
    $self->{response}->content() =~ m/.*\<$mtime_element\>([^\<]*)\<\/$mtime_element\>/;
    my $mdate = $1;

    # debug
    #print STDERR Dumper( "mdate: ", $mdate );

    my $mtime;
    # test if $mdate is provided in xml-dom

    if ( defined $mdate ) {
	# create time-piece object
	# mdate format example: 2007-06-26 02:42
	my $time_obj = Time::Piece->strptime( $mdate, "%Y-%m-%d %H:%M" );
	$mtime = $time_obj->epoch();

	# debug
	#print STDERR Dumper( "mtime in secs: ", $mtime );
    }
    else {
	# else invalidate cache
	$mtime = time();
	
	# debug
	#print STDERR Dumper("now: ", $mtime );
    }

    # cache mtime, since mtime is called twice per request
    $self->{mtime}->{$self->{id}} = $mtime;

    # debug
    #print STDERR Dumper( "return value: ", $mtime );

    return $mtime;
}

# sub: process
# we always answer requests :-)
sub process {
    my $self = shift;
    return 1;
}

# sub: key
# should return a unique identifier for the resource.
# we assume the id from the uri (including query params) is a good one.
sub key {
    my $self = shift;
    return $self->{id};
}

# sub: exists
# returns 1 if remote XML-DOM is accessible
# throws AxKit IO exception otherwise
sub exists {
    my $self = shift;
    my $response = $self->{response};
    my $url = $self->{xmlfile};
    if ( $response->is_success() ) {
	return 1;
    }
    else {
	throw Apache::AxKit::Exception::IO( -text =>  $response->status_line() . ": Cannot access upstream resource: \"$url\"" );
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Apache::AxKit::Provider::XMLDOMProvider - AxKit Provider for remote XML-DOMs available via HTTP

=head1 SYNOPSIS

  AxContentProvider Apache::AxKit::Provider::XMLDOMProvider
  PerlSetVar RemoteXML "http://www.example.com/xmlfile.xml"
  PerlSetVar RemoteXMLmTimeElement "mdate"

=head1 DESCRIPTION

Apache::AxKit::Provider::XMLDOMProvider allows for local transformation of
remote XML-Files available via HTTP. The remote XML-file for local processing
can be specified in the Apache::AxKit configuration. Additionally, an element
holding adequate modification time information can be provided via the
Apache::AxKit configuration. This Apache::AxKit-Provider is very useful for
local processing of dynamically generated XML-DOMs available via a Web-server,
especially if one needs to pass specific query parameters to it. 

The URI of the remote XML-file is specified with the RemoteXML variable.
RemoteXMLmTimeElement should hold the name of the XML-Element which contains
date information when the remote XML-file was last modified (format "YYYY-MM-DD
hh:mm"; e.g. "2007-07-15 16:20"). Is the element specifying the modification
time not present, the remote XML-file will not be cached and hence fetched for
each request. This module uses LWP::UserAgent to get remote XML-files. 

=head2 EXPORT

All by default.

=head1 SEE ALSO

Apache::AxKit (http://www.axkit.org)

=head1 AUTHOR

Severin Gehwolf, E<lt>Severin.Gehwolf@uibk.ac.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Severin Gehwolf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
