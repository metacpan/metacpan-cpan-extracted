#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Command line build of an Android apk without resorting to ant or gradle
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------
# perl Build.PL && perl Build test && sudo perl Build install
package Android::Build;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use File::Copy;
use POSIX qw(strftime);                                                         # http://www.cplusplus.com/reference/ctime/strftime/

our $VERSION = '20201115';

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

sub getAppName                                                                  # Single word name of app used to construct file names
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

sub getAssFolder($)     {my ($a) = @_; $a->buildArea.'assets/'}                 # Assets folder name
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
  overWriteFile($man, $manifest);
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
  overWriteFile($res."values/strings.xml", $t);

  if (my $titles = $android->titles)                                            # Create additional titles from a hash of: {ISO::639 2 digit language code=>title in that language}
   {for my $l(sort keys %$titles)
     {my $t = $title->{$l};
      overWriteFile($res."values-$l/strings.xml", <<END);
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

my $confirmRequiredUtilitiesAreInPosition;

sub confirmRequiredUtilitiesAreInPosition($)                                    # Confirm required utilities are in position
 {my ($android)  = @_;
  return if $confirmRequiredUtilitiesAreInPosition++;                           # Only do this once per run

  my $buildTools   = $android->getBuildTools;
  my $adb          = $android->getAdb;
  my $aapt         = filePath($buildTools, qw(aapt));
  my $dx           = filePath($buildTools, qw(dx));
  my $zipAlign     = filePath($buildTools, qw(zipalign));

  zzz("$aapt version", qr(Android Asset Packaging Tool), 0,
      "aapt not found at:\n$aapt");
  zzz("$adb version", qr(Android Debug Bridge), 0, "adb not found at:\n$adb");
  zzz("$dx --version", qr(dx version), 0, "dx not found at:\n$dx");
  zzz("jarsigner", qr(Usage: jarsigner), 0, "jarsigner not found");
  zzz("javac -version", qr(javac), 0, "javac not found");
  zzz("zip -v", qr(Info-ZIP), 0, "zip not found\n");
  zzz("$zipAlign", 0, 2, "zipalign not found at:\n$zipAlign");
 }

sub signApkFile($$)                                                             # Sign an apk file
 {my ($android, $apkFile) = @_;                                                 # Android, apk file to sign
  $android->confirmRequiredUtilitiesAreInPosition;

  my $keyStoreFile = $android->keyStoreFileX;
  -e $keyStoreFile or confess"Key store file does not exists:\n$keyStoreFile\n";
  my $keyAlias     = $android->keyAliasX;
  my $keyStorePwd  = $android->keyStorePwd;

  my $alg = $android->debug ? '' : "-sigalg SHA1withRSA -digestalg SHA1";

  my $c =
    "echo $keyStorePwd |".
    "jarsigner $alg -keystore $keyStoreFile $apkFile $keyAlias";
  my $s = zzz($c);

  $s =~ /reference a valid KeyStore key entry containing a private key/s and
    confess "Invalid keystore password: $keyStorePwd ".
            "for keystore:\n$keyStoreFile\n".
            "Specify the correct password via the keyStorePwd() method\n";

  $s =~ /jar signed/s or confess "Unable to sign $apkFile\n";

  if ($android->verifyApk)                                                      # Optional verify
   {my $v = zzz("jarsigner -verify $apkFile");
    $v =~ /jar verified/s or confess "Unable to verify $apkFile\n";
   }
 }

sub make
 {my ($android)  = @_;
  $android->confirmRequiredUtilitiesAreInPosition;
  my $getAppName    = $android->getAppName;
  my $buildTools   = $android->getBuildTools;
  my $buildArea    = $android->buildArea;
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
  my $binRes       = filePath($bin, q(res));
  my $classes      = filePath($bin, q(classes));
  my $api          = $bin."$getAppName.ap_";
  my $apj          = $bin."$getAppName-unaligned.apk";
  my $apk          = $bin."$getAppName.apk";

  if (1)                                                                        # Confirm required files are in position
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

  unlink $_ for $api, $apj, $apk;                                               # Remove any existing apks

  if (1)                                                                        # Generate R.java
   {makePath($gen);
    my $c = "$aapt package -f -m -0 apk -M $manifest -S $res -I $androidJar".
            " -J $gen --generate-dependencies";
    zzz($c);
   }

  if (1)                                                                        # Compile java
   {makePath(filePathDir($classes));
    my $j = join ' ', grep {/\.java\Z/} @src,                                   # Java sources files
      findFiles(filePathDir($gen));

    my $J = join ':', $androidJar, @libs;                                       # Jar files for javac

    my $c = "javac -g -Xlint:-options -source $javaTarget ".                    # Compile java source files
            " -target $javaTarget -cp $J -d $classes $j";
    zzz($c);
   }

  if (1)                                                                        # 'Dx'
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
   {zzz("mv $api $apj");                                                        # Create apk
    zzz("cd $bin && zip -qv $apj classes.dex");                                 # Add dexed classes
   }

  my $assetsFolder = $android->getAssFolder;
  my $assetsFiles  = $android->assets;                                          # Create asset files if necessary

  if ($assetsFiles or -d $assetsFolder)                                         # Create asset files if necessary
   {writeFiles($assetsFiles, $assetsFolder) if $assetsFiles;                    # Write assets file system hash if supplied
    zzz(qq(cd $assetsFolder && cd .. && zip -rv $apj assets));                  # Add assets to apk
   }

  $android->signApkFile($apj);                                                  # Sign the apk file

  zzz("$zipAlign -f 4 $apj $apk");                                              # Zip align

  unlink $_ for $api, $apj;                                                     # Remove intermediate apks
 }

sub cloneApk2($$)                                                               # Clone an apk file: copy the apk, replace the L<assets|assets/>, re-sign, zipalign, return the name of the newly created apk file.
 {my ($android, $oldApk) = @_;                                                  # Android, file name of apk to be cloned
  $android->confirmRequiredUtilitiesAreInPosition;

  confess "Old apk file name not supplied\n"   unless    $oldApk;
  confess "Old apk does not exist:\n$oldApk\n" unless -e $oldApk;

  my $buildTools   = $android->getBuildTools;
  my $zipAlign     = filePath($buildTools, qw(zipalign));

  my $tempFolder = temporaryFolder;                                             # Temporary folder to unzip into
  zzz(<<"END", 0, 0,  "Unable to unzip");                                       # Unzip old apk
unzip -o $oldApk -d $tempFolder -x "assets/*" "META-INF/*"
END

  if (my $assetsFiles = $android->assets)                                       # Create asset files if necessary
   {my $assetsFolder  = fpd($tempFolder, q(assets));
    writeFiles($assetsFiles, $assetsFolder);
   }

  my $tmpApk = fpe(temporaryFile, q(apk));                                      # Temporary Apk
  zzz(qq(cd $tempFolder && zip -rv $tmpApk *), 0, 0, "Unable to rezip");        # Recreate apk

  $android->signApkFile($tmpApk);                                               # Sign

  my $newApk = fpe(temporaryFile, q(apk));                                      # New apk
  zzz("$zipAlign -f 4 $tmpApk $newApk", 0, 0, "Unable to zipalign");            # Zip align

  unlink $tmpApk;                                                               # Clean up
  clearFolder($tempFolder, 100);

  return $newApk;
 }

sub compile2($)                                                                 #P Compile the app
 {my ($android) = @_;                                                           # Android build
  $android->create;
  $android->make;                                                               # Compile the app
 }

sub install2($)                                                                 #P Install an already L<compiled|/compile> app on the selected L<device|/device>:
 {my ($android)  = @_;                                                          # Android build
  my $apk        = $android->apk;
  my $device     = $android->getDevice;
  my $package    = $android->getPackage;
  my $activity   = $android->activityX;
  my $adb        = $android->getAdb." $device ";
# say STDERR "Install app";
  zzz("$adb install -r $apk");
# say STDERR "Start app";
  zzz("$adb shell am start $package/.Activity");
# say STDERR "App installed and started";
 }

sub lint2($)                                                                    #P Lint all the source code java files for the app
 {my ($android)  = @_;                                                          # Android build
  my $src        = $android->getLintFile;
  my $androidJar = $android->getAndroidJar;
  my $area       = $android->classes // 'Classes';
  makePath($area);
  zzz("javac *.java -d $area -cp $androidJar:$area");                           # Android, plus locally created classes
 }

#1 Methods and attributes

sub new()                                                                       #S Create a new build.
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
  genLValueScalarMethods(qw(activity));                                         # Activity name: default is B<Activity>. The name of the activity to start on your android device: L<device|/device> is L<package|/package>/L<Activity|/Activity>
  genLValueScalarMethods(qw(assets));                                           # A hash containing your assets folder (if any).  Each key is the file name in the assets folder, each corresponding value is the data for that file. The keys of this hash may contain B</> to create sub folders.
  genLValueScalarMethods(qw(buildTools));                                       # Name of the folder containing the build tools to be used to build the app, see L<prerequisites|/prerequisites>
  genLValueScalarMethods(qw(buildFolder));                                      # Name of a folder in which to build the app, The default is B</tmp/app/>. If you wish to include assets with your app, specify a named build folder and load it with the desired assets before calling L<compile> or specify the assets via L<assets>.
  genLValueScalarMethods(qw(classes));                                          # A folder containing precompiled java classes and jar files that you wish to L<lint|/lint> against.
  genLValueScalarMethods(qw(debug));                                            # The app will be debuggable if this option is true.
  genLValueScalarMethods(qw(device));                                           # Device to run on, default is the only emulator or specify '-d', '-e', or '-s SERIAL' per L<adb|http://developer.android.com/guide/developing/tools/adb.html>
  genLValueScalarMethods(qw(fastIcons));                                        # Create icons in parallel if true - the default is to create them serially which takes more elapsed time.
  genLValueScalarMethods(qw(icon));                                             # Jpg file containing a picture that will be converted and scaled by L<ImageMagick|http://imagemagick.org/script/index.php> to make an icon for the app, default is B<icon.jpg> in the current directory.
  genLValueScalarMethods(qw(keyAlias));                                         # Alias of the key in your key store file which will be used to sign this app. See L<Signing key|/Signing key> for how to generate a key.
  genLValueScalarMethods(qw(keyStoreFile));                                     # Name of your key store file.  See L<Signing key|/Signing key> for how to generate a key.
  genLValueScalarMethods(qw(keyStorePwd));                                      # Password of your key store file.  See L<Signing key|/Signing key> for how to generate a key.
  genLValueArrayMethods (qw(libs));                                             # A reference to an array of jar files to be copied into the app build to be used as libraries.
  genLValueScalarMethods(qw(lintFile));                                         # A file to be linted with the L<lint|/lint> action using the android L<platform|/platform> and the L<classes|/classes> specified.
  genLValueArrayMethods (qw(log));                                              # Output: a reference to an array of messages showing all the non fatal errors produced by this running this build. To catch fatal error enclose L<build|/build> with L<eval{}|perlfunc/eval>
  genLValueScalarMethods(qw(package));                                          # The package name used in the manifest file to identify the app. The java file containing the L<activity|/activity> for this app should use this package name on its B<package> statement.
  genLValueScalarMethods(qw(parameters));                                       # Optional parameter string to be placed in folder: B<res> as a string accessible via: B<R.string.parameters> from within the app. Alternatively, if this is a reference to a hash, strings are created for each hash key=value
  genLValueArrayMethods (qw(permissions));                                      # A reference to an array of permissions, a standard useful set is applied by default if none are specified.
  genLValueScalarMethods(qw(platform));                                         # Folder containing B<android.jar>. For example B<~/Android/sdk/platforms/25.0.2>
  genLValueScalarMethods(qw(platformTools));                                    # Folder containing L<adb|https://developer.android.com/studio/command-line/adb.html>
  genLValueArrayMethods (qw(sdkLevels));                                        # [minSdkVersion, targetSdkVersion], default is [15, 25]
  genLValueArrayMethods (qw(src));                                              # A reference to an array of java source files to be compiled to create this app.
  genLValueScalarMethods(qw(title));                                            # Title of app, the default is the L<package|/package> name of the app.
  genLValueScalarMethods(qw(titles));                                           # A hash of translated titles: {ISO::639 2 digit language code=>title in that language}* for this app.
  genLValueScalarMethods(qw(verifyApk));                                        # Verify the signed apk if this is true.
  genLValueScalarMethods(qw(version));                                          # The version number of the app. Default is today's date, formatted as B<YYYYMMDD>
 }

sub compile($)                                                                  # Compile the app.
 {my ($android)  = @_;                                                          # Android build
  eval {&compile2(@_)};
  if ($@)
   {$android->logMessage($@);
    return $@;
   }
  undef                                                                         # No errors encountered
 }

sub cloneApk($$)                                                                # Clone an apk file: copy the existing apk, replace the L<assets|/assets>, re-sign, zipalign, return the name of the newly created apk file.
 {my ($android, $oldApk) = @_;                                                  # Android build, the file name of the apk to be cloned
  &cloneApk2(@_);
 }

sub lint($)                                                                     # Lint all the Java source code files for the app.
 {my ($android)  = @_;                                                          # Android build
  eval {&lint2(@_)};
  if ($@)
   {$android->logMessage($@);
    return $@;
   }
  undef                                                                         # No errors encountered
 }

sub install($)                                                                  # Install an already L<compiled|/compile> app on to the selected L<device|/device>
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

Android::Build - Lint, compile, install, run an Android app using the command line tools minus Ant and Gradle thus freeing development effort from the strictures imposed by Android Studio.

=head1 Synopsis

You can see Android::Build in action in GitHub Actions at the end of:
L<https://github.com/philiprbrenan/AppaAppsGitHubPhotoApp/blob/main/genApp.pm>

=head2 Prerequisites

 sudo apt-get install imagemagick zip openjdk-8-jdk openjdk-8-jre
 sudo cpan install Data::Table::Text Data::Dump Carp POSIX File::Copy;

You will need a version of the
L<Android Build Tools|https://developer.android.com/studio/index.html>
as specified right at the end of the page below all the inappropriate
advertising for Android Studio.

Download:

  wget https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip

and unzip to get a copy of B<sdkmanager> which can be used to get the version of
the SDK that you want to use, for example:

  sdkmanager --list --verbose

Download the SDK components to be used:

  (cd  android/sdk/; tools/bin/sdkmanager         \
  echo 'y' | android/sdk/tools/bin/sdkmanager     \
   'build-tools;25.0.3' emulator 'platform-tools' \
   'platforms;android-25' 'system-images;android-25;google_apis;x86_64')

Add to these components to the B<$PATH> variable for easy command line use:

  export PATH=$PATH:~/android/sdk/tools/:~/android/sdk/tools/bin:\
  ~/android/sdk/platform-tools/:~/android/sdk/build-tools/25.0.3

Create an AVD:

 avdmanager create avd --name aaa \
   -k 'system-images;android-25;google_apis;x86_64' -g google_apis

Start the B<AVD> with a specified screen size (you might need to go into the
B<android/sdk/tools> folder):

 emulator -avd aaa -skin "2000x1000"

Running L<compile> will load the newly created L<apk> into the emulator as long
as it is the only one running.

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

If you wish to include assets with your app, either use L<buildFolder> to
specify a build area and place your assets in the B<assets> sub directory of
this folder before using L<compile> to compile your app, else use the L<assets>
keyword to specify a hash of assets to be included with your app.

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

Lint, compile, install, run an Android app using the command line tools minus Ant and Gradle thus freeing development effort from the strictures imposed by Android Studio.


Version '20201114'.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.




=head1 Index


=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Android::Build

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2019 Philip R Brenan.

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
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Test::More tests => 1;

ok 1;
