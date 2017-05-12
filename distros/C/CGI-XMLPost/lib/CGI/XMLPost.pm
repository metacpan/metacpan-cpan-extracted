package CGI::XMLPost;

use strict;
use warnings;

use Carp;

our $VERSION = '1.6';

# Ripped off from CGI.pm

our $CRLF;

my $EBCDIC = "\t" ne "\011";

if ($^O eq 'VMS') 
{
  $CRLF = "\n";
} 
elsif ($EBCDIC) 
{
  $CRLF= "\r\n";
} 
else 
{
  $CRLF = "\015\012";
}

=head1 NAME

CGI::XMLPost - receive XML file as an HTTP POST

=head1 SYNOPSIS

   use CGI::XMLPost;

   my $xmlpost = CGI::XMLPost->new();

   my $xml = $xmlpost->data();

   # ... do something with $xml

=head1 DESCRIPTION

CGI::XMLPost is a lightweight module for receiving XML documents in the
body of an HTTP request.  It provides some utility methods that make it
easier to work in a CGI environment without requiring any further modules.

=head1 METHODS


=over 4

=cut


=item new

This is the constructor of the class.  If it succeeds in reading the POST
data correct it will return a a blessed object - otherwise undef.

The arguments are in the form of a hash reference - the keys are :

=over 2

=item strict

If this is set to a true value then the HTTP request method and content type
are checked.  If the first is not POST and the second does not match 'xml$'
then the method will return undef.

=back

=cut

sub new
{
   my ( $proto, $args ) = @_;

   my $class = ref($proto) || $proto;

   
   my $self = bless {}, $class;

   if ( $args->{strict} )
   {
      if ( $self->request_method() ne 'POST' or $self->content_type !~ /xml$/ )
      {
         return undef;
      }
   }

   my $cl = $self->content_length();

   if ( sysread( STDIN, $self->{_data}, $cl) == $cl )
   {
      return $self;
   }
}

=item content_type

Returns the content type of the HTTP request.

=cut

sub content_type
{
    my ( $self ) = @_;

    return $ENV{CONTENT_TYPE};
}

=item request_method

Returns the request method of the HTTP request.

=cut

sub request_method
{
   my ( $self ) = @_;

   return $ENV{REQUEST_METHOD};
}


=item content_length

Returns the content length of the request.

=cut

sub content_length
{
   my ( $self ) = @_;

   return $ENV{CONTENT_LENGTH};
}

=item data

Returns the data as read from the body of the HTTP request.

=cut

sub data
{
   my ( $self ) = @_;

   return $self->{_data};
}

=item encoding

Gets or sets the encoding used in the response.  The default is utf-8

=cut

sub encoding
{
   my ( $self, $encoding ) = @_;

   if ( defined $encoding )
   {
      $self->{_encoding} = $encoding;
   }

   return $self->{_encoding} || 'utf-8';
}

=item header

Returns a header suitable to be used in an HTTP response.  The arguments are
in the form of key/value pairs - valid keys are :

=over 2

=item status

The HTTP status code to be returned - the default is 200 (OK).

=item type

The content type of the response - the default is 'application/xml'.

=back

=cut

sub header
{
   my ( $self, %args ) = @_;

   my @header;

   $self->{status} = $args{status} || 200;

   push @header, "Status: $self->{status}";

   $self->{type} = $args{type}   || 'application/xml';

   my $charset = $self->encoding();

   push @header, "Content-Type: $self->{type}; charset=$charset";   

   my $header = join $CRLF, @header;

   $header .= $CRLF x 2;

   return $header;

}

my %status_codes = (
                     200 => "OK",
                     405 => "Method Not Allowed",
                     415 => "Unsupported Media Type",
                     400 => "Bad Request",
                    );

=item response

Returns a string that is suitable to be sent in the body of the response.
The default is to return an XML string of the form :

       <?xml version="1.0" encoding="iso-8859-1"?>
       <Response>
         <Code>$status</Code>
         <Text>$text</Text>
       </Response>
   
Where $status is the status code used in the header as described above and
$text is the desciptive text for that status.  If a different text is required
this can be supplied with the argument key 'text'.

=cut

sub response
{
   my ( $self, %args ) = @_;

   my $status = $self->{status} || 200;
   my $text = $args{text} || $status_codes{$status};

   my $type = $self->{type} || 'application/xml';

   my $response;

   my $encoding = $self->encoding();

   if ( $type =~ /xml$/i )
   {
     $response =<<EOX;
<?xml version="1.0" encoding="$encoding"?>
<Response>
  <Code>$status</Code>
  <Text>$text</Text>
</Response>
EOX
   }
   else
   {
     $response = $text;
   }   
   return $response;
}

=item remote_address

Remotes the address of the remote peer if it is known.

=cut

sub remote_address
{
    my ( $self ) = @_;
    return $ENV{REMOTE_ADDRESS};
}

=item as_xpath

Returns an XML::XPath object inititialized with the received XML or a false
value if XML::XPath is not present or the parse failed.

=cut

sub as_xpath
{
    my ( $self ) = @_;

    my $got_xpath = undef;

    eval
    {
       require XML::XPath;
       $got_xpath = 1;
    };

    return $got_xpath ? XML::XPath->new(xml => $self->data()) : undef;
}

1;
__END__

=back

=head1 AUTHOR

Jonathan Stowe <jns@gellyfish.co.uk>

=head1 SEE ALSO

CGI

=head1 LICENSE

Please see the README file in the source distribution for the licence of this
module.

=cut

