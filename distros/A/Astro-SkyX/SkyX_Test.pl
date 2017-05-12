#!/usr/bin/perl -w
# Completed Module Tests. Not everything has been tested
# because I'm lazy.
# TheSkyX Objects
# Astro::SkyX::Application
# Astro::SkyX::ImageLink
# Astro::SkyX::ImageLinkResults
# Astro::SkyX::TheSkyXAction
#
# TheSky6 Classic Objects
# Astro::SkyX::sky6ObjectInformation
# Astro::SkyX::sky6DataWizard (Can run Query but not access data)
# Astro::SkyX::sky6DirectGuide
# Astro::SkyX::sky6MyFOVs
# Astro::SkyX::sky6RASCOMTheSky
# Astro::SkyX::sky6RASCOMTele
# Astro::SkyX::sky6Web

#
# CCDSoft Classic Objects
# Astro::SkyX::ccdsoftCamera

#
# Still need tests for:
# Astro::SkyX::sky6StarChart
# Astro::SkyX::sky6Utils
# Astro::SkyX::ccdsoftCameraImage
# Astro::SkyX::ccdsoftAutoguiderImage
#
# Modules I can't test:
# Astro::SkyX::sky6Dome (No Dome license)
# Astro::SkyX::sky6Raven (No Dome license)
# Astro::SkyX::sky6TheSky - This object has been depricated so not tested.

# Used for testing
#BEGIN { push @INC, "/path/to/SkyXPro/module" }
#
# Use the SkyX perl module
use Astro::SkyX;
# Global variables
use vars qw( $SX $Skysock $output $error $target );
#
$| = 1;
my $movetests = 0;
my $answer = '';
my $slewtarget = '';
print "\n\nWARNING: Executing module fuctions that move the telescope\n";
print "         can result in damage to your telescope, mount, and accessories.\n";
print "         Make sure your telescope is clear of obstructions, you pick\n";
print "         a safe slew target and your observatory roof is open!\n";
print "\n\n To execute move telescope functions you must type YES at the\n";
print "prompt: ";
chomp ($answer = <>);
if ( $answer eq 'YES' ) {
  $movetests = 1;
}
print "\n\n  Enter a safe target (slew and info tests): ";
chomp ($slewtarget = <>);
if ( !$slewtarget ){
  print "\n Exiting. No target selected\n";
  exit;
}

########## Initialize the module and connect to TheSkyX ############

#change to IP if across network
initSX('localhost');
#initSX('192.168.3.12');

####################################################################
# This tests the raw Send/Get methods to send raw java script      #
####################################################################

testSendGet();
####################################################################
# Is SkyX initialized? What version? This fully tests              #
# the Astro::SkyX::Application module                              #
####################################################################

testApplication();
# Print out error from the last command if there was one.
  print "  SkyX module query to see if there was an error on the last command:\n";
  print "  " . $SX->getError() . "\n";

####################################################################
# Test TheSkyXAction class module. Fully tests the                 #
# Astro::SkyX::TheSkyXAction module.                               #
####################################################################

testTheSkyXAction();

####################################################################
# Tests for Astro::SkyX::sky6ObjectInformation module.             #
####################################################################

testsky6ObjectInformation("$slewtarget");

####################################################################
# Tests for Astro::SkyX::sky6DataWizard module.                    #
####################################################################

# Query will run, but unsure how to access the results.

testsky6DataWizard("Objects on Virtual Sky.dbq");

####################################################################
# Tests for Astro::SkyX::sky6MyFOVs module.                        #
####################################################################

# WARNING: Do not have FOV's with single ticks (') in the name.
 
testsky6MyFOVs();

####################################################################
# Test Astro::SkyX::sky6RASCOMTheSky module                        #
# Only testing non-superceded methods                              #
####################################################################

testsky6RASCOMTheSky();

####################################################################
# Tests for Astro::SkyX::sky6RASCOMTele module.                    #
####################################################################

if ( $movetests ) {
  testsky6RASCOMTele("$slewtarget");
}else{
  print "sky6RASCOMTele  not tested because of potential telescope movement.\n";
}

####################################################################
# Tests for Astro::SkyX::sky6DirectGuide module.                    #
####################################################################

