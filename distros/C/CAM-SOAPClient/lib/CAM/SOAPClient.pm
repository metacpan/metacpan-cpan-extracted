package CAM::SOAPClient;

require 5.005_62;
use strict;
use warnings;
use SOAP::Lite;

our $VERSION = '1.17';

=for stopwords Lapworth subclassable wsdl

=head1 NAME

CAM::SOAPClient - SOAP interaction tools

=head1 LICENSE

Copyright 2006 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

  use CAM::SOAPClient;
  my $client = CAM::SOAPClient->new(wsdl => 'http://www.clotho.com/staff.wsdl');
  my ($fname, $lname) = $client->call('fetchEmployee', '[firstName,lastName]',
                                      ssn => '000-00-0000');
  my $record = $client->call('fetchEmployee', undef, ssn => '000-00-0000');
  my @addresses = $client->call('allEmployees', '@email');
  
  my $firstbudget = $client->call('listClientProjects', 
                                  '/client/projects/project/budget');
  
  if ($client->hadFault()) {
     die 'SOAP Fault: ' . $client->getLastFaultString();
  }

=head1 DESCRIPTION

This module offers some basic tools to simplify the creation of SOAP
client implementations.  It is intended to be subclassable, but works
fine as-is too.

The purpose for this module is to abstract the complexity of
SOAP::Lite.  That module makes easy things really easy and hard things
possible, but quite obscure.  The problem is that the easy things are
often too basic.  For example, calling remote methods with positional
arguments is easy, but with named arguments is much harder.  Calling
methods on a SOAP::Lite server is easy, but an Apache Axis server is
much harder.  This module attempts to make typical SOAP and WSDL activities
easier by hiding some of the weirdness of SOAP::Lite.

The main method is call(), via which you can specify what remote
method to invoke, what return values you want, and the named arguments
you want to pass.  See below for more detail.

This package has been tested against servers running SOAP::Lite,
Apache Axis, and PEAR SOAP.

=head1 SEE ALSO

L<SOAP::Lite::Simple> is another module with very similar goals to
this one.  Leo Lapworth, the author of that module, and I have briefly
discussed merging the work into a single package, but have not made
much progress.  If any users are interested in such a merger, let us know.

=head1 METHODS

=over

=item $pkg->new([opts], $uri)

=item $pkg->new([opts], $uri, $proxy)

=item $pkg->new([opts], $uri, $proxy, $username, $password)

=item $pkg->new([opts], wsdl => $url)

=item $pkg->new([opts], wsdl => $url, $username, $password)

Create a connection instance.  The C<$proxy> is not required here, but
if not specified it must be set later via C<setProxy()>.  Optionally
(and recommended) you can specify a WSDL C<$url> instead of a C<$uri> and
C<$proxy>.

If a C<$username> is specified, then the C<$username> and C<$password>
are simply passed to C<setUserPass()>.

The options are as follows:

=over

=item timeout => $seconds

This defaults to 6 hours.

=back

=cut

sub new
{
   my $pkg = shift;
   my %cfg = (
              timeout => 6*60*60, # 6 hours
              );
   while (@_ > 0)
   {
      if ($_[0] eq 'timeout')
      {
         my $key = shift;
         my $val = shift;
         $cfg{$key} = $val;
      }
      else
      {
         last;
      }
   }

   my $uri = shift;
   my $proxy = shift;
   my $user = shift;
   my $pass = shift;

   return if (!$uri);

   my $soap = SOAP::Lite  -> on_fault( sub {} );
   my $self = bless {
      %cfg,
      services => {},
      soap => $soap,
      auth => {},
      global_proxy => undef,
      global_uri => undef,
      proxies => {},
      uris => {},
   }, $pkg;

   if ($uri eq 'wsdl')
   {
      $self->setWSDL($proxy);
   }
   else
   {
      $self->setURI($uri);
      if ($proxy)
      {
         $self->setProxy($proxy);
      }
   }

   if ($user)
   {
      $self->setUserPass($user, $pass);
   }
   return $self;
}

=item $self->setWSDL($url)

Loads a Web Service Description Language file describing the SOAP service.

=cut

sub setWSDL
{
   my $self = shift;
   my $url = shift;
   
   # The SOAP::Schema API changed as of SOAP::Lite v0.65-beta2
   my $schema = SOAP::Schema->can('schema_url') ?
       SOAP::Schema->schema_url($url) :
       SOAP::Schema->schema($url);
   my $services = $schema->parse()->services();
   #use Data::Dumper; print STDERR Dumper($services);

   foreach my $class (values %{$services})
   {
      foreach my $method (keys %{$class})
      {
         my $endpoint = $class->{$method}->{endpoint};
         # 'uri' was used thru SOAP::Lite v0.60, 'namespace' is used in v0.65+
         my $namespace = $class->{$method}->{uri} ? $class->{$method}->{uri}->value() : $class->{$method}->{namespace};
         $self->{proxies}->{$method} = $endpoint ? $endpoint->value() : undef;
         $self->{uris}->{$method} = $namespace;
      }
   }

   return $self;
}

