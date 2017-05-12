package Astro::SkyX;

use 5.006001;
use strict;
use warnings;
require IO::Socket;
require Scalar::Util;
require Exporter;
require Astro::SkyX::Application;
require Astro::SkyX::AutomatedImageLinkSettings;
require Astro::SkyX::ClosedLoopSlew;
require Astro::SkyX::ImageLinkResults;
require Astro::SkyX::ImageLink;
require Astro::SkyX::OpticalTubeAssembly;
require Astro::SkyX::SelectedHardware;
require Astro::SkyX::WeatherUtil;
require Astro::SkyX::TheSkyXAction;
require Astro::SkyX::ccdsoftCamera;
require Astro::SkyX::ccdsoftCameraImage;
require Astro::SkyX::ccdsoftAutoguiderImage;
require Astro::SkyX::sky6DataWizard;
require Astro::SkyX::sky6DirectGuide;
require Astro::SkyX::sky6Dome;
require Astro::SkyX::sky6MyFOVs;
require Astro::SkyX::sky6ObjectInformation;
require Astro::SkyX::sky6RASCOMTele;
require Astro::SkyX::sky6RASCOMTheSky;
require Astro::SkyX::sky6Raven;
require Astro::SkyX::sky6StarChart;
require Astro::SkyX::sky6TheSky;
require Astro::SkyX::sky6Utils;
require Astro::SkyX::sky6Web;
use constant IGNORECTLC => 0;
use vars qw( $SkyXConnection $error );

our @ISA = qw( Exporter );

