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

our $VERSION = '2017.505';

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
        permissions=>$permissions,
        version    =>$version};
 }

if (1)                                                                          # Parameters that can be set by the caller - see the pod at the end of this file for a complete description of what each parameter does
 {Data::Table::Text::genLValueScalarMethods(
  qw(action),                                                                   # Optional: Default action to perform, compile, lint, run, install, default default is run
  qw(activity),                                                                 # Optional: Activity name, default is 'Activity'
  qw(buildTools),                                                               # REQUIRED: Name of the folder containing the build tools to be used to build the app
  qw(buildFolder),                                                              # Optional: Name of a folder in which to build the app
  qw(copyFiles),                                                                # Optional: Sub to copy additional files into the app before it is complied
  qw(debug),                                                                    # Optional: Make app debuggable is specified and true
  qw(device),                                                                   # Optional: Device to run on, default is the only emulator
  qw(domain),                                                                   # REQUIRED: Domain name for app
  qw(icon),                                                                     # Optional: Jpg file containing a picture that will be scaled to make an icon for the app, default is 'icon.jpg'
  qw(keyAlias),                                                                 # REQUIRED: alias used in keytool to name the key to be used to sign this app
  qw(keyStoreFile),                                                             # REQUIRED: file name of keystore
  qw(keyStorePwd),                                                              # REQUIRED: password of keystore
  qw(log),                                                                      # Output:   message log
  qw(libs),                                                                     # Optional: extra libraries
  qw(name),                                                                     # Optional: One word name of app, default is the name of the folder: '../', will be lower cased and added to the domain name
  qw(parameters),                                                               # Optional: Parameter string to be placed in res for the app
  qw(permissions),                                                              # Optional: Permissions, a standard useful set is applied
  qw(sdk),                                                                      # REQUIRED: Folder containing Android sdk
  qw(sdkLevels),                                                                # Optional: [minSdkVersion,targetSdkVersion], default is [15,25]
  qw(src),                                                                      # Optional: Source of app, default is everything in './src' folder
  qw(title),                                                                    # Optional: Title of app, default is name of app
  qw(version),                                                                  # Optional: Version of app, default is today's date
 )}

sub appSdkLevels($)                                                             # File name of Android jar for linting
 {my ($android) = @_;
  my $l = $android->sdkLevels;
  return @$l if $l;
  (15,25)
 }

sub androidJar($)                                                               # File name of Android jar for linting
 {my ($android) = @_;
  my $sdk = $android->sdk;
  my (undef, $l) = $android->appSdkLevels;
  $sdk."platforms/android-$l/android.jar"
 }

sub appName                                                                     # Single word name of app
 {my ($a) = @_;
  $a->name // (split /\//, $home)[-1];
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

sub package                                                                     # Package for app
 {my ($a) = @_;
  $a->domain.".".lc($a->appName);
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

sub pushIcon                                                    # Create and transfer each icon  using Imagemagick
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
      my $r = xxx($c);
      !$r or confess "Unable to create icon:\n$r\n";
      my $res = $android->appResFolder;
      my $T = $res.$d.'-'.$dir.'dpi/'.$i.'.png';
      makePath($T);
      print STDERR qx(rsync $appIcon $T);
     }
   }
 }

