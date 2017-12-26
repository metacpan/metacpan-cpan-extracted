#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Command line build of an Android apk without resorting to ant or gradle
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------

package Android::Build;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use File::Copy;
use POSIX qw(strftime);                                                         # http://www.cplusplus.com/reference/ctime/strftime/

our $VERSION = '20171224';

#-------------------------------------------------------------------------------
# Constants
#-------------------------------------------------------------------------------

my $home        = currentDirectory();                                           # Home directory
my $permissions =                                                               # Default permissions
   [qw(INTERNET ACCESS_WIFI_STATE ACCESS_NETWORK_STATE WRITE_EXTERNAL_STORAGE),
    qw(READ_EXTERNAL_STORAGE RECEIVE_BOOT_COMPLETED)];
my $version     = strftime('%Y%m%d', localtime);                                # Version number without dots
my $javaTarget  = 7;                                                            # Java release level to target

#-------------------------------------------------------------------------------
# Private methods
#-------------------------------------------------------------------------------

sub getSDKLevels($)                                                             # File name of Android jar for linting
 {my ($android) = @_;                                                           # Android build
  my $l = $android->sdkLevels;
  return @$l if $l and @$l;
  (15,25)
 }

sub getInstructions                                                             # How to get the build tools
 {<<END
Download the Linux tools as specified at the end of page:

  https://developer.android.com/studio/index.html

last set to:

  https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip

Unzip the retrieved file to get the sdkmanager. Use the sdkmanager to get the
version of the SDK that you need, for example:

  sdkmanager 'platforms;android-25'  'build-tools;25.0.3
END
}

