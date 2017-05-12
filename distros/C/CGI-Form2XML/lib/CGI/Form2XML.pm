package CGI::Form2XML;

=head1 NAME

CGI::Form2XML - Render CGI form input as XML

=head1 SYNOPSIS


   use CGI::Form2XML;


   my $x = CGI::Form2XML->new();

   $x->ns_prefix("nfd");

   print $x->asXML();


=head1 DESCRIPTION

This module provides a method of taking CGI form input and turning it into
XML for further processing by another application or storage.  Unlike
modules such CGI::XML and CGI::XMLForm it produces XML to a fixed schema
whose structure is not influenced by the form input.  If flexibility as to
the structure of the XML data is required you will probably want to consider
one of the other modules.

The schema is included in the distribution of this module as "xmlform.xsd".

The module inherits from the CGI module in order to get access to the CGI
parameters, so any of the methods of that module can be used.

=head2 METHODS

=over 4

=cut

use strict;
use warnings;

use CGI;
use POSIX qw(strftime);

use base 'CGI';

our $VERSION = '1.6';

=item  new

The constructor for the class.  Returns a blessed object of type CGI::Form2XML.
Any arguments provided will be passed to the constructor of CGI.

=cut

sub new
{
    my ( $proto, @args) = @_;

    my $class = ref($proto) || $proto;


    my $self  = $class->SUPER::new(@args);

    bless $self, $class;


    return $self;
}


=item asXML

Returns the XML document that represents this CGI request.
It takes a hashref of arguments whose keys are :

=over 2

=item ns_prefix

The namespace prefix that should be used for this document.  The default
is no namespace.

=item ns_url

The URL that describes this namespace - the default is 
'http://schemas.gellyfish.com/FormData', there is currently nothing at this
URL.

=item omit_info

If this is set to a true value then the 'header' information will not be
emitted by asXML().

=back

=cut

sub asXML
{
   my ( $self, $args ) = @_;

   my $xml  = '';
   my $info = '';
   my $items = '';

   my $indent = ' ' x 3;

   my @params = grep !/(?:destination|session_id|owner)/, $self->param();

   my ($referer, $handler, $time, $destination, $session_id, $owner);

   my $ns_prefix = $args->{ns_prefix} || $self->ns_prefix();
   my $ns_url    = $args->{ns_url}    || $self->ns_url();

   my %info;

   my $pref = $ns_prefix ? "$ns_prefix:" : '' ;

   unless ( $self->omit_info() || $args->{omit_info} )
   {
      my %mandatory = (
                         referer   => 1,
                         handler   => 1,
                         timestamp => 1
                      );

      $info{referer} = $self->referer() || '';
      $info{handler} = $self->script_name() || '';

      $info{timestamp}    = strftime("%Y-%d-%mT%H:%M:%S",localtime());     


      $info{destination} = $self->param('destination') || $self->destination() 
                                                      || '';
      $info{session_id}  = $self->param('session_id') || $self->sess_id() || '';
      $info{owner}       = $self->param('owner') || $self->owner() || '' ;

       

      
     for my $item ( keys %info )
     {
       my $indent = $indent x 2;
       
       if ( length $info{$item} )
       {
          $info{$item} = _quote_xml($info{$item});
          
          $info .= "$indent<$pref$item>$info{$item}</$pref$item>\n";
       }
       elsif ($mandatory{$item})
       {
          $info .= "$indent<$pref$item />\n";
       }
     }

     $info = "$indent<${pref}info>\n$info$indent</${pref}info>\n";
  }

  foreach my $param ( @params )
  {
    my $indent = $indent x 2;

    my $value = $self->param($param);

    if (ref $value )
    {
       my $index = 0;
       foreach my $mvalue ( @{$value} )
       {
          $index++;
          $mvalue = _quote_xml($mvalue);
          $items .= qq%$indent<${pref}field name="$param" index="$index">%;
          $items .= "$mvalue</${pref}field>\n";
       }
    }
    else
    {
       $value = _quote_xml($value);
       $items .= qq%$indent<${pref}field name="$param">%;
       $items .= "$value</${pref}field>\n";
    }
  }

  $items = "$indent<${pref}items>\n$items$indent</${pref}items>\n";

  my $ns_att = '';

  
  if ( $ns_url )
  {

    my $prefix_part = '';

    if ($ns_prefix )
    {
       $prefix_part = ":$ns_prefix";
    }
    $ns_att = qq% xmlns$prefix_part="$ns_url"%;
  }

  $xml = "<${pref}form_data$ns_att>\n$info$items</${pref}form_data>\n";

  return $xml;
}