sub pushIcons                                                                   # Create icons
 {my ($android) = @_;
  $android->pushIcon(@$_)
    for ([48, "m"], [72, "h"], [96, "xh"], [144, "xxh"]);
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
  my ($minSdk, $targetSdk) = $android->appSdkLevels;
  my $package     = $android->package;
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
  my $parameters = $android->parameters // '';
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
  my $p = $android->package;
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
  my $sdk       = $android->sdk;
  my $name      = $android->appName;
  my $activity  = $android->activity;
  my $package   = $android->package;
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

sub make
 {my ($android) = @_;
  my $appName    = $android->appName;

  my $sdk        = $android->sdk;
  my $buildTools = $android->buildTools;
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

  my $adb        = filePath($sdk, "platform-tools/adb");
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
   {my $a = xxx("$aapt version");
    $a =~ /Android Asset Packaging Tool/ or
      confess "aapt not found at:\n$aapt\n";
   }

  if (1)                                                                        # Confirm javac
   {my $a = xxx("javac -version");
    $a =~ /javac/ or confess "javac not found\n";
   }

  if (1)                                                                        # Confirm dx
   {my $a = xxx("$dx --version");
    $a =~ /dx version/ or confess "dx not found at:\n$dx\n";
   }

  if (1)                                                                        # Confirm zipalign
   {my $a = xxx("$zipAlign");
    $a =~ /Zip alignment utility/ or
      confess "zipalign not found at:\n$zipAlign\n";
   }

  if (1)                                                                        # Confirm zipalign
   {my $a = xxx("$adb version");
    $a =~ /Android Debug Bridge/ or confess "adb not found at:\n$adb\n";
   }

  if (1)                                                                        # Confirm files
   {for(
  [qq(sdk),        $sdk       ],
  [qq(buildTools), $buildTools],
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
    my $r = xxx("$aapt crunch -v -S $res -C $binRes");
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
     "jarsigner -verbose $alg -keystore $keyStoreFile $apk $keyAlias");

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
  my $src        = $android->src;
  my $androidJar = $android->androidJar;
  my $area       = &getJavaCompiledClassesFolder;
  my $cmd = qq(cd $src && javac *.java -cp  $androidJar:$area);                 # Android, plus locally created classes
  $android->logMessage($cmd);
  if (my $r = qx($cmd))                                                         # Perform compile
   {confess "$r\n";
   }
 }

sub getJavaCompiledClassesFolder                                                # Directory to contain classes compiled by javac -d
 {my $javaClasses = 'Classes';                                                  # Folder that holds compiled java classes
  my @path = split /\//, $home;                                                 # Path components
  while(@path)                                                                  # Walk up the path until we meet java or a folder containing 'Classes'
   {my $p = join '/', @path, $javaClasses;
    last if -d $p;                                                              # A folder containing compile java classes
    last if $path[-1] =~ /java/;                                                # A java folder
    pop @path;                                                                  # Try higher up
   }
  my $f = join '/', @path, $javaClasses;                                        # Directory to contain compiled java classes
  makePath($f);
  $f
 }

#-------------------------------------------------------------------------------
# Install app
#-------------------------------------------------------------------------------

sub install
 {my ($android)  = @_;
  my $sdk        = $android->sdk;
  my $apk        = $android->apk;
  my $device     = $android->device;
  my $package    = $android->package;
  my $activity   = $android->activity;
  my $adb        = $sdk."platform-tools/adb -s $device";
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

sub cInstall                                                                    # Install on emulator
 {my ($android)  = @_;
  $android->install;
 }

sub cLint                                                                       # Lint the source code
 {my ($android)  = @_;
  $android->lint;
 }

sub cCompile                                                                    # Create, make
 {my ($android)  = @_;
  $android->create;
  $android->make;                                                               # Command
 }

sub cRun                                                                        # Create, make, install
 {my ($android)  = @_;
  $android->cCompile;
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

    if    (/\A-*run\z/i)     {$android->cRun}                                   # Run app
    elsif (/\A-*compile\z/i) {$android->cCompile}                               # Compile app
    elsif (/\A-*lint\z/i)    {$android->cLint}                                  # Lint source
    elsif (/\A-*install\z/i) {$android->cInstall}                               # Install on emulator
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

Android::Build - Lint, compile, install, start an Android App using the command
line tools minus ant and gradle.

=head1 Prerequisites

 sudo apt-get install imagemagick zip openjdk-8-jdk
 sudo cpan install Data::Table::Text Data::Dump Carp POSIX File::Copy;

And a version of the Android Software Development Kit.

=head1 Synopsis

This file which can be found in the tar.gz file containing this module:

  SampleApp/perl/makeWithperl.pl

contains:

 use Android::Build;

 my $a = &Android::Build::new();

 $a->sdk          = qq(/home/phil/Android/sdk/);            # Android SDK on the local machine
 $a->buildTools   = $a->sdk."build-tools/25.0.2/";          # Build tools folder
 $a->name         = qq(Genapp);                             # Name of the app, this value will be lower cased and appended to the domain name to form the package name
 $a->title        = qq(Generic App);                        # Title of the app as seen under the icon
 $a->domain       = qq(com.appaapps);                       # Domain name in reverse order
 $a->icon         = "$home/images/Jets/EEL.jpg";            # English Electric Lightning: image that will be scaled to make an icon using Imagemagick
 $a->keyAlias     = qq(xxx);                                # Alias of key to be used to sign this app
 $a->keyStoreFile = "$home/keystore/release-key.keystore";  # Key store file
 $a->keyStorePwd  = qq(xxx);                                # Password for key store file

 $a->build(qw(run));                                        # Build, install and run the app on the only emulator

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

If your Android build description is in file:

 /somewhere/$folder/perl/makeWithPerl.pl

then the Java source and libs for your app should be in:

 /somewhere/$folder/src/*.java
 /somewhere/$folder/libs/*.jar

and the java package name for your app should be:

 package $domain.$folder

where:

 $domain

is your reversed domain name written in lowercase. Executing:

 use Android::Build;

 my $a = &Android::Build::new();
 ...
 $a->build(qw(run));

from folder:

 SampleApp/perl/

will copy the files in the 𝘀𝗿𝗰 and 𝗹𝗶𝗯𝘀 folders to the 𝗯𝘂𝗶𝗹𝗱𝗙𝗼𝗹𝗱𝗲𝗿 before
starting the build of your app.

If this does not meet your requirements, then provide a 𝘀𝘂𝗯

 $a->copyFiles = sub ...

which will be called just before the build begins to allow you to copy into the
𝗯𝘂𝗶𝗹𝗱𝗙𝗼𝗹𝗱𝗲𝗿 any other files needed to build your app.

=head1 Parameters

You can customize your build by assigning to or reading from the following
methods:

=head2 activity

Optional: Activity name, default is 'Activity'. The name of the class to start on the
emulator is the concatenation of:

 $domain. lc($name). '/.'. $activity

=head2 buildTools

REQUIRED: Name of the folder containing the build tools to be used to build the
app

=head2 buildFolder

Optional: Name of a folder in which to build the app. The default is ../tmp

This folder will be cleared (without warning) before the app is built.

=head2 copyFiles

Optional: Sub to copy additional files into the app before it is complied

=head2 debug

Optional: Make the app debuggable if specified and true

=head2 device

Optional: Device to run on, default is the only emulator

=head2 domain

REQUIRED: Domain name for app.  The name of the class to start on the emulator
is the concatenation of:

 $domain. lc($name). '/.'. $activity

=head2 icon

Optional: Jpg file containing a picture that will be scaled using Imagemagick
to make an icon for the app, default is 'icon.jpg'

=head2 keyAlias

REQUIRED: alias used in keytool to name the key to be used to sign this app

=head2 keyStoreFile

REQUIRED: name of key store file

=head2 keyStorePwd

REQUIRED: password of key store file

=head2 log

Output: message log

=head2 libs

Optional: extra libraries

=head2 name

Optional: One word name for the app, default is the name of the folder
containing the current folder. This name will be lower cased and added to the
domain name to form the name of the package to be started to run the app. If
the package name so constructed does not match any package statement in any of
your java files then your app will not start as expected.

The name of the class to start on the emulator is the concatenation of:

 $domain. lc($name). '/.'. $activity

The apk for the generated app will be:

 $name.'.apk'

=head2 parameters

Optional: Parameter string to be placed in folder: 𝗿𝗲𝘀  as a string accessible
via:

 R.string.parameters

=head2 permissions

Optional: Permissions for the app. A standard useful set is supplied by default
if none are provided.

=head2 sdk

REQUIRED: Folder containing Android sdk. This information is used in
conjunction with parameter: 𝘀𝗱𝗸𝗟𝗲𝘃𝗲𝗹𝘀 to find the right Android.jar
and to access the platform tools folder.

=head2 sdkLevels

Optional: [minSdkVersion,targetSdkVersion], default is [15,25]

=head2 src

Optional: Source of app, default is everything in the '../src' folder.

The source files do not have to be positioned within the domain name hierarchy,
you can for instance have all your source files at the root of source directory
or anywhere below it if that is more convenient. This module compiles all java
files found under the source directory plus any others that have been copied
into the app 𝗯𝘂𝗶𝗹𝗱𝗙𝗼𝗹𝗱𝗲𝗿 by the 𝗰𝗼𝗽𝘆𝗳𝗶𝗹𝗲 option. The only requirements is that
each java file use a package statement to declare its final position in the
domain name hierarchy.

=head2 title

Optional: Title of app, default is the name of app, This title will appear
below the app icon on the Android device display.

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

__DATA__
use Test::More tests => 1;

ok 1;
