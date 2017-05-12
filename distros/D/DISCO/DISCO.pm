package DISCO;

# Copyright 2004 Christian Wenz -- http://www.hauser-wenz.de/

use strict;

our $VERSION = "0.01";

our $URI;
our $DATA = undef;

use XML::Simple;
use LWP::UserAgent;

sub new {
  my $self = shift;
  my $class = ref($self) || $self;

  my %params = @_;
  $self = { URI => $params{URI} || undef };

  bless ($self, $class);

  return $self;
}

sub _get_data
{
    my $uri = shift; 
    my $req = HTTP::Request->new(GET => $uri);
  
    my $ua = LWP::UserAgent->new;
    $ua->agent("DISCO.pm/$VERSION " . $ua->agent);
    my $res = $ua->request($req);

    if ($res->is_success) {
        return $res->content;
    } else {
        print $res->status_line;
    }
}

sub get_ref
{
    my $self = shift; 
    $self->{DATA} = XMLin(_get_data($self->{URI})) unless defined;
    return $self->{DATA}->{contractRef}->{ref};
}

sub get_docRef
{
    my $self = shift;
    $self->{DATA} = XMLin(_get_data($self->{URI})) unless defined;
    return $self->{DATA}->{contractRef}->{docRef};
}

sub get_address
{
    my $self = shift;
    $self->{DATA} = XMLin(_get_data($self->{URI})) unless defined;
    return $self->{DATA}->{soap}->{address};
}

# ----------------------------------

1;

__END__

=head1 NAME

DISCO - DISCO client interface

=head1 SYNOPSIS

 use DISCO;

 my $disco = DISCO->new(URI => 'http://');
 print 'ref: ' . $disco->get_ref . "\n";
 print 'docRef: ' . $disco->get_docRef . "\n";
 print 'address: ' . $disco->get_address;

=head1 DESCRIPTION

This module provide functions to interpret DISCO.
DISCO (short for Discovery) is a pseudo-standard by Microsoft. 
A published .disco file, which is an XML document that contains 
links to other resources that describe the XML Web service, 
enables programmatic discovery of an XML Web service. 
More information at I<msdn.microsoft.com/library/en-us/cpguide/html/cpconwebservicediscovery.asp>.

The interface exposed provides access to the ref, docRef and address attributes of a DISCO file.

=head1 FUNCTIONS

The following functions are provided.  All are exported by
default.  
All the get_xxx() return the value of the xxx attribute in the provided XML. 
The constructor expects the URI of the DISCO file in the URI parameter.

=over

=item get_ref()

This function returns the value of the ref element in the DISCO file.

=item get_docRef()

This function returns the value of the docRef element in the DISCO file.

=item get_address()

This function returns the value of the address element in the DISCO file.

=back

=head1 GLOBALS

=head2 $URI

The URI of the DISCO file.

=head1 BUGS AND LIMITATIONS

=over

=item Does not understand (yet) multiple entries in the DISCO file

=item Does not support (yet) local DISCO files

=item Limited support for auto-generated DISCO files by Visual Studio .NET

=item Automatic generation of WSDL proxies (using SOAP::Lite) not yet implemented

=back

=head1 SEE ALSO

DISCO reqires use XML::Simple and LWP::UserAgent.

http://msdn.microsoft.com/library/en-us/cpguide/html/cpconwebservicediscovery.asp

=head1 AUTHOR

Christian Wenz <wenz@cpan.org>

Copyright 2004 Christian Wenz -- http://www.hauser-wenz.de/

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
