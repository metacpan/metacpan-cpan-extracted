#-------------------------------------------------------------------------------
# Compile, install, start an Android App using the sdk command line build tools
# rather than calling them via ant or gradle.
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------

package Android::Build;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use File::Copy;
use POSIX qw(strftime);                                                         # http://www.cplusplus.com/reference/ctime/strftime/

our $VERSION = '2017.528';

#-------------------------------------------------------------------------------
# Constants
#-------------------------------------------------------------------------------

my $home        = currentDirectory();                                           # Home directory
my $permissions =                                                               # Default permissions
   [qw(INTERNET ACCESS_WIFI_STATE ACCESS_NETWORK_STATE WRITE_EXTERNAL_STORAGE),
    qw(READ_EXTERNAL_STORAGE RECEIVE_BOOT_COMPLETED)];
my $version     = strftime('%Y%m%d', localtime);                                # Version number without dots

sub new()                                                                       # Create a new default build
 {bless{action     =>qq(run),
        activity   =>qw(Activity),
        device     =>qq(emulator-5554),
        home       =>$home,
        icon       =>'icon.png',
        log        =>[],
        parameters =>'',
        permissions=>$permissions,
        version    =>$version};
 }

if (1)                                                                          # Parameters that can be set by the caller - see the pod at the end of this file for a complete description of what each parameter does
 {Data::Table::Text::genLValueScalarMethods(
  qw(action),                                                                   # Default action to perform, compile, lint, run, install, default default is run
  qw(activity),                                                                 # Activity name, default is 'Activity'
  qw(buildTools),                                                               # Name of the folder containing the build tools to be used to build the app
  qw(buildFolder),                                                              # Name of a folder in which to build the app
  qw(classes),                                                                  # Classes folder to be included in lint and/or test
  qw(copyFiles),                                                                # Sub to copy additional files into the app before it is complied
  qw(debug),                                                                    # Make app debuggable is specified and true
  qw(device),                                                                   # Device to run on, default is the only emulator
  qw(icon),                                                                     # Jpg file containing a picture that will be scaled to make an icon for the app, default is 'icon.jpg'
  qw(keyAlias),                                                                 # Alias used in keytool to name the key to be used to sign this app
  qw(keyStoreFile),                                                             # File name of keystore
  qw(keyStorePwd),                                                              # Password of keystore
  qw(lintFile),                                                                 # Java source files to be linted
  qw(log),                                                                      # Message log
  qw(libs),                                                                     # Extra libraries
  qw(package),                                                                  # The package name to be used in the manifest and to start the app - the file containing the Activity for the app should be in this package
  qw(parameters),                                                               # Parameter string to be placed in res for the app
  qw(permissions),                                                              # Permissions, a standard useful set is applied
  qw(platform),                                                                 # Folder containing 'android.jar' - for example Android/sdk/platforms/25.0.2
  qw(platformTools),                                                            # Folder containing Android sdk platform tools
  qw(sdkLevels),                                                                # [minSdkVersion,targetSdkVersion], default is [15,25]
  qw(src),                                                                      # Source of app, default is everything in './src' folder
  qw(title),                                                                    # Title of app, default is name of app
  qw(version),                                                                  # Version of app, default is today's date
 )}

sub getSDKLevels($)                                                             # File name of Android jar for linting
 {my ($android) = @_;
  my $l = $android->sdkLevels;
  return @$l if $l;
  (15,25)
 }

sub getInstructions                                                             # How to get the build tools
 {<<END

https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip

Unzip the retrieved file to get the sdkmanager. Use the sdkmanager to get the
version of the SDK that you need, for example:

sdkmanager 'platforms;android-25'  'build-tools;25.0.3
END
}

sub getPlatform                                                                 # Get and validate the SDK Platform folder
 {my ($a) = @_;
  my $f = $a->platform;
  $f or confess <<END.getInstructions;

"platform" parameter required - it should be the name of the folder containing
the android.jar file that you wish to use. You can get this jar file from:

END
  -d $f or confess <<END;
Cannot find platformTools folder:
$f
END
  $f
 }