=item $self->setURI($uri)

Specifies the URI for the SOAP server.  This is not needed if you are
using WSDL.

=cut

sub setURI
{
   my $self = shift;
   my $uri = shift;

   $self->{global_uri} = $uri;
   return $self;
}

=item $self->setProxy($proxy)

Specifies the URL for the SOAP server.  This is not needed if you are
using WSDL.

=cut

sub setProxy
{
   my $self = shift;
   my $proxy = shift;

   $self->{global_proxy} = $proxy;
   return $self;
}

=item $self->setUserPass($username, $password)

Specifies the C<$username> and C<$password> to use on the SOAP server.
These values are stored until used via loginParams().  Most
applications won't use this method.

=cut

sub setUserPass
{
   my $self = shift;
   my $username = shift;
   my $password = shift;

   $self->{auth}->{username} = $username;
   $self->{auth}->{password} = $password;
   return $self;
}

=item $self->getLastSOM()

Returns the SOAP::SOM object for the last query.

=cut

sub getLastSOM
{
   my $self = shift;

   return $self->{last_som};
}

=item $self->hadFault()

Returns a boolean indicating whether the last call() resulted in a fault.

=cut

sub hadFault
{
   my $self = shift;

   my $som = $self->getLastSOM();
   return $som && (ref $som) && $som->fault();
}

=item $self->getLastFaultCode()

Returns the fault code from the last query, or C<(none)> if the last
query did not result in a fault.

=cut

sub getLastFaultCode
{
   my $self = shift;

   my $som = $self->getLastSOM();
   if ($som && (ref $som) && $som->can('faultcode') && $som->fault())
   {
      return $som->faultcode();
   }
   else
   {
      return '(none)';
   }
}

=item $self->getLastFaultString()

Returns the fault string from the last query, or C<(none)> if the last
query did not result in a fault.

=cut

sub getLastFaultString
{
   my $self = shift;

   my $som = $self->getLastSOM();
   if ($som && (ref $som) && $som->can('faultstring') && $som->fault())
   {
      return $som->faultstring();
   }
   else
   {
      return '(none)';
   }
}

=item $self->getLastFault()

Creates a new SOAP::Fault instance from the last fault data, if any.  If
there was no fault (as per the hadFault() method) then this returns
undef.

=cut

sub getLastFault
{
   my $self = shift;

   return if (!$self->hadFault());

   my $som = $self->getLastSOM();
   return if (!$som || !(ref $som) || !$som->fault());

   my $code   = $som->can('faultcode')   ? $som->faultcode()   : 'Unknown';
   my $string = $som->can('faultstring') ? $som->faultstring() : 'An unknown error has occurred';
   my $detail = $som->can('faultdetail') ? $som->faultdetail() : undef;
   if ($detail)
   {
      $detail = $detail->{data};
   }

   my $fault = SOAP::Fault->new(
      faultcode   => $code,
      faultstring => $string,
      ($detail ? (faultdetail => SOAP::Data->name('data' => $detail)) : ()),
   );
   return $fault;
}


=item $self->call($method, undef, $key1 => $value1, $key2 => $value, ...)

=item $self->call($method, $xpath, $key1 => $value1, $key2 => $value, ...)

=item $self->call($method, $xpath_arrayref, $key1 => $value1, $key2 => $value, ...)

