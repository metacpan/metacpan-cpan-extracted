package Dancer::Plugin::RPC::XML;

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Exception ':all';
use Dancer::Plugin;
use RPC::XML;
use RPC::XML::ParserFactory;

our $VERSION = '0.06';

register 'xmlrpc' => \&xmlrpc;
register 'xmlrpc_fault' => \&xmlrpc_fault;

hook before => sub {
  if (request->is_post) {
    content_type('text/xml');
  }
};

sub xmlrpc {
  my ($pattern, @rest) = @_;
  
  my $code;
  for my $e (@rest) { 
    $code = $e if ref($e) eq 'CODE';
  }

  my $rpcxml_route = sub {  
    if ( not request->is_post ) {
      pass and return 0;
    }
  
    # disable layout
    my $layout = setting('layout');
    setting('layout' => undef);
  
    # parse the request body
    my $xml = request->body;
		
    return RPC::XML::response->new(
      RPC::XML::fault->new(-1,  "XML parse failure - empty"))->as_string if ( !$xml || $xml =~ /^\s?$/ );
	
    my $reqobj = RPC::XML::ParserFactory->new()->parse( $xml );
  
    if ( not ref $reqobj ) {
      return RPC::XML::response->new(
        RPC::XML::fault->new(-2,  "XML parse failure: $reqobj"))->as_string;
    }
  
    my @data = @{$reqobj->args};
    my $name = $reqobj->name;
  
    my @values = ();
    for my $v (@data) { push @values, $v->value; };
  
    # stuff data into params
    request->_set_route_params( { 'method' => $name, 'data' => \@values } );
  
    # call the code
    my $response = try {
      $code->();
    } catch {
      my $e = $_;
      setting('layout' => $layout);
      die $e;
    };

    # re-enable layout
    setting('layout' => $layout);

    # wrap the response in xml with RPC::XML
		if ( ref $response ne 'RPC::XML::response' ) {
    	return RPC::XML::response->new( $response )->as_string;
		}
		else {
		 	return $response->as_string;
		}
  };

  # rebuild the @rest array with the compiled route handler
  my @compiled_rest;
  for my $e (@rest) {
    if (ref($e) eq 'CODE') {
      push @compiled_rest, {}, $rpcxml_route;
    }
    else {
      push @compiled_rest, {}, $e;
    }
  }
 
  any ['post'] => $pattern, @compiled_rest;
	#any ['get', 'post'] => $pattern, @compiled_rest;
}

sub xmlrpc_fault {
  return RPC::XML::response->new(RPC::XML::fault->new( @_ ));
};

register_plugin;
1; # End of Dancer::Plugin::RPC::XML

=head1 NAME

Dancer::Plugin::RPC::XML - A plugin for Dancer to wrap XML-RPC calls

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

Quick summary of what the module does.

  # in your app.pl
  use Dancer::Plugin::RPC::XML;

	xmlrpc '/foo/bar' => sub {
	  # methodname
	  my $method = params->{method};
    # listref of data
    my $data = params->{data};

    return xmlrpc_fault(100,"Undefined method") unless $method =~ /something_known/;

	  my $response;
 
    $response->{name} = "John Smith";

	  return $response;
  };
 
=head1 REGISTERED METHODS

=head2 xmlrpc
 
Route handler for xmlrpc routes. Unwraps requests and re-wraps responses in xml using
the RPC::XML module.

=head2 xmlrpc_fault( $faultCode, $faultString )

Returns xmlrpc fault xml

=head1 AUTHOR

Jesper Dalberg, C<< <jdalberg at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-rpc-xml at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-RPC-XML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::RPC::XML

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-RPC-XML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-RPC-XML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-RPC-XML>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-RPC-XML/>

=back

=head1 ACKNOWLEDGEMENTS

=over

=item * Thanks to Randy J Ray (RJRAY) for the wonderful RPC::XML module
 
=item * Thanks to the Dancer project for creating an alternative to CGI!

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Jesper Dalberg, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
