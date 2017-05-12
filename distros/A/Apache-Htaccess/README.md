
# Apache::Htaccess [![Build Status](https://travis-ci.org/archeac/apache-htaccess.svg?branch=master)](https://travis-ci.org/archeac/apache-htaccess)

### Name
Apache::Htaccess - Create and modify Apache .htaccess files

### Installation
To install from CPAN
```
cpan Apache::Htaccess
```
To install from source
```
perl Makefile.PL
make
make test
make install
```

### Synopsis

```perl
use Apache::Htaccess;
 
my $obj = Apache::Htaccess->new("htaccess");
die($Apache::Htaccess::ERROR) if $Apache::Htaccess::ERROR;
 
$obj->global_requires(@groups);
 
$obj->add_global_require(@groups);
 
$obj->directives(CheckSpelling => 'on');
 
$obj->add_directive(CheckSpelling => 'on');
 
$obj->requires('admin.cgi',@groups);
 
$obj->add_require('admin.cgi',@groups);
 
$obj->save();
die($Apache::Htaccess::ERROR) if $Apache::Htaccess::ERROR;

```
### Description

This module provides an object-oriented interface to Apache .htaccess files. Currently the ability exists to read and write simple htaccess files.

### Methods

#### new()
```perl
my $obj = Apache::Htaccess->new($path_to_htaccess);
```
Creates a new Htaccess object either with data loaded from an existing htaccess file or from scratch

#### save()
```perl
$obj->save();
```
Saves the htaccess file to the filename designated at object creation. This method is automatically called on object destruction.

#### global_requires()
```perl
$obj->global_requires(@groups);
```
Sets the global group requirements. If no params are provided, will return a list of the current groups listed in the global require. Note: as of 0.3, passing this method a parameter list causes the global requires list to be overwritten with your parameters. see add_global_require().

#### add_global_require()
```perl
$obj->add_global_require(@groups);
```
Sets a global require (or requires) nondestructively. Use this if you just want to add a few global requires without messing with all of the global requires entries.

#### requires()
```perl
$obj->requires($file,@groups);
```
Sets a group requirement for a file. If no params are given, returns a list of the current groups listed in the files require directive. Note: as of 0.3, passing this method a parameter list causes the requires list to be overwritten with your parameters. see add_require().

#### add_require()
```perl
$obj->add_require($file,@groups);
```
Sets a require (or requires) nondestructively. Use this if you just want to add a few requires without messing with all of the requires entries.

#### directives()
```perl
$obj->directives(CheckSpelling => 'on');
```
Sets misc directives not directly supported by the API. If no params are given, returns a list of current directives and their values. Note: as of 0.2, passing this method a parameter list causes the directive list to be overwritten with your parameters. see add_directive().

#### add_directive()
```perl
$obj->add_directive(CheckSpelling => 'on');
```
Sets a directive (or directives) nondestructively. Use this if you just want to add a few directives without messing with all of the directive entries.

### TODO
* rewrite the parser to handle blocks
* improve documentation
* Oracale iPlanet htaccess parser

### Author(s)
Matt Cashner <matt@cre8tivegroup.com> originally created this module.
brian d foy <bdfoy@cpan.org> maintained it for a long time.

Now this module is maintained by Arun Venkataraman <arun@cpan.org>

### Copyright

Copyright (C) 2016 Arun Venkataraman

This module may be distributed under the terms of Perl itself.