sub getBuildTools                                                               # Get and validate the SDK Platform build-tools folder
 {my ($a) = @_;
  my $f = $a->buildTools;
  $f or confess <<END.getInstructions;

"buildTools" parameter required - it should be the name of the folder
containing the Android SDK build tools. You can get these tools from:

END
  -d $f or confess <<END;
Cannot find buildTools folder:
$f
END
  $f
 }

sub getPlatformTools                                                            # Get and validate the SDK Platform tools folder
 {my ($a) = @_;
  my $f = $a->platformTools;
  $f or confess <<END.getInstructions;

"platformTools" parameter required - it should be the name of the folder
containing the Android SDK platform tools.  You can get these tools from:

END
  -d $f or confess <<END;
Cannot find platformTools folder:
$f
END
  $f
 }

sub androidJar($)                                                               # File name of Android jar for linting
 {my ($android) = @_;
  my $p = $android->getPlatform;
  filePath($p, qw(android.jar))
 }

sub getPackage                                                                  # Get and validate the package name for this app
 {my ($a) = @_;
  my $d = $a->package;
  $d or confess <<END =~ s/\n/ /gsr;
"package" parameter required - it should be the value used on the package
statement in the Activity for this app
END
  $d =~ /\./ or confess <<END =~ s/\n/ /gsr;
package "$d" should contain at least one '.'
END
  $d
 }

sub getLintFile                                                                 # Name of the file to be linted
 {my ($a) = @_;
  my $f = $a->lintFile;
  $f or confess <<END;
"lintFile" parameter required to lint a file
END
  -e $f or confess <<END;
File to be linted does not exist:
$f
END
  $f
 }

sub appName                                                                     # Single word name of app used to construct file names
 {my ($a) = @_;
  my $d = $a->getPackage;
  (split /\./, $d)[-1];
 }

sub appTitle                                                                    # Title of app
 {my ($a) = @_;
  $a->title // $a->appName;
 }

sub sourceFolder                                                                # Folder containing source of app
 {my ($a) = @_;
  $a->src // $home.'../src';
 }

sub appLibs                                                                     # Folder containing libraries to be copied into the app
 {my ($a) = @_;
  $a->libs // $home.'../libs';
 }

sub apkFileName                                                                 # Apk name - shorn of path
 {my ($a) = @_;
  $a->appName.'.apk';
 }

sub apk                                                                         # Apk name - with full path
 {my ($a) = @_;
  $a->appBinFolder.$a->apkFileName;
 }

sub buildArea($)                                                                # Build folder name
 {my ($a) = @_;
  $a->buildFolder // $home.'../tmp/app/'                                        # Either the user supplied build folder name or the default
 }

sub appBinFolder($)     {my ($a) = @_; $a->buildArea.'bin/'}                    # Bin folder name
sub appGenFolder($)     {my ($a) = @_; $a->buildArea.'gen/'}                    # Gen folder name
sub appResFolder($)     {my ($a) = @_; $a->buildArea.'res/'}                    # Res folder name
sub appSrcFolder($)     {my ($a) = @_; $a->buildArea.'src/'}                    # Source folder name
sub appLibsFolder($)    {my ($a) = @_; $a->buildArea.'libs/'}                   # Libraries folder
sub appIcon($)          {my ($a) = @_; $a->buildArea.'icon.png'}                # Icon file name
sub manifestFile($)     {my ($a) = @_; $a->buildArea.'AndroidManifest.xml'}     # Name of manifest file

sub logMessage($@)                                                              # Log a message
 {my ($android, @message) = @_;
  my $s = join '', grep {$_} @message;
  chomp($s) if $s =~ /\n\Z/;
  push @{$android->log}, $s;
# say STDERR $s;
 }

#-------------------------------------------------------------------------------
# Create icons for app
#-------------------------------------------------------------------------------

