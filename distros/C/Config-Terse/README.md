# NAME

Config::Terse is laconic configuration files parser.

# SYNOPSIS

    #!/usr/bin/perl
    use strict;
    use Config::Terse;

    my $cfg = terse_config_load( 'try.cfg' );

    use Data::Dumper;
    print Dumper( $cfg );

# DESCRIPTION

Config::Terse parses configuration files with very compact syntax, which 
may seem rude or unfriendly. It provides sections with keyword/value pairs, 
sections inheritance and named groups of sections.

Each line in the config file contains whitespace-delimited key and value:

    key         value
    anotherkey  other value
    koe         ne se chete

Sections begin with equal sign on new line, followed by the section name:

    =newsection
    

    sectionkey1  value
    newkey       value

Sections may inherit other sections. Inherited sections are specified with 
plus sign and name after the section name:

    =newsection  +othersection1  +othersection2  ...

Sections may be grouped in groupss. Group names are specified with "at" sign (@)
followed by the group name, after the section name:

    =apple  @fruits
    

Inheritance and groups can be combined but order is important! All inherited
sections specified before group is taken from the main (root) sections.
Inherited sections after group name is taken from the same group (if such
exists. 

Sections can be added to multiple groups. They will be linked together and
changing one section key will be visible in the other groups.

Here is an example:

    =green
      color  green
      

    =tree  @fruits
      isatree  yes
      

    =apple +green  @fruits  +tree
      name  this is a green apple tree
      

The "apple" section will inherit "green" section, then will be put in the
"fruits" group and finally will inherit the "tree" section from "fruits".

All section and key names are converted to upper case by default.

The result perl hash structure for all the examples combined will be:

    $VAR1 = {
              'GREEN' => {
                           'COLOR' => 'green'
                         },
              'MAIN' => {
                          'ANOTHERKEY' => 'other value',
                          'KEY' => 'value',
                          'KOE' => 'ne se chete'
                        },
              'FRUITS' => {
                            'TREE' => {
                                        'ISATREE' => 'yes'
                                      },
                            'APPLE' => {
                                         'COLOR' => 'green',
                                         'NAME' => 'this is a green apple tree',
                                         'ISATREE' => 'yes'
                                       }
                          },
              'NEWSECTION' => {
                                'SECTIONKEY1' => 'value',
                                'NEWKEY' => 'value'
                              }
            };

Default section name is 'MAIN'. It is used for keys in files without any 
sections or for keys in the leading part of a file where no section has been 
defined yet. Default section name can be changed with 'MAIN' option and will 
be modified by the 'CASE' option. See 'OPTIONS' section below.

# OPTIONS

Few options can be added when loading new config file:

      # make all sections and keys names upper case (default)
      my $cfg = terse_config_load( 'try.cfg', CASE => 'UC' );
    

    # make all sections and keys names lower case
    my $cfg = terse_config_load( 'try.cfg', CASE => 'LC' );

    # leave all sections and keys names asis, no case conversion
    my $cfg = terse_config_load( 'try.cfg', CASE => 'NC' );

    # keep sections and keys in the order they were seen
    my $cfg = terse_config_load( 'try.cfg', ORDERED => 1 );

    # set MAIN section name
    my $cfg = terse_config_load( 'try.cfg', MAIN => '*' );

    # combined options
    my $cfg = terse_config_load( 'try.cfg', CASE    => 'LC', 
                                            MAIN    => '*', 
                                            ORDERED => 1 );

# GITHUB REPOSITORY

    https://github.com/cade-vs/perl-config-terse
    

    git clone git://github.com/cade-vs/perl-config-terse.git

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"

    <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>

    http://cade.datamax.bg