if ( $movetests ) {
  testsky6DirectGuide();
}else{
  print "sky6DirectGuide not tested because of potential telescope movement.\n";
}

####################################################################
# Tests for Astro::SkyX::sky6Web module.                           #
####################################################################

# WARNING: Set a target that is not outside telescope limits

if ( $movetests ) {
  testsky6Web("$slewtarget");
}else{
  print "sky6Web not tested because of potential telescope movement.\n";
}

####################################################################
# Tests for Astro::SkyX::ccdsoftCamera module.                     #
####################################################################

testccdsoftCamera();

####################################################################
# Test Image linking.                                              #
# Fully tests the Astro::SkyX::ImageLink module.                   #
####################################################################

# If I wasn't so lazy I would grab a DSS image first and
# image link that...
# testImageLink(pathtoFITS,imagescale,unknownscale)
my $DSSimage = $SX->ccdsoftCamera->LastImageFileName;
#testImageLink($DSSimage,1.70,1); 
testImageLink('C:\Users\Woody\Desktop\test.fit',.47,1); 
# testImageLink('/Users/woody/Desktop/test.fits',1.48,0); # Mac OSX

####################################################################
# Test ImageLinkResults class module. Fully tests the              #
# Astro::SkyX::ImageLinkResults module.                            #
####################################################################

testImageLinkResults();

####################################################################
# Tests for Astro::SkyX::ccdsoftCameraImage module.                      #
####################################################################

testccdsoftCameraImage($DSSimage);
#testccdsoftCameraImage('C:\Users\Woody\Desktop\test.fits');

# Turn tracking off and disconnect all

 $SX->sky6RASCOMTele->SetTracking(0,1,0,0);
 $SX->ccdsoftCamera->focDisconnect();
 $SX->ccdsoftCamera->Disconnect();

# $SX->sky6RASCOMTele->Disconnect();
 $SX->sky6RASCOMTheSky->DisconnectTelescope();

exit;

#######################################################



sub initSX {
  my $ipaddr = shift;
# Establish new object
  $SX = Astro::SkyX->new();
# Connect using IP/hostname and port number
  $Skysock = $SX->connect($ipaddr,'3040');
#   $Skysock = $SX->connect('localhost','3040');
}

sub testSendGet {
  print "Testing Send/Get routines.\n";
  my $aa='';
  my $javastring = ' /* Java Script */
 /*   Find.js */
var Out;
var PropCnt = 189;
var p;

Out="";
sky6StarChart.Find("Saturn");

for (p=0;p<PropCnt;++p)
{
   if (sky6ObjectInformation.PropertyApplies(p) != 0)
	{
		/*Latch the property into ObjInfoPropOut*/
      sky6ObjectInformation.Property(p);
      Out += sky6ObjectInformation.ObjInfoPropOut + "|";
   }
}';

  $SX->Send($javastring);
  $aa = $SX->Get();
  print "\n  Returning:\n$aa\n\n";    
  print "Finished testing SendGet.\n";
}

sub testApplication {
  print "Testing 100% of the Application module.\n";
  print "\nSkyX Initialized status: ",
    $SX->Application->initialized,
    "\nRunning version: ",
    $SX->Application->version,
    " Build " . $SX->Application->build,
    " on OS: " . $SX->Application->operatingSystem,
    "\n";
  print "Finished testing Application module.\n";
  sleep 1;
}