Invoke the named SOAP method.  The return values are indicated in the
second argument, which can be undef, a single scalar or a list of
return fields.  If this path is undef, then all data are returned as
if the SOAP C<paramsout()> method was called.  Otherwise, the SOAP
response is searched for these values.  If any of them are missing,
call() returns undef.  If multiple values are specified, they are all
returned in array context, while just the first one is returned in
scalar context. This is best explained by examples:

    'documentID' 
           returns 
        /Envelope/Body/<method>/documentID

    ['documentID', 'data/[2]/type', '//result']
           returns
       (/Envelope/Body/<method>/documentID,
        /Envelope/Body/<method>/data/[2]/type,
        /Envelope/Body/<method>/*/result)
           or
        /Envelope/Body/<method>/documentID
           in scalar context

If the path matches multiple fields, just the first is returned.
Alternatively, if the path is prefixed by a C<@> character, it is
expected that the path will match multiple fields.  If there is just
one path, the matches are returned as an array (just the first one in
scalar context).  If there are multiple paths specified, then the
matches are returned as an array reference.  For example, imagine a
query that returns a list of documents with IDs 4,6,7,10,20 for user
#12.  Here we detail the return values for the following paths:

  path: 'documents/item/id' or ['documents/item/id']
      returns
   array context: (4)
  scalar context: 4
  
  path: '@documents/item/id' or ['@documents/item/id']
      returns
   array context: (4,6,7,10,20)
  scalar context: 4
  
  path: ['documents/item/id', 'userID']
      returns
   array context: (4, 12)
  scalar context: 4
  
  path: ['@documents/item/id', 'userID']
      returns
   array context: ([4,6,7,10,20], 12)
  scalar context: [4,6,7,10,20]
  
  path: ['userID', '@documents/item/id']
      returns
   array context: (12, [4,6,7,10,20])
  scalar context: 12

=cut

sub call
{
   my $self = shift;
   my $method = shift;
   my $paths = shift;
   my @args = @_;

   my @rets;

   if ($paths && !ref $paths)
   {
      $paths = [$paths];
   }

   my $uri = $self->{uris}->{$method} || $self->{global_uri};
   my $proxy = $self->{proxies}->{$method} || $self->{global_proxy};
   if (!$uri || !$proxy)
   {
      # Create a minimal SOAP fault from scratch
      $self->_setFault('Client',
                       "Attempted to call method '$method' which lacks a URI or proxy.  Are you sure you called the right method?");
      return;
   }
   
   my $soap = SOAP::Lite->can('ns') ? $self->{soap}->ns($uri) : $self->{soap}->uri($uri);
   my $som = $soap
       ->proxy($proxy,
               ($self->{timeout} ? 
                (timeout => $self->{timeout}) : ())
              )
       ->call($method, $self->request($self->loginParams(), @args));

   if (!$som || !ref $som)
   {
      $self->_setFault('Client', 'Communication failure');
      return;
   }

   $self->{last_som} = $som;

   if ($som->fault)
   {
      return;
   }

   if (!defined $paths)
   {
      @rets = ($som->match('/Envelope/Body/[1]')->valueof());
   }
   else
   {
      foreach my $origpath (@{$paths})
      {
         my $path = $origpath;
         my $is_array = ($path =~ s/\A\@//xms);
         
         return if (!$som->match("/Envelope/Body/[1]/$path"));
         my @values = $som->valueof();
         if ($is_array)
         {
            if (@{$paths} == 1)
            {
               push @rets, @values;
            }
            else
            {
               push @rets, [@values];
            }
         }
         else
         {
            push @rets, $values[0];
         }
      }
   }
   return wantarray ? @rets : $rets[0];
}


sub _setFault
{
   my $self   = shift;
   my $code   = shift;
   my $string = shift;

   $self->{last_som} = SOAP::Deserializer->deserialize(<<"EOF"
<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
 <Body>
  <Fault>
   <faultcode>$code</faultcode>
   <faultstring>$string</faultstring>
  </Fault>
 </Body>
</Envelope>
EOF
   );
   return $self;
}

=item $self->loginParams()

This is intended to return a hash of all the required parameters shared
by all SOAP requests.  This version returns the contents of
C<%{$soap->{auth}}>.  Some subclasses may wish to override this, while
others may wish to simply add more to that hash.

=cut

sub loginParams
{
   my $self = shift;
   return (%{$self->{auth}});
}

=item $self->request($key1 => $value1, $key2 => $value2, ...)

=item $self->request($soapdata1, $soapdata2, ...)

Helper routine which wraps its key-value pair arguments in SOAP::Data
objects, if they are not already in that form.

=cut

sub request
{
   my $pkg_or_self = shift;
   # other args below

   my @return;
   while (@_ > 0)
   {
      my $var = shift;
      if ($var && (ref $var) && (ref $var) eq 'SOAP::Data')
      {
         push @return, $var;
      }
      else
      {
         push @return, SOAP::Data->name($var, shift);
      }
   }
   return @return;
}

1;
__END__

=back

=head1 SEE ALSO

SOAP::Lite

CAM::SOAPApp

=head1 CODING

This module has over 80% code coverage in its regression tests, as
reported by L<Devel::Cover> via C<perl Build testcover>.

With three policy exceptions, this module passes Perl Best Practices
guidelines, as enforced by L<Perl::Critic> v0.13.

=head1 AUTHOR

Clotho Advanced Media, I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut
