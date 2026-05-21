[![Releasing](https://github.com/cnangel/Conf-Libconfig/actions/workflows/release-workflow.yml/badge.svg)](https://github.com/cnangel/Conf-Libconfig/actions/workflows/release-workflow.yml)
[![Testing](https://github.com/cnangel/Conf-Libconfig/actions/workflows/test.yml/badge.svg)](https://github.com/cnangel/Conf-Libconfig/actions/workflows/test.yml)

# Conf-Libconfig

Perl bindings to the C library libconfig

## INSTALLATION

* First install libconfig and its development files.

  * RHEL(<8) or Centos(<8) :

    ```
    yum install libconfig libconfig-devel -y
    ```

  * RHEL(>=8) or Centos(>=8) :

    ```
    dnf install libconfig libconfig-devel -y
    ```
  * Debian or Ubuntu:
    ```
    apt-get libconfig libconfig-dev -y
    ```

  * openSUSE:
    ```
    # available in the Packman repository
    zypper install libconfig8 libconfig-devel
    ```

* On other platforms, you can compile libconfig from source: https://hyperrealm.github.io/libconfig/




## Instructions:
* Install libconfig from source:
  ```
  wget https://hyperrealm.github.io/libconfig/dist/libconfig-1.8.2.tar.gz
  tar -zxf libconfig-1.8.2.tar.gz
  cd libconfig-1.8.2
  export MYPREFIX=/usr
  # or if you lack privileges for making system-wide changes:
  # export MYPREFIX=$HOME/local
  ./configure --prefix=$MYPREFIX
  make
  make install
  ```

* To install this module, run the following commands:
  ```
  perl Makefile.PL
  # or if you use a self-compiled libconfig as above:
  # perl Makefile.PL LIBS=-L$MYPREFIX/lib INC=-I$MYPREFIX/include
  make
  # If not using en_US system, you must set export LC_ALL=en_US.UTF-8
  make test
  make install
  ```

## SUPPORT AND DOCUMENTATION

* After installing, you can find documentation for this module with the
perldoc command.
```
    perldoc Conf::Libconfig
```
* You can also look for information at:

  - RT, CPAN's request tracker
    - http://rt.cpan.org/NoAuth/Bugs.html?Dist=Conf-Libconfig

  - AnnoCPAN, Annotated CPAN documentation
    - http://annocpan.org/dist/Conf-Libconfig

  - CPAN Ratings
    - http://cpanratings.perl.org/d/Conf-Libconfig

  - Search CPAN
    - http://search.cpan.org/dist/Conf-Libconfig/

## COPYRIGHT AND LICENCE

* Copyright (c) 2009, Alibaba Search Center, Alibaba Inc. All rights reserved.

* Copyright (C) 2009-2026 cnangel

* This program is released under the following license: bsd
