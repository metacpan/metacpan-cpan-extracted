# NAME

mkpkgconfig - create pkg-config metadata files

# VERSION

version v2.0.2

# SYNOPSIS

mkpkgconfig _options_

# DESCRIPTION

**mkpkgconfig** creates a **pkg-config** metadata (`.pc`) file.
**pkg-config** variables and keywords are defined on the command line,
variable dependencies are validated, and the configuration file is output.
"Standard" variables (such as `$libdir`, `$datadir`) may be automatically
created, and only variables which are used are output.

## Variables and Keywords

**pkg-config** distinguishes between _variables_ and _keywords_. Values for both may include
interpolated variables, as in `Cflags: -I ${include}`.

Some commonly used variables have dedicated command line options:

    --prefix     : base prefix for paths
    --package    : filesystem compatible package name
    --modversion : package version

(`--modversion` sets the _version_ variable; the `--version` flag will output the version of `mkpkgconfig`).

`--modversion` is required.  `--prefix` and `--package` may be
required if a keyword requires them or `--auto` is set and
auto-generated variables require it.

Common keywords also have dedicated options:

    --Name
    --Conflicts
    --Description
    --Requires
    --Libs
    --Cflags
    --URL

The `--Name` and `--Description` options are required. The
`Version` keyword is automatically set to `${version}`. It is
not possible to set it directly from the command line.

Other variables and keywords may be specified via the `--var` and
`--kwd` options, respectively:

    --var name=value
    --kwd name=value

which may be used more than once.

## Automatically Generated Variables

`mkpkgconfig` can automatically generate a number of "standard"
variables, such as _bindir_, _libdir_, etc, based upon the _prefix_
variable.  Use the ["--list-auto"](#list-auto) option to output a list of these
variables.

# OPTIONS

## General Options

- --output

    Where the configuration file is to be written.  It defaults to the
    standard output stream.

- --usevars `all`|`requested`|`needed`

    Which variables should be output.  It defaults to `needed`.

    - `all`

        output all variables, needed or not, including automatically generated
        ones if `--auto` was specified;

    - `requested`

        output only requested variables (via-`-var variable=value` or `--auto=variable,...`) and keyword dependencies;

    - `needed`

        output only those variables actually used by keywords

## Variables

- `--var` _name_=_value_

    Set the variable named _name_ to _value_.

- `--prefix` _value_

    Set the `prefix` variable.

- `--package` _value_

    Set the `package` variable

- `--modversion` _value_

    Set the `version` value

- `--auto`
- `--auto` _list of variables_

    Generate a set of variables.  Use `--list-auto` to see what is generated.

    If passed a list of variable names, those will be output if `--usevars` is set to `requested`.

    Individual variables may be overriden using `--var`.

- `--list-auto`

    Output a list of the automatically generated keywords and exit.

### Keywords

- `--kwd` _name_=_value_

    Set the keyword named _name_ to _value_.

- `--Name`  _value_
- `--name` _value_

    Set the _Name_ keyword.
    This parameter is required.

- `--Description` _value_
- `--description` _value_

    Set the _Description_ keyword.
    This parameter is required.

- `--Requires` _value_
- `--requires` _value_

    Set the _Requires_ keyword.

- `--Conflicts` _value_
- `--conflicts`  _value_

    Set the _Conflicts_ keyword.

- `--Libs` _value_
- `--libs`  _value_

    Set the _Libs_ keyword.

- `--Cflags` _value_
- `--cflags`  _value_

    Set the _Cflags_ keyword.

## Miscellaneous

- --version

    Output the version of **mkpkgconfig** and exit.

- --help

    Output a short help message and exit.

- --manual

    Output the manual and exit.

# SUPPORT

## Bugs

Please report any bugs or feature requests to bug-app-mkpkgconfig@rt.cpan.org  or through the web interface at: [https://rt.cpan.org/Public/Dist/Display.html?Name=App-mkpkgconfig](https://rt.cpan.org/Public/Dist/Display.html?Name=App-mkpkgconfig)

## Source

Source is available at

    https://codeberg.org/djerius/p5-App-mkpkgconfig

and may be cloned from

    https://codeberg.org/djerius/p5-App-mkpkgconfig.git

# AUTHOR

Diab Jerius <djerius@sao.si.edu>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