sub testTheSkyXAction {
  print "Testing 100% of the TheSkyXAction module.\n";
# Need to set a target for some of these commands
  $SX->sky6StarChart->Find("$slewtarget");
  print "ZOOM_IN\n";
  $SX->TheSkyXAction->execute("ZOOM_IN");
  sleep 1;
  print "ZOOM_OUT\n";
  $SX->TheSkyXAction->execute("ZOOM_OUT");
  sleep 1;
  print "MOVE_RIGHT\n";
  $SX->TheSkyXAction->execute("MOVE_RIGHT");
  sleep 1;
  print "MOVE_LEFT\n";
  $SX->TheSkyXAction->execute("MOVE_LEFT");
  sleep 1;
  print "MOVE_UP\n";
  $SX->TheSkyXAction->execute("MOVE_UP");
  sleep 1;
  print "MOVE_DOWN\n";
  $SX->TheSkyXAction->execute("MOVE_DOWN");
  sleep 1;
# TELE_CENTER_CROSS_HAIRS requires connection to telescope, 
# and must be disconnected to use the TIMESKIP commands
# Since these commands do not move the telescope, it is safe
# to connect.
  if (!$SX->sky6RASCOMTele->IsConnected) { 
    print "  Connecting to Telescope. \n";
    $SX->sky6RASCOMTele->Connect();
  }else{
    print "  Already connected to Telescope. \n";
  }
  print "TELE_CENTER_CROSS_HAIRS\n";
  $SX->TheSkyXAction->execute("TELE_CENTER_CROSS_HAIRS");
  sleep 1;
  print "TARGET_LOCK_ON\n";
  $SX->TheSkyXAction->execute("TARGET_LOCK_ON");
  sleep 1;
  print "TARGET_CENTER\n";
  $SX->TheSkyXAction->execute("TARGET_CENTER");
  sleep 1;
  print "TARGET_FRAME\n";
  $SX->TheSkyXAction->execute("TARGET_FRAME");
  sleep 1;

  if ($SX->sky6RASCOMTele->IsConnected) { 
    print "  Disconnecting from Telescope. \n";
    $SX->sky6RASCOMTele->SetTracking(0,1,0,0);
    $SX->sky6RASCOMTheSky->DisconnectTelescope();
  }else{
    print "  Already disconnected to Telescope. \n";
  }
  print "TIMESKIP_GOFWD\n";
  $SX->TheSkyXAction->execute("TIMESKIP_GOFWD");
  sleep 1;
  print "TIMESKIP_GOBACK\n";
  $SX->TheSkyXAction->execute("TIMESKIP_GOBACK");
  sleep 1;
  print "TIMESKIP_STEPFWD\n";
  $SX->TheSkyXAction->execute("TIMESKIP_STEPFWD");
  sleep 1;
  print "TIMESKIP_STEPBACK\n";
  $SX->TheSkyXAction->execute("TIMESKIP_STEPBACK");
  sleep 1;
  print "TIMESKIP_STOP\n";
  $SX->TheSkyXAction->execute("TIMESKIP_STOP");
  sleep 1;
  print "TIMESKIP_USECOMPUTERCLOCK\n";
  $SX->TheSkyXAction->execute("TIMESKIP_USECOMPUTERCLOCK");
  sleep 1;
  print "Finished testing TheSkyXAction module.\n";
  sleep 1;
}

sub testImageLink {
  print "Testing 100% of ImageLink module.\n";
  my $image = shift;
  my $scale = shift;
  my $unknownscale = shift;
  $SX->ImageLink->pathToFITS($image);
  print "pathToFits set to " . $SX->ImageLink->pathToFITS . "\n";
  $SX->ImageLink->scale($scale);
  print "scale set to " . $SX->ImageLink->scale . "\n";
  $SX->ImageLink->unknownScale($unknownscale);
  print "unknownScale set to " . $SX->ImageLink->unknownScale . "\n";
  print "Executing ImageLink: ";
  $SX->ImageLink->execute();
  print "Finished testing ImageLink module.\n";
  sleep 1;
}

sub testImageLinkResults {
  print "Testing 100% of ImageLinkResults module.\n";
  if ($SX->ImageLinkResults->succeeded){
    print "Sucess!\n";
    print "ImageScale: " . $SX->ImageLinkResults->imageScale . "\n";
    print "PositionAngle: " . $SX->ImageLinkResults->imagePositionAngle . "\n";
    print "CenterRAJ2000: " . $SX->ImageLinkResults->imageCenterRAJ2000 . "\n";
    print "CenterDecJ2000: " . $SX->ImageLinkResults->imageCenterDecJ2000 . "\n";
    print "imageWidthInPixels: " . $SX->ImageLinkResults->imageWidthInPixels . "\n";
    print "imageHeightInPixels: " . $SX->ImageLinkResults->imageHeightInPixels . "\n";
    print "imageIsMirrored: " . $SX->ImageLinkResults->imageIsMirrored . "\n";
    print "imageFilePath: " . $SX->ImageLinkResults->imageFilePath . "\n";
    print "imageStarCount: " . $SX->ImageLinkResults->imageStarCount . "\n";
    print "imageFWHMinArcSeconds: " . $SX->ImageLinkResults->imageFWHMinArcSeconds . "\n";
    print "solutionRMS: " . $SX->ImageLinkResults->solutionRMS . "\n";
    print "solutionRMSX: " . $SX->ImageLinkResults->solutionRMSX . "\n";
    print "solutionRMSY: " . $SX->ImageLinkResults->solutionRMSY . "\n";
    print "solutionStarCount: " . $SX->ImageLinkResults->solutionStarCount . "\n";
    print "catalogStarCount: " . $SX->ImageLinkResults->catalogStarCount . "\n";
  }else{
    print "Failed!\n";
    print "errorCode: " . $SX->ImageLinkResults->errorCode . "\n";
    print "errorText: " . $SX->ImageLinkResults->errorText . "\n";
    print "searchAborted: " . $SX->ImageLinkResults->searchAborted . "\n";
  }
  print "Finished testing ImageLinkResults module.\n";
  sleep 1;
}

