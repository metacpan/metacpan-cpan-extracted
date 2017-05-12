package Config::DotNetXML::Parser;

use strict;
use warnings;
use XML::XPath;

our $VERSION = '1.6';

=head1 NAME

Config::DotNetXML::Parser - Parse a .NET XML .config file

=head1 SYNOPSIS

use Config::DotNetXML::Parser;

my $parser = Config::DotNetXML::Parser->new(File => $file);

my $config = $parser->data();


=head1 DESCRIPTION

This module implements the parsing for Config::DotNetXML it is designed to
be used by that module but can be used on its own if the import feature is
not required.

The configuration files are XML documents like:

   <configuration>
      <appSettings>
          <add key="msg" value="Bar" />
      </appSettings>
   </configuration>

and the configuration is returned as a hash reference of the <add /> elements
with the key and value attributes providing respectively the key and value
to the hash. 'appSettings' is the default section and is the one that is
exported into your namepace if you asked Config::DotNetXML to do so.

Named sections can also be introduced:

   <configuration>
     <configSections>
        <section name="CustomSection" />
     </configSections>

     <CustomSection>
       <add key="msg" value="Bar" />
     </myCustomSection>
   </configuration>

And the items in the named section can be accessed via the getConfigSection()
method.  Custom sections can appear in the same file as the appSettings default.
It should be noted that single value sections and custom section handlers are
currently not supported. 

=head2 METHODS

=over 2

=cut

=item new

Returns a new Config::DotNetXML::Parser object - it takes parameters in
key => value pairs:

=over 2

=item File

The filename containing the configuration.  If this is supplied then the
configuration will be available via the data() method immediately, otherwise
at the minimum parse() will need to be called first.

=back

=cut

sub new
{
   my ( $class, %Args ) = @_;

   my $self = bless {}, $class;

   $self->parser(XML::XPath->new());

   if ( exists $Args{File} )
   {
      $self->File($Args{File});
   }



   if ( defined $self->File() )
   {
      $self->parse();
   }

   return $self;
}

=item parser

Convenience accessor/mutator for the underlying XML parser.

=cut

sub parser
{
   my ( $self, $parser ) = @_;

   if ( defined $parser )
   {
      $self->{_parser} = $parser;
   }

   return $self->{_parser};
}

=item parse

This causes the configuration file to be parsed, after which the configuration
will be available via the data() method. It can be supplied with an optional
filename which will remove the need to use the File() method previously.

=cut

sub parse
{
   my ( $self, $file ) = @_;

   if ( defined $file )
   {
      $self->File($file);
   }

   my @sections = qw(appSettings);

   my $configs = $self->parser()->find('/configuration/configSections/section');


   my $data = {};

   foreach my $section ( $configs->get_nodelist() )
   {
      push @sections,$section->getAttribute('name');
   }

   foreach my $section ( @sections )
   {
      my $adds = $self->parser()->find("/configuration/$section/add");

      if ( defined $adds )
      {
         foreach my $add ( $adds->get_nodelist() )
         {
            my $key = $add->getAttribute('key');
            my $value =  $add->getAttribute('value');
   
            $data->{$section}->{$key} = $value;
         }
      }
   }  

   $self->configData($data);
}

=item data

Returns parsed data from the default (appSettings) section - this will be 
undefined if parse() has not previously been called or there is no appSettings
section in the configuration.

=cut

sub data
{
   my ( $self,$data ) = @_;
   return $self->getConfigSection('appSettings') || {}; 
}

=item getConfigSection

Returns the named configuration section or a false value if there is no such 
section.

=cut

sub getConfigSection
{
   my ( $self, $section ) = @_;

   return $self->configData()->{$section};
}

=item configData

Accessor/Mutator for the underlying parsed configuration data, you will
almost certainly be accessing the configuration through the methods of
L<Config::DotNetXML> rather than using this directly.

=cut

sub configData
{
    my ( $self, $data ) = @_;

    if ( defined $data )
    {
       $self->{_data} = $data;
    }

    if ( not exists $self->{_data} )
    {
       $self->{_data} = {};
    }

    return $self->{_data};
}

=item File

Returns or sets the name of the file to be parsed for the configuration.

=cut

=back
=cut

sub File
{
    my ( $self , $file ) = @_;

    if ( defined $file )
    {
       $self->parser()->set_filename($file);
    }

    return $self->parser()->get_filename();
}


=head1 BUGS

Those familiar with the .NET Framework will realise that this is not a
complete implementation of all of the facilities offered by the 
System.Configuration class: specifically custom section handlers, and
single value sections - these should come later.

The observant will have noticed that the use of configuration sections 
causes the file not to be strictly valid XML inasmuch as the schema cannot
be defined prior to parsing - this is unfortunately the way that the .NET
framework has it specified, the named sections should probably be dealt with
using a 'name' attribute instead.

=head1 AUTHOR

Jonathan Stowe <jns@gellyfish.co.uk>

=head1 COPYRIGHT

This library is free software - it comes with no warranty whatsoever.

Copyright (c) 2004, 2005, 2016 Jonathan Stowe

This module can be distributed under the same terms as Perl itself.

=cut

1;