sub getPlatform                                                                 # Get and validate the SDK Platform folder
 {my ($a) = @_;
  my $f = $a->platformX;
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
  my $f = $a->buildToolsX;
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
  my $f = $a->platformToolsX;
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

sub getDevice($)                                                                # Device to be used
 {my ($android) = @_;
  my $d = $android->device;
  return '-e' unless $d;
  return $d if $d =~ m(\A-)s;
  "-s $d"
 }

sub getAndroidJar($)                                                            # File name of Android jar for linting
 {my ($android) = @_;
  my $p = $android->getPlatform;
  my $a = filePath($p, qw(android.jar));
  -e $a or confess "Cannot find android.jar via file:\n$a\n";
  $a
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
  my $f = $a->lintFileX;
  $f or confess <<END;
"lintFile" parameter required to lint a file
END
  -e $f or confess <<END;
File to be linted does not exist:
$f
END
  $f
 }

sub getActivity                                                                 # Activity for app
 {my ($a) = @_;
  $a->activity // 'Activity';
 }

sub getAppName                                                                     # Single word name of app used to construct file names
 {my ($a) = @_;
  my $d = $a->getPackage;
  (split /\./, $d)[-1];
 }

sub getTitle                                                                    # Title of app
 {my ($a) = @_;
  $a->title // $a->getAppName;
 }

sub apkFileName                                                                 # Apk name - shorn of path
 {my ($a) = @_;
  $a->getAppName.'.apk';
 }

sub apk                                                                         # Apk name - with full path
 {my ($a) = @_;
  $a->getBinFolder.$a->apkFileName;
 }

sub getVersion                                                                  # Version of the app or default to today's date
 {my ($a) = @_;
  $a->version // $version;
 }

sub buildArea($)                                                                # Build folder name
 {my ($a) = @_;
  $a->buildFolder // '/tmp/app/'                                                # Either the user supplied build folder name or the default
 }

sub getBinFolder($)     {my ($a) = @_; $a->buildArea.'bin/'}                    # Bin folder name
sub getGenFolder($)     {my ($a) = @_; $a->buildArea.'gen/'}                    # Gen folder name
sub getResFolder($)     {my ($a) = @_; $a->buildArea.'res/'}                    # Res folder name
sub getManifestFile($)  {my ($a) = @_; $a->buildArea.'AndroidManifest.xml'}     # Name of manifest file

sub logMessage($@)                                                              # Log a message
 {my ($android, @message) = @_;
  my $s = join '', grep {$_} @message;
  chomp($s) if $s =~ /\n\Z/;
  push @{$android->log}, $s;
  say STDERR $s if -t STDERR;
 }

#-------------------------------------------------------------------------------
# Create icons for app
#-------------------------------------------------------------------------------

sub pushIcon                                                                    # Create and transfer each icon  using Imagemagick
 {my ($android, $icon, $size, $dir) = @_;
  my $res     = $android->getResFolder;
  my $man     = $android->getManifestFile;

  for my $i(qw(ic_launcher))
   {for my $d(qw(drawable))
     {my $s = $size;
      my $T = $res.$d.'-'.$dir.'dpi/'.$i.'.png';
      makePath($T);
      unlink $T;
      my $c = "convert -strip \"$icon\" -resize ${s}x${s}! \"$T\"";             # Convert icon to required size and make it square

      my $r = zzz($c);
#     say STDERR dump([$c, $icon, $T, -e $T, fileSize($T), $r ]);
      confess "Unable to create icon:\n$T\n$r\n"                                # Check icon was created
        if $r or !-e $T or fileSize($T) < 10;
     }
   }
 }

sub pushIcons                                                                   # Create icons possibly in parallel
 {my ($android) = @_;
  my $icon      = $android->iconX;
  -e $icon or confess "Cannot find icon file:\n$icon\n";
  my @pid;
  my @i = ([48, "m"], [72, "h"], [96, "xh"], [144, "xxh"]);                     # Icon specifications

  if ($android->fastIcons)                                                      # Speed up - but it does produce a lot of error messages
   {for(@i)
     {if (my $pid = fork())
       {push @pid, $pid
       }
      else
       {eval {$android->pushIcon($icon, @$_)};
        exit;
       }
     }
    waitpid($_, 0) for @pid;
   }
  else
   {$android->pushIcon($icon, @$_) for @i;
   }
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
  my $version     = $android->getVersion;
  my $man         = $android->getManifestFile;
  my $activity    = $android->activityX;

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
  $manifest =~ s/android:debuggable="true"//gs unless $android->debug;
  writeFile($man, $manifest);
 }

#-------------------------------------------------------------------------------
# Create resources for app
#-------------------------------------------------------------------------------

sub resources()
 {my ($android)  = @_;
  my $title      = $android->getTitle;
  my $version    = $android->getVersion;
  my $parameters = $android->parameters // '';
  my $package    = $android->getPackage;
  my $res        = $android->getResFolder;
  my $strings    = sub
   {return qq(<string name="parameters">$parameters</string>)
      unless ref $parameters;
    my $s = '';
    for my $key(sort keys %$parameters)
     {my $val = $parameters->{$key};
      $s .= qq(<string name="$key">$val</string>\n);
     }
    $s
   }->();
  my $t = << "END";
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="packageName">$package</string>
    <string name="app_name">$title</string>
    <string name="versionName">$version</string>
    $strings
</resources>
END
  writeFile($res."values/strings.xml", $t);

  if (my $titles = $android->titles)                                            # Create additional titles from a hash of: {ISO::639 2 digit language code=>title in that language}
   {for my $l(sort keys %$titles)
     {my $t = $title->{$l};
      writeFile($res."values-$t/strings.xml", <<END);
      <?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">$t</string>
</resources>
END
     }
   }
 }

#-------------------------------------------------------------------------------
# Create app
#-------------------------------------------------------------------------------

sub create
 {my ($android) = @_;
  $android->pushIcons;
  $android->manifest;
  $android->resources;
 }

#-------------------------------------------------------------------------------
# Make app
#-------------------------------------------------------------------------------

sub getAdb
 {my ($android) = @_;
  filePath($android->getPlatformTools, qw(adb))
 }

sub make
 {my ($android)  = @_;
  my $getAppName    = $android->getAppName;

  my $buildTools   = $android->getBuildTools;
  my $buildArea    = $android->buildArea;
  my $keyStoreFile = $android->keyStoreFileX;
  -e $keyStoreFile or confess "Key store file does not exists:\n$keyStoreFile\n";
  my $keyAlias     = $android->keyAliasX;
  my $keyStorePwd  = $android->keyStorePwd;

  my $adb          = $android->getAdb;
  my $androidJar   = $android->getAndroidJar;

  my $aapt         = filePath($buildTools, qw(aapt));
  my $dx           = filePath($buildTools, qw(dx));
  my $zipAlign     = filePath($buildTools, qw(zipalign));

  my $bin          = $android->getBinFolder;
  my $gen          = $android->getGenFolder;
  my $res          = $android->getResFolder;
  my @src          = @{$android->src};
  my @libs         = @{$android->libs};

  my $manifest     = $android->getManifestFile;
  my $binRes       = filePath($bin, $res);
  my $classes      = filePath($bin, qw(classes));

  my $api          = $bin."$getAppName.ap_";
  my $apj          = $bin."$getAppName-unaligned.apk";
  my $apk          = $bin."$getAppName.apk";

  if (1)                                                                        # Confirm aapt
   {my $a = zzz("$aapt version", qr(Android Asset Packaging Tool));
    $a =~ /Android Asset Packaging Tool/ or
      confess "aapt not found at:\n$aapt\n";
   }

  if (1)                                                                        # Confirm javac
   {my $a = zzz("javac -version", qr(javac));
    $a =~ /javac/ or confess "javac not found\n";
   }

  if (1)                                                                        # Confirm dx
   {my $a = zzz("$dx --version", qr(dx version));
    $a =~ /dx version/ or confess "dx not found at:\n$dx\n";
   }

  if (1)                                                                        # Confirm zipalign
   {my $a = zzz("$zipAlign", undef, 2);
    $a =~ /Zip alignment utility/ or
      confess "zipalign not found at:\n$zipAlign\n";
   }

  if (1)                                                                        # Confirm adb
   {my $a = zzz("$adb version", qr(Android Debug Bridge));
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

  for my $file(@{$android->src})                                                # Check source files
   {-e $file or confess "Unable to find source file:\n$file\n";
   }

  for my $file(@{$android->libs})                                               # Check library files
   {-e $file or confess "Unable to find library:\n$file\n";
   }

  unlink $_ for $api, $apj, $apk;                                               # Remove apks

  if (1)                                                                        # Generate R.java
   {makePath($gen);
    my $c = "$aapt package -f -m -0 apk -M $manifest -S $res -I $androidJar".
            " -J $gen --generate-dependencies";
    zzz($c);
   }

  if (1)                                                                        # Java
   {makePath(filePathDir($classes));
    my $j = join ' ', grep {/\.java\Z/} @src,                                   # Java sources files
      findFiles(filePathDir($gen));

    my $J = join ':', $androidJar, @libs;                                       # Jar files for javac

    my $c = "javac -g -Xlint:-options -source $javaTarget ".                    # Compile java source files
            " -target $javaTarget -cp $J -d $classes $j";
    zzz($c);
   }

  if (1)                                                                        # Dx
   {my $j = join ' ', @libs;                                                    # Jar files to include in dex
    zzz("$dx --incremental --dex --force-jumbo ".
        " --output $classes.dex $classes $j");
   }

  if (1)                                                                        # Crunch
   {makePath($binRes);
    zzz("$aapt crunch -S $res -C $binRes");
   }

  if (1)                                                                        # Package
   {zzz
     ("$aapt package --no-crunch -f  -0 apk -M $manifest".
      " -S $binRes  -S $res -I $androidJar".
      " -F $api".
      " --generate-dependencies");
   }

  if (1)                                                                        # Create apk and sign
   {zzz("cp $api $apj");                                                        # Create apk
    zzz("cd $bin && zip -qv $apj classes.dex");                                 # Add dexed classes

    if (1)                                                                      # Sign
     {my $alg = $android->debug ? '' : "-sigalg SHA1withRSA -digestalg SHA1";

      my $c =
        "echo $keyStorePwd |".
        "jarsigner $alg -keystore $keyStoreFile $apj $keyAlias";
      my $s = zzz($c);

      $s =~ /reference a valid KeyStore key entry containing a private key/s and
        confess "Invalid keystore password: $keyStorePwd ".
                "for keystore:\n$keyStoreFile\n".
                "Specify the correct password via the keyStorePwd() method\n";

      $s =~ /jar signed/s or confess "Unable to sign $apj\n";
     }

    if ($android->verifyApk)                                                    # Optional verify
     {my $v = zzz("jarsigner -verify $apj");
      $v =~ /jar verified/s or confess "Unable to verify $apk\n";
     }

    zzz("$zipAlign -f 4 $apj $apk");                                            # Zip align
   }
 }

#1 Methods and attributes

sub new()                                                                       #S Create a new default build
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

if (1) {                                                                        # Parameters that can be set by the caller - see the pod at the end of this file for a complete description of what each parameter does
  genLValueScalarMethods(qw(activity));                                         # Activity name, default is B<Activity> this the name of the activity to start on the L<device|/device> is L<package|/package>/L<activity|/activity>
  genLValueScalarMethods(qw(buildTools));                                       # Name of the folder containing the build tools to be used to build the app, see L<prerequisites|/prerequisites>
  genLValueScalarMethods(qw(buildFolder));                                      # Name of a folder in which to build the app, The default is B</tmp/app/>
  genLValueScalarMethods(qw(classes));                                          # A folder containing precompiled java classes and jar files that you wish to L<lint|/lint> against
  genLValueScalarMethods(qw(debug));                                            # Make the app debuggable if this option is true
  genLValueScalarMethods(qw(device));                                           # Device to run on, default is the only emulator or specify '-d', '-e', or '-s SERIAL' per qx(man adb)
  genLValueScalarMethods(qw(fastIcons));                                        # Create icons in parallel - the default is to create them serially.
  genLValueScalarMethods(qw(icon));                                             # Jpg file containing a picture that will be converted and scaled by L<ImageMagick|http://imagemagick.org/script/index.php> to make an icon for the app, default is B<icon.jpg>
  genLValueScalarMethods(qw(keyAlias));                                         # Alias used in the java keytool to name the key to be used to sign this app. See L<Signing key|/Signing key> for how to generate a key.
  genLValueScalarMethods(qw(keyStoreFile));                                     # Name of key store file.  See L<Signing key|/Signing key> for how to generate a key.
  genLValueScalarMethods(qw(keyStorePwd));                                      # Password of key store file.  See L<Signing key|/Signing key> for how to generate a key.
  genLValueArrayMethods (qw(libs));                                             # A reference to an array of jar files to be copied into the app build to be used as libraries.
  genLValueScalarMethods(qw(lintFile));                                         # A file to be linted with the L<lint|/lint> action using the android L<platform|/platform> and the L<classes|/classes> specified.
  genLValueArrayMethods (qw(log));                                              # Output: a reference to an array of messages showing all the non fatal errors produced by this running this build. To catch fatal error enclose L<build|/build>with 𝗲𝘃𝗮𝗹 {}
  genLValueScalarMethods(qw(package));                                          # The package name to be used in the manifest and to start the app - the file containing the L<activity|/activity> for the app should be in this package
  genLValueScalarMethods(qw(parameters));                                       # Optional parameter string to be placed in folder: B<res> as a string accessible via: B<R.string.parameters> from within the app. Alternatively, if this is a reference to a hash, strings are created for each hash key=value
  genLValueArrayMethods (qw(permissions));                                      # A reference to an array of permissions, a standard useful set is applied by default if none are specified.
  genLValueScalarMethods(qw(platform));                                         # Folder containing B<android.jar>. For example B<~/Android/sdk/platforms/25.0.2>
  genLValueScalarMethods(qw(platformTools));                                    # Folder containing L<adb|https://developer.android.com/studio/command-line/adb.html>
  genLValueArrayMethods (qw(sdkLevels));                                        # [minSdkVersion, targetSdkVersion], default is [15, 25]
  genLValueArrayMethods (qw(src));                                              # A reference to an array of java source files to be compiled to create this app
  genLValueScalarMethods(qw(title));                                            # Title of app, the default is name of app
  genLValueScalarMethods(qw(titles));                                           # Create additional titles for different languages from a hash of: {ISO::639 2 digit language code=>title in that language}
  genLValueScalarMethods(qw(verifyApk));                                        # Verify the signed apk
  genLValueScalarMethods(qw(version));                                          # Version of app, default is today's date
 }

sub compile2($)                                                                 # Compile the app
 {my ($android)  = @_;                                                          # Android build
  $android->create;
  $android->make;                                                               # Compile the app
 }

sub compile($)                                                                  # Compile the app
 {my ($android)  = @_;                                                          # Android build
  eval {&compile2(@_)};
  if ($@)
   {$android->logMessage($@);
    return $@;
   }
  undef                                                                         # No errors encountered
 }

sub lint2($)                                                                    # Lint all the source code java files for the app
 {my ($android)  = @_;                                                          # Android build
  my $src        = $android->getLintFile;
  my $androidJar = $android->getAndroidJar;
  my $area       = $android->classes // 'Classes';
  makePath($area);
  zzz("javac *.java -d $area -cp $androidJar:$area");                           # Android, plus locally created classes
 }

sub lint($)                                                                     # Lint all the source code java files for the app
 {my ($android)  = @_;                                                          # Android build
  eval {&lint2(@_)};
  if ($@)
   {$android->logMessage($@);
    return $@;
   }
  undef                                                                         # No errors encountered
 }

sub install2($)                                                                 # Install an already L<compiled|/compile> app on the selected L<device|/device>:
 {my ($android)  = @_;                                                          # Android build
  my $apk        = $android->apk;
  my $device     = $android->getDevice;
  my $package    = $android->getPackage;
  my $activity   = $android->activityX;
  my $adb        = $android->getAdb." $device ";

  zzz("$adb install -r $apk");
  zzz("$adb shell am start $package/.Activity");
 }

sub install($)                                                                  # Install an already L<compiled|/compile> app on the selected L<device|/device>:
 {my ($android)  = @_;                                                          # Android build
  eval {&install2(@_)};
  if ($@)
   {$android->logMessage($@);
    return $@;
   }
  undef                                                                         # No errors encountered
 }

sub run($)                                                                      # L<Compile|/compile> the app, L<install|/install> and then run it on the selected L<device|/device>
 {my ($android)  = @_;                                                          # Android build
  for(qw(compile install))                                                      # Compile, install and run
   {my $r = $android->$_;
    return $r if $r;
   }
  undef                                                                         # No errors encountered
 }

# podDocumentation

=encoding utf-8

=head1 Name

Android::Build - L<lint|/lint>, L<compile|/compile>, L<install|/install>,
L<run|/run> an Android App using the command line tools minus ant and gradle
thus freeing development effort from the strictures imposed by android studio.

=head1 Prerequisites

 sudo apt-get install imagemagick zip openjdk-8-jdk
 sudo cpan install Data::Table::Text Data::Dump Carp POSIX File::Copy;

You will need a version of the
L<Android Build Tools|https://developer.android.com/studio/index.html>
as specified right at the end of the page below all the inappropriate
advertising for Android Studio.

Download:

  wget https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip

then using the sdkmanager to get the version of the SDK that you want to use,
for example:

  sdkmanager --list --verbose

  sdkmanager 'platforms;android-25'  'build-tools;25.0.3' emulator \
   'system-images;android-25;google_apis;x86_64'

=head1 Synopsis

 use Android::Build;

 my $a = &Android::Build::new();                                                # Create new builder

 $a->buildTools    = qq(~/Android/sdk/build-tools/25.0.2/);                     # Android SDK Build tools folder
 $a->icon          = qq(~/images/Jets/EEL.jpg);                                 # Image that will be scaled to make an icon using Imagemagick - the English Electric Lightening
 $a->keyAlias      = qq(xxx);                                                   # Alias of key to be used to sign this app
 $a->keyStoreFile  = qq(~/keystore/release-key.keystore);                       # Key store file
 $a->keyStorePwd   = qq(xxx);                                                   # Password for key store file
 $a->package       = qq(com.appaapps.genapp);                                   # Package name containing the activity for this app
 $a->platform      = qq(~/Android/sdk/platforms/android-25/);                   # Android SDK platform folder
 $a->platformTools = qq(~/Android/sdk/platform-tools/);                         # Android SDK platform tools folder
 $a->src           = [q(~/AndroidBuild/SampleApp/src/Activity.java)];           # Source code for the app
 $a->title         = qq(Generic App);                                           # Title of the app as seen under the icon

 $a->run;                                                                       # Build, install and run the app on the only emulator

Modify the code above to reflect your local environment, then start an emulator
and run the modified code to compile your app and load it into the emulator.

=head2 Sample App

A sample app is included in folder:

 ./SampleApp

Modify the values in

 ./SampleApp/perl/makeWithPerl.pl

to reflect your local environment, then start an emulator and run:

 perl ./SampleApp/perl/makeWithPerl.pl

to compile the sample app and load it into the running emulator.

=head2 Signing key

If you do not already have a signing key, you can create one with the supplied
script:

 ./SampleApp/perl/generateAKey.pl

=head1 Description

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Methods and attributes

=head2 new()

Create a new default build


This is a static method and so should be invoked as:

  Android::Build::new


=head2 activity :lvalue

Activity name, default is B<Activity> this the name of the activity to start on the L<device|/device> is L<package|/package>/L<activity|/activity>


=head2 buildTools :lvalue

Name of the folder containing the build tools to be used to build the app, see L<prerequisites|/prerequisites>


=head2 buildFolder :lvalue

Name of a folder in which to build the app, The default is B</tmp/app/>


=head2 classes :lvalue

A folder containing precompiled java classes and jar files that you wish to L<lint|/lint> against


=head2 debug :lvalue

Make the app debuggable if this option is true


=head2 device :lvalue

Device to run on, default is the only emulator or specify '-d', '-e', or '-s SERIAL' per qx(man adb)


=head2 icon :lvalue

Jpg file containing a picture that will be converted and scaled by L<ImageMagick|http://imagemagick.org/script/index.php> to make an icon for the app, default is B<icon.jpg>


=head2 keyAlias :lvalue

Alias used in the java keytool to name the key to be used to sign this app. See L<Signing key|/Signing key> for how to generate a key.


=head2 keyStoreFile :lvalue

Name of key store file.  See L<Signing key|/Signing key> for how to generate a key.


=head2 keyStorePwd :lvalue

Password of key store file.  See L<Signing key|/Signing key> for how to generate a key.


=head2 libs :lvalue

A reference to an array of jar files to be copied into the app build to be used as libraries.


=head2 lintFile :lvalue

A file to be linted with the L<lint|/lint> action using the android L<platform|/platform> and the L<classes|/classes> specified.


=head2 log :lvalue

Output: a reference to an array of messages showing all the non fatal errors produced by this running this build. To catch fatal error enclose L<build|/build>with 𝗲𝘃𝗮𝗹 {}


=head2 package :lvalue

The package name to be used in the manifest and to start the app - the file containing the L<activity|/activity> for the app should be in this package


=head2 parameters :lvalue

Optional parameter string to be placed in folder: B<res> as a string accessible via: B<R.string.parameters> from within the app.


=head2 permissions :lvalue

A reference to an array of permissions, a standard useful set is applied by default if none are specified.


=head2 platform :lvalue

Folder containing B<android.jar>. For example B<~/Android/sdk/platforms/25.0.2>


=head2 platformTools :lvalue

Folder containing L<adb|https://developer.android.com/studio/command-line/adb.html>


=head2 sdkLevels :lvalue

[minSdkVersion, targetSdkVersion], default is [15, 25]


=head2 src :lvalue

A reference to an array of java source files to be compiled to create this app


=head2 title :lvalue

Title of app, the default is name of app


=head2 titles :lvalue

Create additional titles for different languages from a hash of: {ISO::639 2 digit language code=>title in that language}


=head2 verifyApk :lvalue

Verify the signed apk


=head2 version :lvalue

Version of app, default is today's date


=head2 compile($)

Compile the app

  1  Parameter  Description
  2  $android   Android build

=head2 lint($)

Lint all the source code java files for the app

  1  Parameter  Description
  2  $android   Android build

=head2 install($)

Install an already L<compiled|/compile> app on the selected L<device|/device>:

  1  Parameter  Description
  2  $android   Android build

=head2 run($)

L<Compile|/compile> the app, L<install|/install> and then run it on the selected L<device|/device>

  1  Parameter  Description
  2  $android   Android build


=head1 Index


1 L<activity|/activity>

2 L<buildFolder|/buildFolder>

3 L<buildTools|/buildTools>

4 L<classes|/classes>

5 L<compile|/compile>

6 L<debug|/debug>

7 L<device|/device>

8 L<icon|/icon>

9 L<install|/install>

10 L<keyAlias|/keyAlias>

11 L<keyStoreFile|/keyStoreFile>

12 L<keyStorePwd|/keyStorePwd>

13 L<libs|/libs>

14 L<lint|/lint>

15 L<lintFile|/lintFile>

16 L<log|/log>

17 L<new|/new>

18 L<package|/package>

19 L<parameters|/parameters>

20 L<permissions|/permissions>

21 L<platform|/platform>

22 L<platformTools|/platformTools>

23 L<run|/run>

24 L<sdkLevels|/sdkLevels>

25 L<src|/src>

26 L<title|/title>

27 L<titles|/titles>

28 L<verifyApk|/verifyApk>

29 L<version|/version>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard L<Module::Build> process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Test::More tests => 1;

ok 1;