sub testsky6ObjectInformation {
  print "Testing sky6ObjectInformation module.\n";
  my $target = shift;
  my $PropCnt = 197;
  my $p;
  my $i;
  print "Finding $target...\n";
  $SX->sky6StarChart->Find($target);
# Full checkout of Astro::SkyX::sky6ObjectInformation module.
  for ( $i = 0; $i < $SX->sky6ObjectInformation->Count; $i++ ) {
    $SX->sky6ObjectInformation->Index($i);
    for ( $p = 0; $p <= $PropCnt; $p++) {
      next if $p == 11;
      if ( $SX->sky6ObjectInformation->PropertyApplies($p) ) {
        #Latch the property into ObjInfoPropOut
        $SX->sky6ObjectInformation->PropertyName($p);
        my $value = $SX->sky6ObjectInformation->ObjInfoPropOut . ": ";
        $SX->sky6ObjectInformation->Property($p);
        print $p . " - " . $SX->sky6ObjectInformation->Index . " - " . $value . $SX->sky6ObjectInformation->ObjInfoPropOut . "\n";
      }
    }
  }
  print "Finished testing sky6ObjectInformation module.\n";
  sleep 1;
}

sub testsky6DataWizard{
  print "Testing sky6DataWizard module.\n";
  my $target = shift;
  $SX->sky6DataWizard->Path("$target");
  $SX->sky6DataWizard->Open();
  print "sky6DataWizardPath set to : " . $SX->sky6DataWizard->Path() . "\n";
  my $Result = $SX->sky6DataWizard->RunQuery;
  print "Query of sky6DataWizard complete.\n";
  sleep 1;
}

sub testsky6DirectGuide {
  print "Testing 100% of sky6DirectGuide module.\n";
  $SX->sky6DirectGuide->IAsynchronous(0);
  print "  IAsynchronous set to: " . $SX->sky6DirectGuide->IAsynchronous . "\n";
  $SX->sky6DirectGuide->MoveTelescope(900,900);
  print "Finished testing sky6DirectGuide module.\n";
  sleep 1;
}

sub testsky6MyFOVs {

  print "Testing sky6MyFOVs module.\n";

  my $PropCnt = 5;
  my $p;
  my $i;
  for ( $i = 0; $i < $SX->sky6MyFOVs->Count; ++$i ) {
    $SX->sky6MyFOVs->Name($i);
    my $FOVName = $SX->sky6MyFOVs->OutString;
    print "FOV Name: " . $FOVName . "\n";
    for ( $p = 0; $p <= $PropCnt; ++$p) {
        $SX->sky6MyFOVs->Property($FOVName,0,$p);
        print "  Property Value $p: " . $SX->sky6MyFOVs->OutVar . "\n";
    }
  }
  print "Finished testing sky6MyFOVs module.\n";
  sleep 1;
}