sub pushIcon                                                                    # Create and transfer each icon  using Imagemagick
 {my ($android, $size, $dir) = @_;
  my $icon    = $android->icon;
  $icon or
    confess "Use the icon() method to supply an icon file for this app\n";
  -e $icon or confess "Cannot find icon file:\n$icon\n";
  my $appIcon = $android->appIcon;
  my $res     = $android->appResFolder;
  my $man     = $android->manifestFile;
  for my $i(qw(ic_launcher))
   {for my $d(qw(drawable))
     {makePath($appIcon);
      my $s = $size;
      my $c = "convert -strip $icon -resize ${s}x${s}! $appIcon";
      my $r = xxx($c, qr(convert));
      !$r or confess "Unable to create icon:\n$r\n";
      my $res = $android->appResFolder;
      my $T = $res.$d.'-'.$dir.'dpi/'.$i.'.png';
      makePath($T);
      print STDERR qx(rsync $appIcon $T);
     }
   }
 }

sub pushIcons                                                                   # Create icons in parallel
 {my ($android) = @_;
  my @pid;
  for([48, "m"], [72, "h"], [96, "xh"], [144, "xxh"])
   {if (my $pid = fork()) {push @pid, $pid}
    else
     {$android->pushIcon(@$_);
      exit;
     }
   }
  waitpid($_, 0) for @pid;
 }

#-------------------------------------------------------------------------------
# Create manifest for app
#-------------------------------------------------------------------------------

sub addPermissions                                                              # Create permissions
 {my ($android) = @_;
  my $P = "android.permission";
  my %p = (map {$_=>1} @{$android->permissions});
  my $p = "\n";

  for(sort keys %p)
   {$p .= "  <uses-permission android:name=\"$P.$_\"/>\n";
   }

  $p
 }

sub manifest
 {my ($android) = @_;
  my $permissions = $android->addPermissions;
  my ($minSdk, $targetSdk) = $android->getSDKLevels;
  my $package     = $android->getPackage;
  my $version     = $android->version;
  my $debug       = $android->debug;
  my $man         = $android->manifestFile;
  my $activity    = $android->activity;

  my $manifest = << "END";
<?xml version="1.0" encoding="utf-8"?>
  <manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$package"
    android:installLocation="auto"
    android:versionCode="$version"
    android:versionName="\@string/versionName">

  <uses-sdk
    android:minSdkVersion="$minSdk"
    android:targetSdkVersion="$targetSdk"/>
  <application
    android:allowBackup="true"
    android:icon="\@drawable/ic_launcher"
    android:largeHeap="true"
    android:debuggable="true"
    android:hardwareAccelerated="true"
    android:label="\@string/app_name">
    <activity
      android:name=".$activity"
      android:configChanges="keyboard|keyboardHidden|orientation|screenSize"
      android:screenOrientation="sensor"
      android:theme="\@android:style/Theme.NoTitleBar"
      android:label="\@string/app_name">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity>
  </application>
  $permissions
</manifest>
END
  $manifest =~ s/android:debuggable="true"//gs unless $debug;
  writeFile($man, $manifest);
 }

#-------------------------------------------------------------------------------
# Create resources for app
#-------------------------------------------------------------------------------

sub resources()
 {my ($android)  = @_;
  my $title      = $android->title;
  my $version    = $android->version;
  my $parameters = $android->parameters;
  my $res        = $android->appResFolder;
  my $t = << "END";
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">$title</string>
    <string name="versionName">$version</string>
    <string name="parameters">$parameters</string>
</resources>
END
  writeFile($res."values/strings.xml", $t);
 }

#-------------------------------------------------------------------------------
# Copy source
#-------------------------------------------------------------------------------

sub copySource
 {my ($android) = @_;
  my $s = $android->sourceFolder;
  my $p = $android->getPackage;
  my $P = $p =~ s/\./\//gr;
  my $t = $android->appSrcFolder."$P/";
  makePath($t);
  print STDERR qx(rsync -r $s $t);                                              # Copy source files recursively
  if (my $copy = $android->copyFiles)                                           # Do a copy file step to bring in additional files
   {$copy->($android, $t);
   }
 }

#-------------------------------------------------------------------------------
# Copy libraries
#-------------------------------------------------------------------------------

sub copyLibs
 {my ($android) = @_;
  if (my $libSource = $android->libs)
   {my $libTarget = $android->appLibs;
    print STDERR qx(rsync -r $_ $libTarget) for glob("$libSource/*")
   }
 }

#-------------------------------------------------------------------------------
# Create app
#-------------------------------------------------------------------------------