our %EXPORT_TAGS = ( 'all' => [ qw(
new connect Send Get
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.11';
 
 my %attr_data = 
     (
       _debug			=> [0,			'read/write'],
     );
 my $count = 0;
 my $select = '';
##---##

  sub new {
    my ($caller, %arg) = @_;
    my $caller_is_obj = ref($caller);
    my $class = $caller_is_obj || $caller;

    my $self = bless {
        _debug          => $arg{"DEBUG"},
        _SkyXConnection			=> $_[2],
	_connect			=> $_[3],
	_Send				=> $_[4],
	_Get				=> $_[5],
        _Application			=> $_[6],
	_AutomatedImageLinkSettings	=> $_[7],
	_ClosedLoopSlew			=> $_[8],
        _ImageLinkResults		=> $_[9],
        _ImageLink			=> $_[10],
	_OpticalTubeAssembly		=> $_[11],
	_SelectedHardware		=> $_[12],
	_WeatherUtil			=> $_[13],
        _TheSkyXAction			=> $_[14],
        _sky6DataWizard			=> $_[15],
        _sky6DirectGuide		=> $_[16],
        _sky6Dome			=> $_[17],
        _sky6MyFOVs			=> $_[18],
        _sky6ObjectInformation		=> $_[19],
        _sky6RASCOMTele			=> $_[20],
        _sky6RASCOMTheSky		=> $_[21],
        _sky6Raven			=> $_[22],
        _sky6StarChart			=> $_[23],
        _sky6TheSky			=> $_[24],
        _sky6Utils			=> $_[25],
        _sky6Web			=> $_[26],
        _ccdsoftCamera  		=> $_[27],
        _ccdsoftCameraImage   		=> $_[28],
        _ccdsoftAutoguiderImage   	=> $_[29],
	}, $class;
    $self->{_Application} = Astro::SkyX::Application::new("Astro::SkyX::Application");
    $self->{_AutomatedImageLinkSettings} = Astro::SkyX::AutomatedImageLinkSettings::new("Astro::SkyX::AutomatedImageLinkSettings");
    $self->{_ClosedLoopSlew} = Astro::SkyX::ClosedLoopSlew::new("Astro::SkyX::ClosedLoopSlew");
    $self->{_ImageLinkResults} = Astro::SkyX::ImageLinkResults::new("Astro::SkyX::ImageLinkResults");
    $self->{_ImageLink} = Astro::SkyX::ImageLink::new("Astro::SkyX::ImageLink");
    $self->{_OpticalTubeAssembly} = Astro::SkyX::OpticalTubeAssembly::new("Astro::SkyX::OpticalTubeAssembly");
    $self->{_SelectedHardware} = Astro::SkyX::SelectedHardware::new("Astro::SkyX::SelectedHardware");
    $self->{_WeatherUtil} = Astro::SkyX::WeatherUtil::new("Astro::SkyX::WeatherUtil");
    $self->{_TheSkyXAction} = Astro::SkyX::TheSkyXAction::new("Astro::SkyX::TheSkyXAction");
    $self->{_sky6DataWizard} = Astro::SkyX::sky6DataWizard::new("Astro::SkyX::sky6DataWizard");
    $self->{_sky6DirectGuide} = Astro::SkyX::sky6DirectGuide::new("Astro::SkyX::sky6DirectGuide");
    $self->{_sky6Dome} = Astro::SkyX::sky6Dome::new("Astro::SkyX::sky6Dome");
    $self->{_sky6MyFOVs} = Astro::SkyX::sky6MyFOVs::new("Astro::SkyX::sky6MyFOVs");
    $self->{_sky6ObjectInformation} = Astro::SkyX::sky6ObjectInformation::new("Astro::SkyX::sky6ObjectInformation");
    $self->{_sky6RASCOMTele} = Astro::SkyX::sky6RASCOMTele::new("Astro::SkyX::sky6RASCOMTele");
    $self->{_sky6RASCOMTheSky} = Astro::SkyX::sky6RASCOMTheSky::new("Astro::SkyX::sky6RASCOMTheSky");
    $self->{_sky6Raven} = Astro::SkyX::sky6Raven::new("Astro::SkyX::sky6Raven");
    $self->{_sky6StarChart} = Astro::SkyX::sky6StarChart::new("Astro::SkyX::sky6StarChart");
    $self->{_sky6TheSky} = Astro::SkyX::sky6TheSky::new("Astro::SkyX::sky6TheSky");
    $self->{_sky6Utils} = Astro::SkyX::sky6Utils::new("Astro::SkyX::sky6Utils");
    $self->{_sky6Web} = Astro::SkyX::sky6Web::new("Astro::SkyX::sky6Web");
    $self->{_ccdsoftCamera} = Astro::SkyX::ccdsoftCamera::new("Astro::SkyX::ccdsoftCamera");
    $self->{_ccdsoftCameraImage} = Astro::SkyX::ccdsoftCameraImage::new("Astro::SkyX::ccdsoftCameraImage");
    $self->{_ccdsoftAutoguiderImage} = Astro::SkyX::ccdsoftAutoguiderImage::new("Astro::SkyX::ccdsoftAutoguiderImage");
    return $self;
  }

  sub Application {
    my $self = shift @_;
    return $self->{_Application};
  }

  sub AutomatedImageLinkSettings {
    my $self = shift @_;
    return $self->{_AutomatedImageLinkSettings};
  }

  sub ClosedLoopSlew {
    my $self = shift @_;
    return $self->{_ClosedLoopSlew};
  }

  sub ImageLinkResults {
    my $self = shift @_;
    return $self->{_ImageLinkResults};
  }

  sub ImageLink {
    my $self = shift @_;
    return $self->{_ImageLink};
  }

  sub OpticalTubeAssembly {
    my $self = shift @_;
    return $self->{_OpticalTubeAssembly};
  }

  sub SelectedHardware {
    my $self = shift @_;
    return $self->{_SelectedHardware};
  }

  sub WeatherUtil {
    my $self = shift @_;
    return $self->{_WeatherUtil};
  }

  sub TheSkyXAction {
    my $self = shift @_;
    return $self->{_TheSkyXAction};
  }

  sub sky6DataWizard {
    my $self = shift @_;
    return $self->{_sky6DataWizard};
  }

  sub sky6DirectGuide {
    my $self = shift @_;
    return $self->{_sky6DirectGuide};
  }

  sub sky6Dome {
    my $self = shift @_;
    return $self->{_sky6Dome};
  }

  sub sky6MyFOVs {
    my $self = shift @_;
    return $self->{_sky6MyFOVs};
  }

  sub sky6ObjectInformation {
    my $self = shift @_;
    return $self->{_sky6ObjectInformation};
  }

  sub sky6RASCOMTele {
    my $self = shift @_;
    return $self->{_sky6RASCOMTele};
  }

  sub sky6RASCOMTheSky {
    my $self = shift @_;
    return $self->{_sky6RASCOMTheSky};
  }

  sub sky6Raven {
    my $self = shift @_;
    return $self->{_sky6Raven};
  }

  sub sky6StarChart {
    my $self = shift @_;
    return $self->{_sky6StarChart};
  }

  sub sky6TheSky {
    my $self = shift @_;
    return $self->{_sky6TheSky};
  }

  sub sky6Utils {
    my $self = shift @_;
    return $self->{_sky6Utils};
  }

  sub sky6Web {
    my $self = shift @_;
    return $self->{_sky6Web};
  }

  sub ccdsoftCamera {
    my $self = shift @_;
    return $self->{_ccdsoftCamera};
  }

  sub ccdsoftCameraImage {
    my $self = shift @_;
    return $self->{_ccdsoftCameraImage};
  }

  sub ccdsoftAutoguiderImage {
    my $self = shift @_;
    return $self->{_ccdsoftAutoguiderImage};
  }

  sub connect {
    my ($obj,$destinationIP,$destinationPort) = @_;
    $SkyXConnection = IO::Socket::INET->new (
                                PeerAddr => $destinationIP,
                                PeerPort => $destinationPort,
                                Blocking => 0,
				autoflush => 1,
                                Proto => 'tcp',
                                Timeout => "300",
                        );
    if ( ! Scalar::Util::openhandle($SkyXConnection ) ){
      die "Unable to connect to The Sky X\n";
    }
    $SkyXConnection->autoflush(1);

    select $SkyXConnection;
    $| = 1;
    $select = IO::Select->new();
    $select->add($SkyXConnection); 
    select STDOUT;
    return 0 unless $SkyXConnection;
    return $SkyXConnection;
  }

  sub Send {
   my $signal = $SIG{INT};
   if ( IGNORECTLC ){
     $SIG{INT} = 'IGNORE';
   }
   my ($self,$sendtext) = @_;
   $sendtext =~ s/\\/\\\\/g;
   print $SkyXConnection "$sendtext\r\n";
#   print "Sending...\n$sendtext\n";
   $SkyXConnection->flush;
   $SIG{INT} = $signal;
  }

  sub Get {
    my $signal = $SIG{INT};
    if ( IGNORECTLC ){
      $SIG{INT} = 'IGNORE';
    }
    my ($self) = @_;
    my $output = undef;
    $error = "";
    while ( ! defined($output) or ($output !~ /[|].*Error = .*\./) ) {
      while ( my @read_from = $select->can_read(0) ) {
          my $data = '';
          $read_from[0]->recv($data,1024);
          $output .= $data if $data;
      }
    }
    ($output,$error) = split(/\|([^|]+)$/,$output);
    $SIG{INT} = $signal;
    return ($output);
  }

  sub getError {
    return ($error);
  }

  sub Wait {
    my ($waitsecs) = @_;
    select(undef,undef,undef,$waitsecs);
  }




1;

__END__

=head1 NAME

Astro::SkyX - Perl extension for communications with The SkyX Scripting Engine Version 10.2.0 (Build 6519 and later).
This module converts perl object oriented function calls to java script objects supported by The SkyX.

=head1 SYNOPSIS

  use Astro::SkyX;
  my $obj = Astro::SkyX->new();
  #connect to SkyX program:
  $Skysock = $obj->connect('localhost','3040');
  #Connect to Telescope, unpark and find home:
  $obj->sky6RASCOMTele->Connect();
  $obj->Wait(60); # Wait 60 seconds before continuing.
  $obj->sky6RASCOMTele->Unpark();
  print "Finding Home...\n";
  $obj->sky6RASCOMTele->FindHome();
  print "Home.\n";


=head1 DESCRIPTION

  The SkyX perl module allows a programmer to interact with the
SkyX scripting engine. Syntax is very close to the Java script
syntax documented in the Software Bisque Script TheSkyX Documentation.

Example:

  /* Java Script */
  sky6RASCOMTele.Connect();

  becomes

  $obj->sky6RASCOMTele->Connect();

  The return value is the output from the Java Script engine in The SkyX.

  Reading properties is similiar:

  $obj->sky6RASCOMTele->GetAzAlt();
  print "Alt is " . $obj->sky6RASCOMTele->dAlt . "\n";;
  print "Az is " . $obj->sky6RASCOMTele->dAz . "\n";;

  Setting property values are a little different than the java script method. Instead of:

  ImageLink.scale = .84;

  use:

  $obj->ImageLink->scale(.84); 

  That simple...

 
=head2 EXPORT

None by default.

=head1 SEE ALSO

There is class specific documentation for any odd things that had to
be kludged. perldoc Astro::SkyX::Classname to see it.

Don't forget ScriptTheSkyX documentation from Software Bisque.

=head1 AUTHOR

Robert Woodard, E<lt>kayak.man@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Robert Woodard

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.

There are restrictions on commercial use of the SkyX scripting engine.
Please see the Software Bisque End User License Agreement prior to
using this module in a commercial setting.

=cut
