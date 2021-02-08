# NAME

App::Followme::Guide - How to install, configure, and run followme

# SYNOPSIS

    followme [directory]

# DESCRIPTION

Updates a static website after changes. Constant portions of each page are
updated to match, text files are converted to html, indexes are created
for files in the archive, and changed files are uploaded to the remote server.

The followme script is run on the directory or file passed as its argument. If
no argument is given, it is run on the current directory.

If a file is passed, the script is run on the directory the file is in. In
addition, the script is run in quick mode, meaning that only the directory
the file is in is checked for changes. Otherwise, not only that directory, but
all directories below it are checked.

# CHANGES

This version is a beta release for version two of followme. In the past the code
constructed a hash and passed it to the template, which used the values in the
hash to produce the web page. In version two the code passes an object to the
template, which calls the build method for each variable in the template, passing
the name of the variable and a filename to retrieve it from as arguments. The
module then returns the value, which is used to fill in the template. The major
user visible change is that the template syntax has changed, the new syntax is a
subset of the previous syntax. Please see [App::Followme::Template](https://metacpan.org/pod/App%3A%3AFollowme%3A%3ATemplate) for a
description of the template syntax. The second change is that the configuration
parameters of some of the modules has changed. The new configuration parameters
are described in each module. The motivation for the change is that placing the
variable building in a separate class allows more than one type of file to be
handled by modules placed in the configurarion file. Each class handles a type
of file and the name of the class which builds the variables is a configuration
parameter. The third change is that the configuration file format has changed
to use a subset of yaml. The new configuration file format is decribed below.

The beta release will be used to build a website documenting followme and the
process of building the site will be used to debug any remaining problems.
When this process is finished, the version will be bumped to 2.00.

# INSTALLATION

First, install the [App::Followme](https://metacpan.org/pod/App%3A%3AFollowme) module from CPAN. It will copy the
followme script to /usr/local/bin, so it will be on your search path.

    sudo cpanm App::Followme

Then create a folder to contain the new website. Run followme with the
init option in that directory

    mkdir website
    cd website
    followme --init

When you run followme with the --init flag, it will install the initial
templates and configuration files. The initial setup is configured to update
pages to maintain a consistent look for the site and simplify the onboarding of
new content.

The first page will serve as a prototype for the rest of your site. When you
look at the html page, you will see that it contains comments looking like

    <!-- section primary -->
    <!-- endsection primary -->

These comments mark the parts of the prototype that will change from page to
page from the parts that are constant across the entire site. Everything
outside the comments is the constant portion of the page. When you have
more than one html page in the folder, you can edit any page, run followme,
and the other pages will be updated to match it.

So you should edit your first page and add any other files you need to create
the look of your site, such as the style sheets.

You can also use followme on an existing site. Run the command

    followme --init

in the top directory of your site. The init option will not overwrite any
existing files in your site. Then look at the convert page template it has
created:

    cat _templates/convert_page.htm

Edit an existing page on your site to have all the section comments in this
template. In the template shipped with this package there are three section
names: meta, primary, and secondary. The meta section is in the html header
and contains the page metadata, although it may also contain other content
tht varies between pages. The primary section contains the page content that
is maintained by you. None of this package's modules will change it. The
secondary section contains content that is updated by the modules in this
package and you will not normally change it.

After you edit a single page, you can place the App::Followme::EditSections
module in the configuration file, after the run\_efore line:

    run_before:
        - App::Followme::EditSections
        - App::Followme::FormatPage
        - App::Followme::ConvertPage

If you then run followme, it will modify the other pages on your website to
match the page you have edited. Then remove the EditSections module from
the configuration file.

# CONFIGURATION

The configuration file for followme is followme.cfg in the top directory of
your site. Configuration file lines are in a subset of yaml format. The format
is described in [App::Followme::NestedText](https://metacpan.org/pod/App%3A%3AFollowme%3A%3ANestedText). Briefy, the top level is a hash,
with name-value pairs in the format

    name: value

There should be no space between the name and the colon and one space between
the colon and value. The value may also be an array. The array elements are listed
one per line preceded by a dash:

    name:
        - first value
        - second value

Configuration files may also contain blank lines or comment lines
starting with a `#`. Subdirectories of the top directory may also contain
configuration files. Values in these configuration files are combined with those
set in the configuration files in directories above it, If it has a parameter of
the same name as a configuration file in a higher directory, it overrides it for
that directory and its subdirectories.

Configuration files contain the names of the Perl modules to be run by followme
in the parameters named run\_before and run\_after. These parameters should be 
arrays, and thus are listed one per line indented from the field name and preceded
by a dash: 

    run_before:
        - App::Followme::FormatPage
        - App::Followme::ConvertPage
    run_after:
        - App::Followme::CreateSitemap

Perl modules are run in the order they appear in the configuration file. If they
are named run\_before then they are run before modules in any configuration files
contained in subdirectories. If they are named run\_after, they are run after
modules which are named in the configuration files in subdirectories. Other
parameters in the configuration files are written to a hash. This hash is passed
to the new method of each module as it loaded, overriding the default values of
the parameters when creating the new object.

These modules are distributed with followme:

- [App::Followme::FormatPage](https://metacpan.org/pod/App%3A%3AFollowme%3A%3AFormatPage)

    This module updates the web pages in a folder to match the most recently
    modified page. Each web page has sections that are different from other pages
    and other sections that are the same. The sections that differ are enclosed in
    html comments that look like

        <!-- section name-->
        <!-- endsection name -->

    and indicate where the section begins and ends. When a page is changed, this
    module checks the text outside of these comments. If that text has changed. the
    other pages on the site are also changed to match the page that has changed.
    Each page updated by substituting all its named blocks into corresponding block
    in the changed page. The effect is that all the text outside the named blocks
    are updated to be the same across all the web pages.

    In addition to normal section blocks, there are per folder section blocks.
    The contents of these blocks is kept constant across all files in a folder and
    all subfolders of it. If the block is changed in one file in the folder, it will
    be updated in all the other files. Per folder section blocks look like

        <!-- section name in folder_name -->
        <!-- endsection name -->

    where folder\_name is the the folder the content is kept constant across. The
    folder name is not a full path, it is the last folder in the path.

- [App::Followme::ConvertPage](https://metacpan.org/pod/App%3A%3AFollowme%3A%3AConvertPage)

    This module changes Markdown files to html files. Markdown format is described
    at:

        http://daringfireball.net/projects/markdown/

    It builds several variables and substitutes them into the page template. The
    most significant variable is body, which is the contents of the text file
    after it has been converted by Markdown. The title is built from the title of
    the Markdown file if one is put at the top of the file. If the file has no
    title, it is built from the file name, replacing dashes with blanks and
    capitalizing each word, The url and absolute\_url are built from the html file
    name. To change the look of the html page, edit the page template. Only blocks
    inside the section comments will be in the resulting page, editing the text
    outside it will have no effect on the resulting page. A complete listing of the
    variables is given in the variables section.

- [App::Followme::CreateIndex](https://metacpan.org/pod/App%3A%3AFollowme%3A%3ACreateIndex)

    This module builds an index for a directory containing links to all the files
    with the specified extension contained in it. The same variables mentioned above
    are calculated for each file, with the exception of body. Comments that look like

        <!-- for @files -->
        <!-- endfor -->

    indicate the section of the template that is repeated for each file contained
    in the index.

- [App::Followme::CreateGallery](https://metacpan.org/pod/App%3A%3AFollowme%3A%3ACreateGallery)

    Create a photo gallery for images in a directory. Each image must have a 
    thumbnail image whose name has the suffix "-thumb". The suffix name is a 
    configuration parameter. The code is very similar to 
    [App::Followme::CreateIndex](https://metacpan.org/pod/App%3A%3AFollowme%3A%3ACreateIndex), but the template is more complex, so it is a 
    separate module.

- [App::Followme::CreateRss](https://metacpan.org/pod/App%3A%3AFollowme%3A%3ACreateRss)

    This module creates an rss file from the metadata of the most recently updated 
    files in a directory. It is a companion to App::Followme::CreateIndex and should
    be used if you also want an rss file.

- [App::Followme::CreateSitemap](https://metacpan.org/pod/App%3A%3AFollowme%3A%3ACreateSitemap)

    This module creates a sitemap file, which is a text file containing the url of
    every page on the site, one per line. It is also intended as a simple example of
    how to write a module that can be run by followme.

- [App::Followme::UploadSite](https://metacpan.org/pod/App%3A%3AFollowme%3A%3AUploadSite)

    This module uploads changed files to a remote site. The default method to do the
    uploads is local copy, but that can be changed by changing the parameter upload\_pkg.
    This package computes a checksum for every file in the site. If the checksum has
    changed since the last time it was run, the file is uploaded to the remote site.
    If there is a checksum, but no local file, the file is deleted from the remote
    site. If followme is run in quick mode, only files whose modification date is
    later then the last time it was run are checked.

# RUNNING

The followme script is run on the directory or file passed as its argument. If
no argument is given, it is run on the current directory. If a file is passed,
the script is run on the directory the file is in and followme is run in
quick mode. Quick mode is an implicit promise that only the named file has
been changed since last time. Each module can make of this assumption what it
will, but it is supposed to shorten the list of files examined.

Followme looks for its configuration files in all the directories above the
directory it is run from and runs all the modules it finds in them. But they are
are only run on the folder it is run from and subfolders of it. Followme only
looks at the folder it is run from to determine if other files in the folder
need to be updated. So after changing a file, followme should be run from the
directory containing the file.
Templates support the basic control structures in Perl: "for" loops and
"if-else" blocks. Creating output is a two step process. First you generate a
subroutine from one or more templates, then you call the subroutine with your
data to generate the output.

The template format is line oriented. Commands are enclosed in html comments
(&lt;!-- -->). A command may be preceded by white space. If a command is a block
command, it is terminated by the word "end" followed by the command name. For
example, the "for" command is terminated by an "endfor" command and the "if"
command by an "endif" command.

All lines may contain variables. As in Perl, variables are a sigil character
('$' or '@') followed by one or more word characters. For example, `$name` or
`@names`. To indicate a literal character instead of a variable, precede the
sigil with a backslash. When you run the subroutine that this module generates,
you pass it a metadata object. The subroutine replaces variables in the template
with the value in the field built by the metadata object.

If the first non-white characters on a line are the command start string, the
line is interpreted as a command. The command name continues up to the first
white space character. The text following the initial span of white space is the
command argument. The argument continues up to the command end string.

Variables in the template have the same format as ordinary Perl variables,
a string of word characters starting with a sigil character. for example,

    $body @files

are examples of variables. Array variable names (variable names starting with 
a `@`) may have a suffix that indicates how the array is sorted. You can add
a suffix to a scalar variable (variable names strting with a `$`) but it
will have no effect. The format for the name is:

    @data_field[_by_$sort_field][_reversed]

the brackets are not part of the variable name. They are there to indicate that 
these sections are optional. Two examples of variables with sort suffixes are

    @files_by_size
    @all_files_by_mdate_reversed

The second suffix, \_reversed, indicates that the variable is sorted from 
largest to smallest instead of the usual format, from smallest to largest.
When used with date fields \_reversed indicates the variable is sorted from 
most recent to oldest.

The following commands are supported in templates:

- do

    The remainder of the line is interpreted as Perl code.

- for

    Expand the text between the "for" and "endfor" commands several times. The
    argument to the "for" command should be an expression evaluating to a list. The
    code will expand the text in the for block once for each element in the list.

        <ul>
        <!-- for @files -->
            <li><a href="$url">$title</a></li>
            <!-- endfor -->
            </ul>

- if

    The text until the matching `endif` is included only if the expression in the
    "if" command is true. If false, the text is skipped.

            <div class="column">
        <!-- for @files -->
        <!-- if $count % 20 == 0 -->
        </div>
            <div class="column">
        <!-- endif -->
            $title<br />
            <!-- endfor -->
            </div>

- else

    The "if" and "for" commands can contain an `else`. The text before the "else"
    is included if the expression in the enclosing command is true and the
    text after the "else" is included if the "if" command is false or the "for"
    command does not execute. You can also place an "elsif" command inside a block,
    which includes the following text if its expression is true.

# TEMPLATES

Templates are read either from the same directory as the configuration file
containing the name of the module being run or from the \_templates subdirectory
of the top directory of the site. For more information about the use of 
templates, see [App::Followme::Template](https://metacpan.org/pod/App%3A%3AFollowme%3A%3ATemplate).

# VARIABLES

Templates contain if commands, for loops and variables. The following variables 
are arrays that can be used as arguments to for loops:

- @files

    An array of files in a directory. The files in the list are controlled by the 
    configuration variables extension, exclude, and exclude\_index.

- @all\_files

    An array of all files in a directory and its subdirectories. The files are 
    controlled by the same configuration variables as @files.

- @top\_files

    An array of the most recently modified files in a directory and its 
    subdirectories. The number of files in the array is controlled by configuration
    variable list\_length. The files in the list are controlled by the same
    configuration variables as used by @files.

- @folders

    An array of subdirectories in a directory. The subdirectories in the list are
    controlled by the configuration parameter exclude\_dirs.

- @breadcrumbs

    An array of index file urls of the directories above the directory containing
    the current file.

- @related\_files

    A list of files with the same file root name as a specified file. This
    list is not filtered by the configuration variables extension and exclude.

- @newest\_file

    An array with one element, the most recently modified file in a directory
    or its subdirectories. It is an array so that other variables can be used
    inside its for loop.

The following variables can only be used inside of loops:

- @loop

    A copy of the array in the enclosing for loop. This is used to build double
    for loops over the same array.

- @thumb\_file

    An array with only one element, the name of the thumbnail file for an image file.
    It is an array so that other variables that are functions of the name can be used
    inside its for loop.

- $is\_first

    True for the first pass through the for loop, false for all following passes. Used
    in if statements.

- $is\_last

    True for the last pass through the for loop, false for all previous passes. Used in 
    if statements.

- $count

    The count of the pass through the loop. Starts at one and goes up to the number of 
    elements in the array.

- $target

    The count prefixed by a string, which is set by the configuration variable 
    target\_prefix. It is used to construct tatgets for links within a web page.

- $target\_previous

    The count of the previous pass through the for loop, prefixed by the configuration
    variable target\_prefix. It is a zero length string for the first pass through the 
    loop.

- $target\_next

    The count of the next pass through the for loop, prefixed by the configuration
    variable target\_prefix. It is a zero length string for the last pass through the 
    loop.

- $url\_previous

    The relative url of the previous file processed by the for loop. It is a zero 
    length string for the first pass through the for loop.

- $url\_next

    The relative url of the next file to be processed by the for loop. It is a zero 
    length string for the last pass through the for loop.

The following variables can be used inside or outside of for loop. If used inside,
the refer to the filename of the current iteration of the loop. If outside, they 
refer to the current file being processed.

- $remote\_url

    The absolute url of the top folder on the site on the remote system. Set by the 
    configuration variable of the same name.

- $site\_url

    The absolute url of the top folder on the site on the local system. Set by the 
    configuration variable of the same name. If the configuration variable is not
    set, it is constructed from the name of the top folder of the site.

- $url

    The url of a file, relative to the url of the top folder.

- $index\_url

    The relative url of the index file in the same folder

- $absolute\_url

    The relative url of a file prefixed by the site url.

- $url\_base

    The relative url of a file without any file extension. Used to create the urls of
    any related files.

- $name

    The name of a file.

- $extension

    The extension of a filename.

- $is\_index

    True if a file is an index file, that is, its name minus the extension is "index".
    Used in if statements.

- $date

    The creation date of a file, if available, the date of last modification, if not.
    The format of this variable is set by the configuration variable date\_format.

- $mdate

    The date of last modification of a file. The format of this variable is set by 
    the configuration variable date\_format.

- $size

    The size of the file in bytes.

- $title

    The title of a file. Constructed from the filename if it is not otherwise 
    available.

- $body

    The body text of a file.

- $summary

    A summary of the file, constructed from the first paragraph of the body.

- $description

    A description of the contents of the file, constructed from the first sentence
    of the body if it is not otherwise available.

- $keywords

    A comma separated list of keywords describing a file. Constructed from the name
    of the folder containing the file if it is not otherwise available.

- $author

    The name of the author of a file. Taken from the configuration variable of the
    same name if it is not otherwise available.

# MODULES

New modules can be written and then invoked via the configuration file, exactly
like the modules that have been distributed with App::Followme. Each module to
be run must have new and run methods. An object of the module's class is created
by calling the new method with the a reference to a hash containing the
configuration parameters. The run method is then called with the directory as
its argument.

The signature of the new method is

    $obj = $module_name->new($configuration);

where $configuration is a reference to a hash containing the configuration
parameters. $module name is the same as the name in the configuration file.

All the modules distributed with App::Followme subclass
App::Followme::Module to access its methods, which provide consistent
behavior, such as looping over files and template handling. It also supplies a
new method, so if you subclass it, you will not need to supply a new method in
your class.

The signature of the run method is

    $obj->run($directory);

where $obj is the object created by the new method and $directory is the name
of the directory the module is being run on. All modules included in
App::Followme use [App::Followme::Module](https://metacpan.org/pod/App%3A%3AFollowme%3A%3AModule) as a base class, so they can use its
methods, such as visiting all files in a directory and compiling a template. If
you wish to write your own module, you can use [App::Followme::CreateSitemap](https://metacpan.org/pod/App%3A%3AFollowme%3A%3ACreateSitemap) 
as a guide. If you use App::Followme::Module as a base class, you should not 
supply your own new method, but rely on the new method in
[App::Followme::ConfiguredObject](https://metacpan.org/pod/App%3A%3AFollowme%3A%3AConfiguredObject), which you will inherit.

# LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Bernie Simon <bernie.simon@gmail.com>
