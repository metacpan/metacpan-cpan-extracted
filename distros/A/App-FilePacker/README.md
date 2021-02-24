# NAME

App::FilePacker - Embed a self-extracting tarball in a Perl module.

# DESCRIPTION

This program allows you to pack a directory structure into a Perl module as a
self-extracting tarball.  The newly-created module provides an `extract` method
that will allow you to unpack the tarball into a target directory.

# SYNOPSIS

Create a module called **Template::MyTemplate** in the output file **MyTemplate.pm**,
containing all of the files in **/var/www/project/templates/mytemplate**.

```perl
#!/usr/bin/env perl
use warnings;
use strict;
use App::FilePacker;

App::FilePacker->new(
   name => 'Template::MyTemplate',
   out  => 'MyTemplate.pm',
   dir  => '/var/www/project/templates/mytemplate',
)->write;
```

Do the same thing, from the command line:

    $ filepacker MyTemplate.pm Template::MyTemplate /var/www/project/templates/mytemplate

You can unpack the Template::MyTemplate in code:

```perl
#!/usr/bin/env perl
use warnings;
use strict;
use Template::MyTemplate;

Template::MyTemplate::extract('./dev/templates/mytemplate');
```

or on the command line:

    $ perl -MTemplate::MyTemplate -e'Template::MyTemplate::extract("./dev/templates/mytemplate")'

# CONSTRUCTOR

The constructor takes the following arguments:

## name

The name of the module to create, used in the package declaration.

## out (REQUIRED)

The file to write the module out to when `write` is called.

## dir (REQUIRED)

The directory that will be packed, all files and directories under this directory
will be packed into a tarball that is embedded in the data section of the module.

## module\_body

This attribute can be set to replace the body of the module if you'd like to
customize the created module.  Read the `write` function before setting this.

# METHODS

## write

Create the Perl module.

# AUTHOR

Kaitlyn Parkhurst (SymKat) _<symkat@symkat.com>_ ( Blog: [http://symkat.com/](http://symkat.com/) )

# CONTRIBUTORS

# SPONSORS

# COPYRIGHT

Copyright (c) 2021 the App::FilePacker ["AUTHOR"](#author), ["CONTRIBUTORS"](#contributors), and ["SPONSORS"](#sponsors) as listed above.

# LICENSE

This library is free software and may be distributed under the same terms as perl itself.

# AVAILABILITY

The most current version of App::FilePacker can be found at [https://github.com/symkat/App-FilePacker](https://github.com/symkat/App-FilePacker)