sub testsky6RASCOMTheSky {

  print "Testing sky6RASCOMTheSky module.\n";

# Testing only non-superceded functions not replaced in other modules

# AutoMap() - Not tested - I'm too lazy
#  print "Add AutoMap entry\n";
#  $SX->sky6RASCOMTheSky->AutoMap();
 
# ConnectDome - No dome license. Not tested.
# CoupleDome - No dome license. Not tested.

# DisconnectTelescope
  $SX->sky6RASCOMTheSky->DisconnectTelescope();

# DisconnectDome - No dome license. Not tested.

#  Quit - Tested, but commented out to keep SkyX from exiting
#  print "Finished. Shutting down.\n";
#  $SX->sky6RASCOMTheSky->Quit();

  print "Finished testing sky6RASCOMTheSky module.\n";
  sleep 1;
}

sub testsky6RASCOMTele {
  my $target = shift;
  print "Testing sky6RASCOMTele module.\n";

#  Abort() - Not tested
#  CommutateMotors - Not tested.
  print "  Connecting to mount, Set Asynchronous mode off, and Unpark\n";
  $SX->sky6RASCOMTele->Connect();
  if ($SX->sky6RASCOMTele->IsConnected) { 
    print "  Connected to Telescope. \n";
  }else{
    print "  Did not connect to Telescope! \n";
  }
  $SX->sky6RASCOMTele->Asynchronous(0);
  $SX->sky6RASCOMTele->Unpark();
# DoCommand() - Not tested (I have a paramount)
  print "  Testing FindHome\n";
  $SX->sky6RASCOMTele->FindHome();
  print "  Home.\n";
  sleep 1; # Needed on some systems if issuing a slew
           # command immediatly after FindHome()
# Connect and move focuser
  print "  Connecting to Focuser\n";
  $SX->ccdsoftCamera->focConnect();
  print "  Moving Focuser\n";
  $SX->sky6RASCOMTele->FocusOutFast();
  sleep 10;
  $SX->sky6RASCOMTele->FocusInFast();
  sleep 10;
  $SX->sky6RASCOMTele->FocusOutSlow();
  sleep 10;
  $SX->sky6RASCOMTele->FocusInSlow();
  sleep 10;
  print "  Finished Focuser In/Out/Fast/Slow\n";
# populate dAlt,dAz,dRa, and dDec and display them
  print "  Slewing to $target.\n";
  $SX->sky6Web->SlewToObject($target);
  while ( ! defined($SX->sky6RASCOMTele->IsSlewComplete) or $SX->sky6RASCOMTele->IsSlewComplete  ne '1' ) {
    print "  Slewing...\n";
    select(undef,undef,undef,4);
  }
  print "  Call GetAzAlt, GetRaDec, and display \n";
  $SX->sky6RASCOMTele->GetAzAlt();
  $SX->sky6RASCOMTele->GetRaDec();
  print "  Alt is " . $SX->sky6RASCOMTele->dAlt . "\n";;
  print "  Az is " . $SX->sky6RASCOMTele->dAz . "\n";;
  print "  RA is " . $SX->sky6RASCOMTele->dRa . "\n";;
  print "  Dec is " . $SX->sky6RASCOMTele->dDec . "\n";;
  my $dRa = $SX->sky6RASCOMTele->dRa;
  my $dDec = $SX->sky6RASCOMTele->dDec;
  print "  Returning home to test SlewToRaDec\n";
  $SX->sky6RASCOMTele->FindHome();
  print "  Testing SlewToRaDec\n";
  $SX->sky6RASCOMTele->SlewToRaDec($dRa,$dDec,$target);
  while ( ! defined($SX->sky6RASCOMTele->IsSlewComplete) or $SX->sky6RASCOMTele->IsSlewComplete  ne '1' ) {
    print "  Slewing...\n";
    select(undef,undef,undef,4);
  }
# Jog() - Not tested
# Park() - Not tested
# Sync() - Not tested
# SlewToAzAlt() - Not tested
# SetParkPosition() - Not tested
# Turn tracking off
  print "  Turn tracking off. \n";
  $SX->sky6RASCOMTele->SetTracking(0,1,0,0);
# Check to see if tracking is on
  if ($SX->sky6RASCOMTele->IsTracking) { 
    print "  Tracking is On. \n";
  }else{
    print "  Tracking is Off. \n";
  }

  print "Finished testing sky6RASCOMTele module.\n";
  sleep 1;
}

