# NAME

Config::NINI - NINI configuration format parser

# SYNOPSIS

    use Config::NINI qw( nini_load_file nini_parse_data );

    # Load and parse a NINI file
    my $data   = nini_load_file('config.nini');
    my $config = nini_parse_data( $data );

    # or

    my $dl = []; # debug locations
    my $data   = nini_load_file('config.nini', { DL => $dl } );
    my $config = nini_parse_data( $data, { DL => $dl, DEBUG => 1 } );

    # Access configuration
    my $value    = $config->{section_name}{key_name};
    my $arrayref = $config->{section_name}{array_key};
    my $hashref  = $config->{section_name}{subsection_name};

# DESCRIPTION

Config::NINI is a Perl module for parsing and loading configuration files in
the NINI format (Not INI). NINI extends traditional INI file concepts with
hierarchical sections, inheritance, array values, and dynamic file inclusion.

Specification, examples, notes on NINI format can be found at:

    https://github.com/cade-vs/NINI
    https://github.com/cade-vs/NINI/blob/master/nini-spec-19.txt
    https://github.com/cade-vs/NINI/blob/master/nini-examples-19.txt

## Key Features

- Trivial to write manually
- Allow hierarchical section organization
- Inheritance of keys and branches between sections
- Array value support with configurable delimiters
- Dynamic file inclusion via @include directives
- Loop detection for included files
- Debug location tracking (file and line numbers)
- Abstract section paths with auto-indexing
- Flexible path navigation and data manipulation

# INSTALLATION

Place Config::NINI in your Perl module search path (@INC). Typically:

    /usr/lib/perl/
    /usr/local/lib/perl/
    ~/perl5/lib/perl5/

Or reference it directly:

    use lib '/path/to/lib';
    use Config::NINI;

# QUICK START

Configuration file example (config.nini):

    = Database
        host      example.com
        port      5432
        user      admin
        password  secret

    = Database Cache
        & Database
        ttl       3600
        enabled   1

Perl script:

    my $config = nini_parse_data( nini_load_file( 'config.nini' ), {} );

    print $config->{Database}{host};              # example.com
    print $config->{'Database Cache'}{host};      # inherited: example.com

# FUNCTIONS

## nini\_load\_file( FILENAME, OPTIONS )

Loads a NINI configuration file from disk, processing includes and
returning raw data as array reference.

- **Arguments**
    - FILENAME

        Path to NINI file to load (string)

    - OPTIONS

        Hash reference with options:

        - DIRS

            Array ref of directories to search for @include directives

        - DL

            Array ref for debug location tracking
- **Returns**

    Array reference containing parsed file lines. This must be variable, since
    nini\_load\_file() will populate it and nini\_parse\_data() will use it to report
    warnings and errors.

- **Example**

        my $dl = [];
        my $data = nini_load_file('app.nini', {
          DIRS => ['/etc/config', '/home/user/.config'],
          DL   => $dl,  # Enable and keep debug locations tracking
        });

        my $nini = nini_parse_data( $data, { DL => $dl } );

- **Notes**
    - Automatically anchors each file to root section (=)
    - Detects and prevents file inclusion loops
    - Strips trailing whitespace from all lines
    - Returns array of configuration directives ready for nini\_parse\_data

## nini\_parse\_data( DATA, OPTIONS )

Parses processed configuration data into hierarchical hash structure.

- amaz**Arguments**
    - DATA

        Array reference (output from nini\_load\_file)

    - OPTIONS

        Hash reference with options:

        - DEBUG

            Enable debug information (boolean)

        - DL

            Array ref for debug location tracking. See nini\_load\_file() for examples and
            explanation how it works.
- **Returns**

    Hash reference containing parsed configuration structure

- **Special Keys**

    The result hash contains special metadata keys:

    - :ord

        Section sequence number (regular sections only)

    - :origin

        Array of debug location strings (if DEBUG enabled). It includes all locations
        in files where the parser went to gather keys information. Can be backtracked
        to see when values are coming from.

    - :warn

        Array of warning messages encountered

- **Example**

        my $config = nini_parse_data($data, {
          DEBUG => 1,
          DL    => $debug_locations
        });

        # Access warnings
        if ($config->{':warn'}) {
          for my $w (@{$config->{':warn'}}) {
            warn "Config warning: $w\n";
          }
        }