sub create
 {my ($android) = @_;
  my $buildArea = $android->buildArea;
  my $name      = $android->appName;
  my $activity  = $android->activity;
  my $package   = $android->getPackage;
  if (-d $buildArea)
   {my $r = xxx("rm -r $buildArea");                                            # Clear build area
    !$r or confess "Unable to remove existing app build area:\n".
                   "$buildArea\n$r\n";
   }
  $android->pushIcons;                                                          # Create icons
  $android->copySource;                                                         # Copy source
  $android->copyLibs;                                                           # Copy libraries
  $android->manifest;                                                           # Create manifest
  $android->resources;                                                          # Create resources
 }

#-------------------------------------------------------------------------------
# Make app
#-------------------------------------------------------------------------------

sub getAdb
 {my ($android) = @_;
  filePath($android->getPlatformTools, qw(adb))
 }

sub make
 {my ($android) = @_;
  my $appName    = $android->appName;

  my $buildTools = $android->getBuildTools;
  $buildTools or confess
   "Supply the path to the build-tools folder in your Android sdk".
   " via the buildTools() method\n";

  my $buildArea    = $android->buildArea;
  my $keyStoreFile = $android->keyStoreFile;
     $keyStoreFile or confess
   "Supply the path to the key store file via the keyStoreFile() method\n";
  -e $keyStoreFile or confess
   "Key store file does not exists:\n$keyStoreFile\n";
  my $keyAlias     = $android->keyAlias;
     $keyAlias or confess
   "Supply the key alias to sign this app via the keyAlias() method\n";
  my $keyStorePwd  = $android->keyStorePwd;

  my $adb        = $android->getAdb;
  my $androidJar = $android->androidJar;

  my $aapt       = filePath($buildTools, qw(aapt));
  my $dx         = filePath($buildTools, qw(dx));
  my $zipAlign   = filePath($buildTools, qw(zipalign));

  my $bin        = $android->appBinFolder;
  my $gen        = $android->appGenFolder;
  my $res        = $android->appResFolder;
  my $src        = $android->appSrcFolder;
  my $manifest   = $android->manifestFile;
  my $binRes     = filePath($bin, $res);
  my $classes    = filePath($bin, qw(classes));

  my $api        = $bin."$appName.ap_";
  my $apj        = $bin."$appName-unaligned.apk";
  my $apk        = $bin."$appName.apk";

  if (1)                                                                        # Confirm aapt
   {my $a = xxx("$aapt version", qr(Android Asset Packaging Tool));
    $a =~ /Android Asset Packaging Tool/ or
      confess "aapt not found at:\n$aapt\n";
   }

  if (1)                                                                        # Confirm javac
   {my $a = xxx("javac -version", qr(javac));
    $a =~ /javac/ or confess "javac not found\n";
   }

  if (1)                                                                        # Confirm dx
   {my $a = xxx("$dx --version", qr(dx version));
    $a =~ /dx version/ or confess "dx not found at:\n$dx\n";
   }

  if (1)                                                                        # Confirm zipalign
   {my $a = xxx("$zipAlign", qr(zipalign));
    $a =~ /Zip alignment utility/ or
      confess "zipalign not found at:\n$zipAlign\n";
   }

  if (1)                                                                        # Confirm adb
   {my $a = xxx("$adb version", qr(Android Debug Bridge));
    $a =~ /Android Debug Bridge/ or confess "adb not found at:\n$adb\n";
   }

  if (1)                                                                        # Confirm files
   {for(
  [qq(buildArea),  $buildArea ],
  [qq(androidJar), $androidJar],
  [qq(res),        $res       ],
  [qq(manifest),   $manifest  ],
  )
     {my ($name, $file) = @$_;
      -e $file or confess "Unable to find $name:\n$file\n";
     }
   }

  unlink $_ for $api, $apj, $apk;                                               # Remove apks

  if (1)                                                                        # Generate R.java
   {makePath($gen);
    my $r = xxx
    ("$aapt package -f -m -0 apk -M $manifest -S $res -I $androidJar",
     "-J $gen --generate-dependencies");
    $android->logMessage($r);
   }

  if (1)                                                                        # Java
   {makePath(filePathDir($classes));
    my $j = join ' ', grep {/\.java\Z/}                                         # Find java files
      findFiles(filePathDir($src)),
      findFiles(filePathDir($gen));

    my $r = xxx("javac -source  7 -target 7 -cp $androidJar -d $classes $j");
    $r !~ /error/ or confess "Java errors\n";
    $android->logMessage($r);
   }

  if (1)                                                                        # Dx
   {makePath($classes);
    my $r = xxx("$dx --dex --force-jumbo --output $classes.dex $classes");
    $android->logMessage($r);
   }

  if (1)                                                                        # Crunch
   {makePath($binRes);
    my $r = xxx("$aapt crunch -S $res -C $binRes");
    $android->logMessage($r);
   }

  if (1)                                                                        # Package
   {my $r = xxx
     ("$aapt package --no-crunch -f  -0 apk -M $manifest",
      "-S $binRes  -S $res -I $androidJar",
      "-F $api",
      "--generate-dependencies");
    $android->logMessage($r);
   }

  if (1)                                                                        # Create apk and sign
   {xxx("cp $api $apj");                                                        # Create apk
    xxx("cd $bin && zip -qv $apj classes.dex");                                 # Add dexed classes

    my $z = xxx("$zipAlign -f 4 $apj $apk");
    $android->logMessage($z);

    my $alg = $android->debug ? '' : "-sigalg SHA1withRSA -digestalg SHA1";

    my $s = xxx("echo $keyStorePwd |",                                          # Sign
     "jarsigner $alg -keystore $keyStoreFile $apk $keyAlias");

    $s =~ /reference a valid KeyStore key entry containing a private key/s and
      confess "Invalid keystore password: $keyStorePwd ".
              "for keystore:\n$keyStoreFile\n".
              "Specify the correct password via the keyStorePwd() method\n";

    $s =~ /jar signed/s or confess "Unable to sign $apk\n";
    $android->logMessage($s);

    my $v = xxx("jarsigner -verify $apk");
    $v =~ /jar verified/s  or confess "Unable to verify $apk\n";
    $android->logMessage($v);
   }
 }