sub testsky6Web {

  print "Testing sky6Web module.\n";
  if (!$SX->sky6RASCOMTele->IsConnected) { 
    print "  Connecting to Telescope. \n";
    $SX->sky6RASCOMTele->Connect();
  }else{
    print "  Already connected to Telescope. Starting Slew. \n";
  }
# Point to $target and wait for it to finish slewing
  my $target = shift;
  print "  Slewing to $target\n";
  $SX->sky6Web->SlewToObject($target);
  while ( ! defined($SX->sky6RASCOMTele->IsSlewComplete) or $SX->sky6RASCOMTele->IsSlewComplete  ne '1' ) {
    print "  Slewing...\n";
    select(undef,undef,undef,4);
  }
  print "  Slew Complete.\n" if $SX->sky6RASCOMTele->IsSlewComplete;
  print "Completed testing sky6Web module.\n";
  sleep 1;
}

sub testccdsoftCamera {


#    TheSkyX.ccdSoftCamera - added filterWheelConnect(), filterWheelDisconnect() and filterWheelIsConnected() methods().
#    CCDSoft2XAdaptor.ccdSoft5Image.DataArray now returns a 2-D array instead of a 1-D array, just like CCDSoft.
#    CCDSoft2XAdaptor.ccdSoft5Image.Width and Height properties no longer return "member not found".
#    CCDSoft2XAdaptor.ccdSoft5Camera methods that do filter wheel operations do nothing if there is no filter wheel connection, just like CCDSoft.
#    CCDSoft2XAdaptor.ccdSoft5Camera.lNumberFilters returns zero when not connected, just like CCDSoft.


  # A LOT more tests need to be added.
  print "Testing ccdsoftCamera module.\n";
  print "  Connecting to Main Imager\n";
# We'll use this later
#   ccdsoftCamera::LastImageFileName
  $SX->ccdsoftCamera->Autoguider(0);
  $SX->ccdsoftCamera->Frame(1);
  $SX->ccdsoftCamera->Connect();
  $SX->ccdsoftCamera->Asynchronous(0);
  $SX->ccdsoftCamera->ImageUseDigitizedSkySurvey(1);
  $SX->ccdsoftCamera->AutoSaveOn(1);
  print "  Taking photo (DSS)\n";
  $SX->ccdsoftCamera->ExposureTime(1);
  $SX->ccdsoftCamera->TakeImage();
  print "  Connecting to Focuser\n";
  $SX->ccdsoftCamera->focConnect();
  print "  Moving in 50 steps.\n";
  $SX->ccdsoftCamera->focMoveIn(50);
  sleep 5;
  print "  Moving out 50 steps.\n";
  $SX->ccdsoftCamera->focMoveOut(50);
  my $numFilters = $SX->ccdsoftCamera->lNumberFilters;
  if ($numFilters =~ /^[+-]?\d+$/ ) {
    my $i = 0;
    for ( $i = 0; $i < $numFilters; ++$i ) {
      print "  Filter position $i - Name: " . $SX->ccdsoftCamera->szFilterName($i) . "\n";
    }
  }else{
    print "  Got a filter error: $numFilters \n";
  }
  print "Finished testing ccdsoftCamera module.\n";
  sleep 1;
}

sub testccdsoftCameraImage {
  my $testImage = shift;
  print "Testing ccdsoftCameraImage module.\n";
  $SX->ccdsoftCameraImage->Path($testImage);
  print "  Image path set to: " . $SX->ccdsoftCameraImage->Path() . "\n";
  print " test path $testImage\n";
  $SX->ccdsoftCameraImage->Open();
  $SX->ccdsoftCameraImage->ScaleInArcsecondsPerPixel(1.70);
  print "InsertWCS " . $SX->ccdsoftCameraImage->InsertWCS() . "\n";;
  print "  InsertWCS Error:  " . $SX->getError() . "\n";
  print "  Image Width: " . $SX->ccdsoftCameraImage->Width . "\n";
  print "  Image Height: " . $SX->ccdsoftCameraImage->Height . "\n";
#  print "  Image JulianDay: " . $SX->ccdsoftCameraImage->JulianDay . "\n";
  print "  Image ModifiedFlag: " . $SX->ccdsoftCameraImage->ModifiedFlag . "\n";
  $SX->ccdsoftCameraImage->Save();
  print "Finished testing ccdsoftCameraImage module.\n";
  sleep 1;
}