=item ns_prefix

Gets and/or sets the namespace prefix as described as an argument to asXML()
above.

=cut

sub ns_prefix
{
    my ( $self, $ns_prefix ) = @_;

    if ( defined $ns_prefix )
    {
       $self->{_private}->{ns_prefix} = $ns_prefix;
    }
    
    return $self->{_private}->{ns_prefix} || '';
}

=item ns_url

Returns and/or sets the namespace URL for the document as described as an
argument to asXML() above.

=cut

sub ns_url
{
    my ( $self, $ns_url ) = @_;

    if ( defined $ns_url )
    {
       $self->{_private}->{ns_url} = $ns_url;
    }
    
    my $def_url = 'http://schemas.gellyfish.com/FormData';

    return $self->{_private}->{ns_url} || $def_url;

}

=item omit_info

If this is set to a true value then the 'header' information will not be
emitted in the output document.

=cut

sub omit_info
{
    my ( $self, $omit_info ) = @_;

    if ( defined $omit_info )
    {
       $self->{_private}->{omit_info} = $omit_info;
    }

    return $self->{_private}->{omit_info} || 0;

}

=item  destination

This is used to set the value of the 'destination' element in the header
information of the output document.  This may be a URL, email address or
some other identifier. Its content is entirely application specific.

=cut

sub destination
{
    my ( $self, $destination ) = @_;    

    if ( defined $destination )
    {
       $self->{_private}->{destination} = $destination;
    }

    return exists $self->{_private}->{destination} ?
                  $self->{_private}->{destination} : '';
}

=item sess_id

This sets the 'session id' for this CGI request, it is intended to be a
unique identifier for this request and may take the form of a UUID or an
MD5 hash or something similar.  Its use is application specific.

=cut

sub sess_id
{
    my ( $self , $sess_id ) = @_;

    if ( defined $sess_id )
    {
       $self->{_private}->{sess_id} = $sess_id;
    }

    return  exists $self->{_private}->{sess_id} ?
                   $self->{_private}->{sess_id} : '' ;

}

=item owner

This sets the value of the 'owner' element in the header information.  This
is intended to be the e-mail address indicating the contact for this
application.  The usage of this information is application specific.

=cut

sub owner
{
    my ( $self , $owner ) = @_;

    if ( defined $owner )
    {
       $self->{_private}->{owner} = $owner;
    }

    return  exists $self->{_private}->{owner} ?
                   $self->{_private}->{owner} : '' ;

}

sub _quote_xml 
{
    $_[0] =~ s/&/&amp;/g;
    $_[0] =~ s/</&lt;/g;
    $_[0] =~ s/>/&gt;/g;
    $_[0] =~ s/'/&apos;/g;
    $_[0] =~ s/"/&quot;/g;
    $_[0] =~ s/([\x80-\xFF])/&XmlUtf8Encode(ord($1))/ge;
    return($_[0]);
}

# I borrowed this from CGI::XML which in turn said
# borrowed from XML::DOM

sub _xml_utf8_encode 
{
    my ($n) = @_;
    if ($n < 0x80) 
    {
        return chr ($n);
    } 
    elsif ($n < 0x800) 
    {
        return pack ("CC", (($n >> 6) | 0xc0), (($n & 0x3f) | 0x80));
    } 
    elsif ($n < 0x10000) 
    {
        return pack ("CCC", (($n >> 12) | 0xe0), ((($n >> 6) & 0x3f) | 0x80),
                     (($n & 0x3f) | 0x80));
    } 
    elsif ($n < 0x110000) 
    {
        return pack ("CCCC", (($n >> 18) | 0xf0), ((($n >> 12) & 0x3f) | 0x80),
                     ((($n >> 6) & 0x3f) | 0x80), (($n & 0x3f) | 0x80));
    }

    return $n;
}

=back

=cut

1;
__END__

=head1 AUTHOR

    Jonathan Stowe <jns@gellyfish.co.uk>

=head1 COPYRIGHT

This module is free software.  It can be used and distributed under
the same terms as Perl itself.  The Perl license can be found in the
file README in the Perl source distribution.

=head1 SEE ALSO

  CGI::XMLForm,  CGI::XML

=cut
