package Config::DotNetXML;

=head1 NAME

Config::DotNetXML - Get config in the manner of .NET Framework

=head1 ABSTRACT

This module allows the transparent import of .NET Framework style config.

=head1 SYNOPSIS

use Config::DotNetXML;

our %appSettings;

my $foo = $appSettings{Foo};

=head1 DESCRIPTION

This module attempts to provide a configuration facility similar to that 
provided by System.Configuration.ConfigurationSettings class in the .NET
framework, the intent is that .NET programs and Perl programs can share the
same configuration file.

When the modules import() method is called (either implicitly via use or
explicitly) it will read and parse and XML file (by default called $0.config)
in the same directory as the script and import the settings specified in
that file into the %appSettings hash in the current package.

The XML file is of the format:

   <configuration>
      <appSettings>
         <add key="msg" value="Bar" />
      </appSettings>
   </configuration>

The E<lt>addE<gt>elements are the ones that contain the configuration, with
the 'key' attribute becoming the key in %appSettings and 'value' becoming
the value.

The default behaviour of the module can be altered by the following parameters
that are supplied via the import list of the module:

=over 2

=item Package

Alter the package into which the settings are imported.  The default is the
package in which C<use Config::DotNetXML> is called.

=item VarName

Use a different name for the variable into which the settings are placed.
The default is C<%appSettings>, the name should not have the type specifier.

=item File

Use a different filename from which to get the settings.  The default is the
program name with '.config' appended.

=item Section

By default the configuration is taken from the 'appSettings' section of the
file - however this can be changed by this parameter. 
See L<Config::DotNetXML::Parser> for details on named sections.

=back

If you don't want or need the import you should use the L<Config::DotNetXML::Parser>
module which is part of this package instead.

=cut

use warnings;
use strict;
use File::Spec;
use Config::DotNetXML::Parser;

BEGIN
{
   delete $INC{'FindBin.pm'};
   require FindBin;
}

our $VERSION = '1.6';

sub import
{

   my ($pkg, %Args ) = @_;

   no strict 'refs';

   my $suffix = '.config';


   my $package;

   if ( exists $Args{Package} )
   {
      $package = $Args{Package};
   }
   else
   {

      if ( ($package = caller(0)) eq 'Test::More')
      {
         $package = caller(1);
      }
   }

   
   my $varname;

   if ( exists $Args{VarName} )
   {
      $varname = $Args{VarName};
   }
   else
   {
      $varname = 'appSettings';
   }

   my $file;

   if ( exists $Args{File} )
   {
      $file = $Args{File};
   }
   else
   {
      $file = File::Spec->catfile($FindBin::Bin,$FindBin::Script) . $suffix;
   }


   my $section = 'appSettings';

   if ( exists $Args{Section} )
   {
      $section = $Args{Section}
   }

   my $parser;

   my $appsettings = {};
   if ( -f $file and -r $file )
   {
      $parser = Config::DotNetXML::Parser->new(File => $file);
      $appsettings = $parser->getConfigSection($section);
   }

   *{"$package\::$varname"} = $appsettings;
}

=head1 BUGS

Those familiar with the .NET Framework will realise that this is not a
complete implementation of all of the facilities offered by the 
System.Configuration class: this will come later.

Some may consider the wanton exporting of names into the calling package
to be a bad thing.

=head1 SEE ALSO

perl, .NET Framework documentation

=head1 AUTHOR

Jonathan Stowe <jns@gellyfish.co.uk>

=head1 COPYRIGHT

This library is free software - it comes with no warranty whatsoever.

Copyright (c) 2004, 2005, 2016 Jonathan Stowe

This module can be distributed under the same terms as Perl itself.

=cut

1;