# NINI FORMAT SPECIFICATION

## Overview

NINI files consist of:

- Sections: Hierarchical organizational units
- Keys: Named data elements with scalar or array values
- Inheritance: Section can inherit from another section
- Comments: Lines starting with #
- Includes: Dynamic file inclusion with @include
- Paths: Whitespace-separated hierarchical navigation

File structure:

    =Section_Name
        key1    value1
        key2[,] v1, v2, v3
        key3[|] v1 | v2 | v3
        & Parent_Section

    =Section_Name  Sub_Section_Name
        & Other Sub_Section
        key4 value4
        text[]  those are space delimited 6 words

Blank lines and comment lines (starting with #) are ignored.

## Comments

Lines starting with `#` are treated as comments and ignored entirely.

Lines with content are treated as-is; there is no support for trailing/inline
comments. Unless line begins with '#', the '#' symbol is verbatim and has no
special meaning.

    # port number 5566
    port  #5566

    # anywhere in-between
    url https://www.gocomics.com/extras/first-calvin-and-hobbes-comic-strip#rulz

# SECTIONS

## Regular Sections

Marked with `=` (equals sign). Create new hierarchical branch.

    = Top_Level_Section

    = Top_Level_Section Sub_Section
      (continues in parent section by default)

    = Another_Top_Level

Whitespace-separated path components create hierarchy:

    = level1 level2 level3

Creates Perl structure:

    %hash = (
      level1 => {
        level2 => {
          level3 => { ... }
        }
      }
    );

## Abstract Sections

Marked with `*` (asterisk). Used for dynamic array-indexed branches.

    * items           # Creates branch at index 0
    key1 value1

    * items           # Creates branch at index 1
    key2 value2

Creates structure:

    items => {
      *0 => { key1 => 'value1' },
      *1 => { key2 => 'value2' }
    }

Auto-indexing with `*` wildcard in path:

    = data *
    name Widget A

Expands `*` to next available integer index. Integer indexes are not required
to be continuous. If there are 1, 5, 16 the next auto-index will be 17 etc.

## Section Modifiers

Delete section contents using `!` operators:

- `!`

    Delete all keys.

- `!!`

    Delete all sub-section branches.

- `!!!`

    Delete everything (keys and branches)

Example:

    = Section
    key1 value1
    branch_name branch_data

    = Section
    !!
    # only key1 left

# KEYS AND VALUES

## Key Syntax

    [+|-]KEY[ARRAY][WHITESPACE]VALUE

Components:

- \[+|-\]

    Operator (optional) - Add or remove operation

- KEY

    Key name (required)

    Pattern: `[a-zA-Z0-9_:\/][a-zA-Z0-9:._\/-]*`

- \[X\]

    Array indicator with delimiter (optional)

- VALUE

    Data value (optional, defaults to '1' if omitted)

Examples:

    key1                    # Scalar, value = '1'
    key2 hello world        # Scalar, value = 'hello world'
    key3 [,] a,b,c          # Array, comma-separated
    key4 [|] x|y|z          # Array, pipe-separated
    key5 [ ] space separated # Array, space-separated
    +key6 append_value      # Add operation (modifier)

## Delimiters

Array delimiter specified in `[X]` where X is:

- `,`

    Comma

- `|`

    Pipe

- `;`

    Semicolon

- `:`

    Colon

- (empty)

    Whitespace (implicit)

### Quote Handling

- Single quotes (`'`)

    Preserve content, remove quotes

- Double quotes (`"`)

    Preserve content, remove quotes

- Pipe quotes (`|`)

    Preserve content, remove quotes

- Escaped quotes (`""`)

    Become single quote in output

## Value Parsing

Whitespace handling:

- Leading/trailing whitespace stripped
- Quoted values preserve internal whitespace

Examples:

    key1     value with spaces
    key2 "  quoted value  "
    key3 "#hash_included"

Results:

    key1 => 'value with spaces'
    key2 => '  quoted value  '
    key3 => '#hash_included'

# ARRAYS

## Array Declaration

Arrays specified with delimiter in brackets:

    array_name [DELIMITER] item1 DELIMITER item2 DELIMITER item3

Returns Perl array reference.

Access in code:

    my @items = @{$config->{section}{array_name}};
    my $count = scalar @{$config->{section}{array_name}};
    my $first = $config->{section}{array_name}->[0];

## Whitespace-Separated Arrays

Using space as implicit delimiter:

    array_name[] one two three four

Results in:

    array_name => ['one', 'two', 'three', 'four']

## Single-Character Delimiters

All delimiters are single-character:

    ports[,] 8080,8081,8082,8443
    formats[|] json|xml|csv|yaml
    paths[:] /etc:/opt:/home

## Quote Handling in Arrays

Quotes included in array delimiters:

    items[,] "first item", 'second item', third

Results in:

    items => ['first item', 'second item', 'third']

# INHERITANCE

## Basic Inheritance

Sections can inherit from other sections using `&` operator.

    = Base
    key1 value1
    key2 value2

    = Derived_Section
    & Base
    key3 value3

Derived Section inherits `key1` and `key2` from Base Section.

Result:

    'Derived_Section' => {
      key1 => 'value1',  # inherited
      key2 => 'value2',  # inherited
      key3 => 'value3'   # own
    }

## Inheritance Levels

Multiple `&` specifiers control inheritance depth:

- `& SOURCE`

    Inherit keys only

- `&& SOURCE`

    Inherit branches only (deep copy, no keys at the same level)

- `&&& SOURCE`

    Inherit keys AND branches. Any number of '&'s beyond 2 is the same.

## Selective Inheritance

    = Parent
        key1 value1
        sub_branch sub_data

    = Child
        & Parent                # Inherits key1 only
        && Parent               # Inherits sub_branch only
        &&& Parent              # Inherits both

## Inherited Branch Structure

When inheriting branches (`&&`), nested structures are deep-copied:

    = Source
        nested parent_value

    = Target
        && Source               # Copies entire nested structure

Resulting structure:

    Target => {
      nested => { ... }     # Deep copy, modifications don't affect Source
    }

## Inheritance Loops

Since inheritance is a deep copy, loops are allowed but may lead to not
obvious results.

    = A
        asd 999
        & A
        # no-op, silent, warning if debug

    = B
        qwe 333
        & A
        # ok

    = A
        & B
        # still ok since deep copy, now both A and B will have asd and qwe keys

# INCLUDE DIRECTIVES

## File Inclusion

Include other NINI files with `@include`:

    @include filename.nini
    @include /path/to/config.nini

Syntax variations:

    @include filename.nini
    @include path/to/file.nini
    @include /absolute/path/file.nini

## Directory Search

Specify search directories in OPTIONS:

    my $config = nini_parse_data(
      nini_load_file('main.nini', {
        DIRS => [
          '/etc/app',
          '/opt/app/config',
          '/home/user/.app'
        ]
      }),
      {}
    );

If `@include` uses relative path, directories are searched in order.
First match wins. Absolute paths (starting with `/`) used directly.

## Include Context

When including a file, the context will be forced to be the root section.
When exit included file, the previous secont will be restored. This is needed
so that all keys at the beginning of the included file will not be injected
into the current section of the base file and all keys after the include
will not be attached into the last section of the include file:

    = Mid_Section
        # all leading keys of included.nini will be forced to be in the root
        @include included.nini
        # key1 will be into "Mid_Section", not in the last open section in
        # included.nini
        key1 value1

This behaviour was selected to match close the "what you (probably) expect is
what you get" :)

## Loop Detection

Circular includes are detected and prevented:

    # file1.nini
    @include file2.nini

    # file2.nini
    @include file1.nini

Attempting to load file1.nini will error:

    nini: error: file load: loop detected for file [file1.nini]

## Include Failure Handling

If included file not found:

- Silent skip (no error, warning if debug)
- Processing continues with next line
- No explicit error message (can enable via DEBUG)

# PATH RESOLUTION

## Path Navigation

Paths are whitespace-separated section names:

    = level1 level2 level3
    key value

Creates:

    level1/level2/level3/key => value

## Path Syntax

Valid path elements:

    [A-Za-z0-9:._\/-]+       # Alphanumeric with special chars
    *                        # Auto-index wildcard
    !                        # Delete key modifier
    !!                       # Delete branch modifier
    !!!                      # Delete all modifier

## Deleting Path Elements

Single `!` deletes matching keys:

    = section
        # Remove all keys in section, mostly for debug or temporary purpose
        !

Double `!!` deletes matching branches:

    = section
        # Remove all branches
        !!

Triple `!!!` deletes both:

    = section
        # Remove everything
        !!!

## Auto-Indexing with \*

Wildcard `*` finds next available numeric index:

    = items  *
        name First

    = items  *
        name Second

Sections become:

    'items' => {
      1 => { name => 'First' },
      2 => { name => 'Second' }
    }

# OPTIONS AND DEBUG TRACKING

## Load Options

`nini_load_file` OPTIONS hash:

- DIRS

    Array ref of directories for `@include` search

- DL

    Array ref to collect debug locations

Example:

    my @locations;
    my $data = nini_load_file('app.nini', {
      DIRS => ['/etc', '/home/user'],
      DL   => \@locations
    });

    # @locations now contains file:line information for each line

## Parse Options

`nini_parse_data` OPTIONS hash:

- DEBUG

    Enable debug collection (boolean)

- DL

    Array ref for debug location strings

Example:

    my @locations;
    my $config = nini_parse_data($data, {
      DEBUG => 1,
      DL    => \@locations
    });

## Debug Information

- :ord

    Integer sequence number (regular sections only).
    Reflects section order in file.

- :origin

    Array ref of location strings.
    Each location: "filename line N" or "filename top/bottom"

    Exists only when DEBUG is enabled.

- :warn

    Array ref of warning messages.
    Includes unresolved inherits, self-reference attempts, etc.

    Exists only when DEBUG is enabled.

Accessing debug info:

    for my $origin (@{$config->{section}{':origin'}}) {
      print "Defined at: $origin\n";
    }

    if (exists $config->{':warn'}) {
      for my $warning (@{$config->{':warn'}}) {
        warn "Config warning: $warning\n";
      }
    }

## Error Messages

Error messages include context:

    nini: error: file load: loop detected for file [FILE]
    nini: error: syntax error in data [LINE] at LOCATION
    nini: error: unrecognisable data [LINE] at LOCATION
    nini: error: cannot inherit parent branch into current at LOCATION

# EXAMPLES

## Simple Configuration

File: `database.nini`

    = Database
    host        localhost
    port        5432
    user        dbuser
    password    secure_pass
    options[,] ssl,compression,timeout

Perl:

    my $cfg = nini_parse_data( nini_load_file( 'database.nini' ) );

    print $cfg->{Database}{host};      # localhost
    print $cfg->{Database}{port};      # 5432

    my @opts = @{$cfg->{Database}{options}};
    # @opts = ('ssl', 'compression', 'timeout')

## Hierarchical Configuration

File: `app.nini`

    = Application
        name    MyApp
        version 1.0

    = Application Database
        host    db.example.com
        port    5432

    = Application Cache
        enabled 1
        ttl     3600

Perl:

    my $cfg = nini_parse_data( nini_load_file('app.nini') );

    print $cfg->{Application}{name};
    print $cfg->{Application}{Database}{host};
    print $cfg->{Application}{Cache}{enabled};

## Inheritance

File: `servers.nini`

    = Default Server
        user          ubuntu
        ssh_key_file  /home/ubuntu/.ssh/id_rsa
        timeout       30

    = Production Web Server
      & Default Server
      hostname      prod-web-01
      ip_address    192.168.1.100
      cpu_count     8

    = Staging Web Server
      & Default Server
      hostname      staging-web-01
      ip_address    192.168.1.101
      cpu_count     4

Perl:

    my $cfg = nini_parse_data( nini_load_file('servers.nini') );

    my $prod = $cfg->{'Production Web Server'};
    print $prod->{user};        # Inherited: ubuntu
    print $prod->{hostname};    # Own: prod-web-01
    print $prod->{timeout};     # Inherited: 30

## Arrays and Delimiters

File: `services.nini`

    = Services
        tcp_ports[,] 22,80,443,8080
        http_methods[|] GET|POST|PUT|DELETE
        workers[] worker1 worker2 worker3

Perl:

    my $cfg = nini_parse_data( nini_load_file('services.nini') );

    my @tcp = @{ $cfg->{Services}{tcp_ports} };
    # @tcp = ('22', '80', '443', '8080')

    my @methods = @{$cfg->{Services}{http_methods}};
    # @methods = ('GET', 'POST', 'PUT', 'DELETE')

    my @w = @{ $cfg->{Services}{workers} };
    # @w = ('worker1', 'worker2', 'worker3')

## File Inclusion

File: `main.nini`

    = Application
        name MyApp

        @include database.nini
        @include services.nini

File: `database.nini`

    = Application Database
        host localhost
        port 5432

File: `services.nini`

    = Application Services
        api_port 8000

Perl:

    my $cfg = nini_parse_data(
      nini_load_file('main.nini', {
        DIRS => ['.']
      }),
      {}
    );

    print $cfg->{Application}{name};
    print $cfg->{Application}{Database}{host};
    print $cfg->{Application}{Services}{api_port};

## Abstract Sections and Auto-Indexing

File: `items.nini`

    inventory *
          name      Laptop
          quantity  5
          price     1200

    inventory *
          name      Mouse
          quantity  25
          price     50

    inventory *
          name      Monitor
          quantity  10
          price     350

Perl:

    my $cfg = nini_parse_data(
      nini_load_file('items.nini'),
      {}
    );

    # Access by numeric index
    for my $i (0..2) {
      my $key = "$i";
      my $item = $cfg->{inventory}{$key};
      print "$item->{name}: $item->{quantity}\n";
    }

Output:

    Laptop: 5
    Mouse: 25
    Monitor: 10

## Debug Information

File: `config.nini`

    = Section1
        key1 value1

    = Section2
        & NonExistent

Perl:

    my @locations;
    my $cfg = nini_parse_data(
      nini_load_file('config.nini', { DL => \@locations }),
      { DEBUG => 1, DL => \@locations }
    );

    # Check for warnings
    if (exists $cfg->{':warn'}) {
      for my $w (@{$cfg->{':warn'}}) {
        print "Warning: $w\n";
      }
    }

Output:

    Warning: cannot find path to inherit [NonExistent] at config.nini line 5

# ERROR HANDLING

## Fatal Errors

Parser dies on:

- Syntax errors in key/value lines
- Unrecognizable data format
- File load loop detection
- Invalid inheritance (circular references)
- Self-inheritance attempts

Use eval to catch:

    my $cfg;
    eval {
      $cfg = nini_parse_data(
        nini_load_file('config.nini'),
        {}
      );
    };

    if ($@) {
      die "Failed to load config: $@\n";
    }

## Non-Fatal Issues

Warnings collected in `:warn` key:

- Cannot find path to inherit
- Self-inheritance attempted
- Invalid optional syntax

Access warnings:

    if (exists $config->{':warn'}) {
      for my $warning (@{$config->{':warn'}}) {
        warn "Config issue: $warning\n";
      }
    }

## Common Issues and Solutions

### Value contains # character

Solution: Quote the value

    key1 "#important"       # Value is: #important
    key2 "URL: http://..."  # Value is: URL: http://...

### Array parsing fails

Solution: Ensure separator is single character and matches usage

    correct:   items [,] a,b,c
    wrong:     items [,] a, b, c   # Spaces included in values
    solution:  items [,] a, b, c   # Use proper format

### Include file not found

Solution: Verify DIRS paths or use absolute paths

    Relative:  @include config.nini
    Absolute:  @include /etc/app/config.nini

### Inheritance path not found

Solution: Ensure section exists and is defined before use

    = Parent Section
    key1 value1

    = Child Section
    & Parent Section
    key2 value2

# DEPENDENCIES

NINI uses dclone() from Storable module.

# AUTHOR

Copyright: 2026 (c) Vladi Belperchinov-Shabanski "Cade" <cade@noxrun.com>

# LICENSE

This module is distributed under the terms of the GNU General Public License,
version 2 (GPLv2). See http://www.gnu.org/licenses/gpl-2.0.html for details.
