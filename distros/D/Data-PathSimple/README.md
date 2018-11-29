# NAME

Data::PathSimple - Navigate and manipulate data structures using paths

# SYNOPSIS

    use Data::PathSimple qw{
      get
      set
    };
    
    my $data = {
      Languages => {
        Perl   => {
          CurrentVersion => '5.16.1',
          URLs           => [
            'http://www.perl.org',
            'http://www.cpan.org',
          ],
        },
        PHP    => {
          CurrentVersion => '5.4.7',
          URLs           => [
            'http://www.php.net',
            'http://pear.php.net',
          ],
        },
        Python => {
          CurrentVersion => '2.7.3',
          URLs           => [
            'http://www.python.org',
          ],
        },
      },
    };

    my $current_perl = get($data, '/Languages/Perl/CurrentVersion');
    my @perl_urls    = @{ get( $data, '/Languages/Perl/URLs' ) || [] };
    
    set($data, '/Languages/Perl/CurrentVersion', '5.16.2');
    set($data, '/Languages/Python/URLs/1/', 'http://pypi.python.org');

# DESCRIPTION

Data::PathSimple allows you to get and set values deep within a data structure
using simple paths to navigate (think XPATH without the steroids).

Why do this when we already have direct access to the data structure? The
motivation is that the path will come from a user using a command line tool.

# SEE ALSO

The latest version can be found at:

&nbsp;&nbsp;&nbsp;&nbsp;[https://gitlab.com/alfiedotwtf/data-pathsimple](https://gitlab.com/alfie/data-pathsimple)

# SUPPORT

Please report any bugs or feature requests at:

&nbsp;&nbsp;&nbsp;&nbsp;[https://gitlab.com/alfie/data-pathsimple/issues](https://gitlab.com/alfie/data-pathsimple/issues)

Feel free to fork the repository and submit pull requests :)

# INSTALLATION

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

# DEPENDENCIES

* Perl v5.10.0

# AUTHOR

[Alfie John](https://www.alfie.wtf)

# WARRANTY

IT COMES WITHOUT WARRANTY OF ANY KIND.

# COPYRIGHT AND LICENSE

Perpetual Copyright (C) to Alfie John

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see [http://www.gnu.org/licenses/](http://www.gnu.org/licenses/).