#-------------------------------------------------------------------------------
# Lint app
#-------------------------------------------------------------------------------

sub lint
 {my ($android)  = @_;
  my $src        = $android->getLintFile;
  my $androidJar = $android->androidJar;
  my $area       = $android->classes // 'Classes';
  makePath($area);
  my $cmd = qq(javac *.java -d $area -cp $androidJar:$area);                    # Android, plus locally created classes
  $android->logMessage($cmd);
  if (my $r = qx($cmd))                                                         # Perform compile
   {say STDERR "$r\n";
   }
 }

#-------------------------------------------------------------------------------
# Install app
#-------------------------------------------------------------------------------

sub install
 {my ($android)  = @_;
  my $apk        = $android->apk;
  my $device     = $android->device;
  my $package    = $android->getPackage;
  my $activity   = $android->activity;
  my $adb        = $android->getAdb." -s $device";
  if (1)
   {my $c = "$adb install -r $apk";
    my $r = xxx($c);
    $r =~ /Success/ or confess "Install failed\n$r\n";
    $android->logMessage($r);
   }
  if (1)
   {my $c = "$adb shell am start $package/.Activity";
    my $r = xxx($c);
    $r =~ /Starting/ or confess "Start failed\n$r\n";
    $android->logMessage($r);
   }
 }

#-------------------------------------------------------------------------------
# Actions
#-------------------------------------------------------------------------------

sub compile                                                                     # Create, make
 {my ($android)  = @_;
  $android->create;
  $android->make;                                                               # Command
 }

sub run                                                                         # Create, make, install
 {my ($android)  = @_;
  $android->compile;
  $android->install;                                                            # Perform compile
 }                                                                              # Install and run

#-------------------------------------------------------------------------------
# Perform actions
#-------------------------------------------------------------------------------

