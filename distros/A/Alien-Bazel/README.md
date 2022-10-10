# Alien-Bazel
Alien::Bazel, Use Perl To Build The Google Bazel Build System On Any Platform

## Description
Alien::Bazel is a Perl distribution, and is meant to be installed as a prerequisite for other Perl distributions (especially other Aliens) which rely on the Bazel build system.  The sole functionality of this distribution is to check if Bazel is already installed, and if not then to build and install it.

## Installation
```
# old Ubuntu v16.04 only, install Bazel dependency JDK 11
# https://stackoverflow.com/questions/52504825/how-to-install-jdk-11-under-ubuntu
$ sudo add-apt-repository -y ppa:openjdk-r/ppa
$ sudo apt-get update
$ sudo apt-get install openjdk-11-jdk
$ export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
$ jvm -version

# install Bazel dependencies
# https://bazel.build/install/compile-source#bootstrap-bazel
$ sudo apt-get install build-essential openjdk-11-jdk zip unzip python2
# OR 
$ sudo apt-get install build-essential openjdk-11-jdk zip unzip python3

# WARNING: share build AKA Bazel bootstrap can take up to 45 minutes & 2.5 gigabytes storage or more
$ cpanm Alien::Bazel
```

## Developers Only
```
$ dzil authordeps --missing | cpanm
$ dzil listdeps --missing | cpanm
```

## Original Creation
Alien::Bazel was originally created via the following commands:

```
# normal installation procedure for minting profile
$ cpanm Dist::Zilla::MintingProfile::AlienBuild

# normal minting procedure
https://github.com/bazelbuild/bazel/releases
$ dzil new -P AlienBuild Alien::Bazel
[DZ] making target dir .../repos_gitlab/Alien-Bazel
Enter the full URL to the latest tarball (or zip, etc.) of the project you want to alienize.
>  https://github.com/bazelbuild/bazel/releases/download/6.0.0-pre.20220823.1/bazel-6.0.0-pre.20220823.1-dist.zip
What is the human project name of the alienized package?
>  bazel
What use cases will this Alien provide?  You may choose more than one: tool
Which pkg-config names (if any) should be used to detect system install?  You may space separate multiple names.
>  
Do you want to install the specific version from the URL above, or the latest version? latest
Multiple build systems were detected in the tarball; select the most reliable one of: autoconf cmake make
Choose build system. manual
[:DefaultModuleMaker] making module lib/Alien/Bazel.pm from template
[:DefaultModuleMaker] making alienfile from template
[:DefaultModuleMaker] making t/alien_bazel.t from template
[DZ] writing files to .../repos_gitlab/Alien-Bazel
[DZ] dist minted in ./Alien-Bazel

# manually edit alienfile

# test build procedure
$ cpanm App::af
$ cpanm Archive::Zip
$ cpanm Sort::Versions
$ cpanm Alien::Build::Plugin::Download::GitHub
$ af install --dry-run
```
