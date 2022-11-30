# Alien-Bazel
Alien::Bazel, Use Perl To Build The Google Bazel Build System On Any Platform

## Description
Alien::Bazel is a Perl distribution, and is meant to be installed as a prerequisite for other Perl distributions (especially other Aliens) which rely on the Bazel build system.  The sole functionality of this distribution is to check if Bazel is already installed, and if not then to build and install it.

## Installation, Download Binary
```
# NOTE: option of non-source install will download pre-built binary from Bazel development team
$ export ALIEN_BAZEL_FROM_SOURCE=0  # optional, defaults to 0
$ cpanm Alien::Bazel
```

## Installation, Build Source Code
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

# WARNING: option of source code install AKA share build AKA Bazel bootstrap can take up to 45 minutes & 2.5 gigabytes storage or more
$ export ALIEN_BAZEL_FROM_SOURCE=1
$ cpanm Alien::Bazel
```

## Developers Only
```
# install static dependencies
$ dzil authordeps | cpanm
$ dzil listdeps | cpanm

# document changes & insert copyrights before CPAN release
$ vi Changes       # include latest release info, used by [NextRelease] and [CheckChangesHasContent] plugins
$ vi dist.ini      # update version number
$ vi FOO.pm foo.t  # add "# COPYRIGHT" as first  line of file, used by [InsertCopyright] plugin
$ vi foo.pl        # add "# COPYRIGHT" as second line of file, used by [InsertCopyright] plugin

# build & install dynamic dependencies & test before CPAN release
$ dzil build
$ ls -ld Alien-Bazel*
$ cpanm --installdeps ./Alien-Bazel-FOO.tar.gz  # install dynamic dependencies for share (non-system) build, including Mozilla::CA
$ dzil test  # needs all dependencies installed by above `cpanm` commands

# inspect build files before CPAN release
$ cd Alien-Bazel-FOO
$ ls -l
$ less Changes 
$ less LICENSE 
$ less COPYRIGHT
$ less CONTRIBUTING
$ less MANIFEST 
$ less README.md 
$ less README
$ less META.json 
$ less META.yml

# make CPAN release
$ git add -A; git commit -av  # CPAN Release, vX.YYY; Codename FOO, BAR Edition
$ git push origin main
$ dzil release
$ git add -A; git commit -av  # CPAN Release, vX.YYY; Changes Auto-Update
$ git push origin main
$ git tag -l
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