sub build
 {my ($android, @actions) = @_;
  @actions = ($android->action) unless @actions;                                # Default action if no action supplied

  while(@actions)
   {local $_ = shift @actions;

    if    (/\A-*run\z/i)     {$android->run}                                    # Run app
    elsif (/\A-*compile\z/i) {$android->compile}                                # Compile app
    elsif (/\A-*lint\z/i)    {$android->lint}                                   # Lint source
    elsif (/\A-*install\z/i) {$android->install}                                # Install on emulator
    else
     {confess"Ignored unknown command: $_\n";
     }
   }
  $android->logMessage("Normal finish for Android::Build");
 }

#-------------------------------------------------------------------------------
# Test
#-------------------------------------------------------------------------------

sub test
 {eval join('', <Android::Build::DATA>) || die $@
 }

test unless caller();

# Documentation
#extractDocumentation unless caller;

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw();
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

1;

=encoding utf-8

=head1 Name

Android::Build - lint, compile, install, start an Android App using the command
line tools minus ant and gradle.

=head1 Prerequisites

 sudo apt-get install imagemagick zip openjdk-8-jdk
 sudo cpan install Data::Table::Text Data::Dump Carp POSIX File::Copy;

You will need a version of the 𝗔𝗻𝗱𝗿𝗼𝗶𝗱 build tools. You can get these tools by
first downloading:

  https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip

then using the sdkmanager to get the version of the SDK that you want to use,
for example:

  sdkmanager 'platforms;android-25'  'build-tools;25.0.3

=head1 Synopsis

This file which can be found in the tar.gz file containing this module:

  SampleApp/perl/makeWithperl.pl

contains:

 use Android::Build;

 my $a = &Android::Build::new();

 $a->buildTools    = qq(/home/phil/Android/sdk/build-tools/25.0.2/);   # Android SDK Build tools folder
 $a->icon          = qq(/home/phil/images/Jets/EEL.jpg);               # Image that will be scaled to make an icon using Imagemagick - the English Electric Lightening
 $a->keyAlias      = qq(xxx);                                          # Alias of key to be used to sign this app
 $a->keyStoreFile  = qq(/home/phil/keystore/release-key.keystore);     # Key store file
 $a->keyStorePwd   = qq(xxx);                                          # Password for key store file
 $a->package       = qq(com.appaapps.genapp);                          # Package name containing the activity for this app
 $a->platform      = qq(/home/phil/Android/sdk/platforms/android-25/); # Android SDK platform folder
 $a->platformTools = qq(/home/phil/Android/sdk/platform-tools/);       # Android SDK platform tools folder
 $a->title         = qq(Generic App);                                  # Title of the app as seen under the icon

 $a->run;                                                              # Build, install and run the app on the only emulator

Modify the values above to reflect your local environment, then start an
emulator and run:

 cd SampleApp/perl/ && perl makeWithPerl.pl

to compile the sample app and load it into the emulator.

If you do not already have a signing key, you can create one with the supplied
script:

 SampleApp/perl/generateAKey.pl

=head1 File layout

A sample file layout is included in folder:

 SampleApp/

If your 𝗔𝗻𝗱𝗿𝗼𝗶𝗱 build description is in file:

 /somewhere/$folder/perl/makeWithPerl.pl

then by default the Java source and libraries (jar files) for your app should
be in:

 /somewhere/$folder/src/*.java
 /somewhere/$folder/libs/*.jar

These files will be copied into the 𝗯𝘂𝗶𝗹𝗱𝗙𝗼𝗹𝗱𝗲𝗿 before starting the build of
your app.

If this does not meet your requirements, then provide a 𝘀𝘂𝗯 {}

 $a->copyFiles = sub ...

which will be called just before the build begins to allow you to copy any
other files into the 𝗯𝘂𝗶𝗹𝗱𝗙𝗼𝗹𝗱𝗲𝗿.

=head1 Actions

The following actions are available:

=head2 compile

To compile your app:

 $android->compile

=head2 lint

To lint a file in your app:

 $android->lintFile = ...
 $android->lint

Set the file to be linted with L<"lintFile">. You can add a folder of
precompiled classes to the lint with L<"classes">.  𝗮𝗻𝗱𝗿𝗼𝗶𝗱.𝗷𝗮𝗿  will also be
added to the lint class path.

=head2 install

To install and already compiled app on the selected L<"device">:

 $android->install

=head2 run

As described in L<"Synopsis">

 $android->run

will compile your app and if the compile is successful, install it on the
selected L<"device"> and run it.

=head1 Parameters

You can customise your build by assigning to or reading from the following
methods:

=head2 activity

Activity name, default is '

 Activity

The name of the class to start on the L<"device"> is the concatenation of:

 package . '/.'. activity

=head2 buildTools

Name of the folder containing the build tools to be used to build the app. See
L<"Prerequisites">

=head2 buildFolder

Name of a folder in which to build the app. The default is

 ../tmp

This folder will be cleared (without warning) before the app is built.

=head2 classes

A folder containing precompiled java classes that you wish to L<"lint"> against.

=head2 copyFiles

𝘀𝘂𝗯 {} to copy additional files into the app before it is complied

=head2 debug

Make the app debuggable if specified and true.

=head2 device

Device to run on, default is the only emulator.

=head2 icon

A file containing a picture that will be converted and scaled using
𝗜𝗺𝗮𝗴𝗲𝗺𝗮𝗴𝗶𝗰𝗸 to make an icon for the app, default is:

 icon.jpg

=head2 keyAlias

Alias used in the java keytool to name the key to be used to sign this app. See
L<"Synopsis"> for how to generate a key.

=head2 keyStoreFile

Name of key store file. See L<"Synopsis"> for how to generate a key.

=head2 keyStorePwd

Password of key store file. See L<"Synopsis"> for how to generate a key.

=head2 log

Output: message log showing all the none fatal errors produced by this running
this build.  To catch fatal error enclose with 𝗲𝘃𝗮𝗹 {}

=head2 libs

Extra libraries (jar files) to be copied into the app build. See also:
L<"CopyFiles">

=head2 lintFile

A file to be linted with the L<"lint"> action using the 𝗮𝗻𝗱𝗿𝗼𝗶𝗱.𝗷𝗮𝗿  and
L<"classes"> specified.

=head2 package

The value of the package statement in the java file containing the 𝗔𝗰𝘁𝗶𝘃𝗶𝘁𝘆
class for this app.  This is the 𝗔𝗰𝘁𝗶𝘃𝗶𝘁𝘆 that will be started to run the app

=head2 platform

The name of the folder containing the 𝗮𝗻𝗱𝗿𝗼𝗶𝗱.𝗷𝗮𝗿  you wish to use.  See the
notes in L<"Prerequisites">

=head2 platformTools

The name of the folder containing the  𝗔𝗻𝗱𝗿𝗼𝗶𝗱.𝗷𝗮𝗿  you wish to use.  See the
notes in L<"Prerequisites">

=head2 parameters

Optional: Parameter string to be placed in folder: 𝗿𝗲𝘀  as a string accessible
via:

 R.string.parameters

from within the app.

=head2 permissions

Permissions for the app. A standard useful set is supplied by default if none
are provided.

=head2 sdkLevels

The sdk levels to be declared for the app in the form:

 [minSdkVersion,targetSdkVersion],

The default is:

 [15,25]

=head2 src

Optional: Source of app, default is everything in the:

  ../src

folder.

The source files do not have to be positioned within the domain name hierarchy,
you can for instance have all your source files at the root of source directory
or anywhere below it if that is more convenient. This module compiles all java
files found under the source directory plus any others that have been copied
into the app 𝗯𝘂𝗶𝗹𝗱𝗙𝗼𝗹𝗱𝗲𝗿 by the 𝗰𝗼𝗽𝘆𝗳𝗶𝗹𝗲 option. The only requirements is that
each java file use a package statement to declare its final position in the
domain name hierarchy.

=head2 title

Title of app, default is the last word of the package name. This title will
appear below the app icon on the 𝗔𝗻𝗱𝗿𝗼𝗶𝗱 device display.

=head2 version

Optional: Version of app, default is today's date

=head1 Installation

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

philiprbrenan@gmail.com

http://www.appaapps.com

=head1 Copyright

Copyright (c) 2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut
# pod2html --infile Build.pm --outfile ~/zzz.html && rm pod2htmd.tmp

__DATA__
use Test::More tests => 1;

ok 1;
