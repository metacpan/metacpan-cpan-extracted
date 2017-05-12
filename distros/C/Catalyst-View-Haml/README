Catalyst::View::Haml - Haml View Class for Catalyst
===================================================

SYNOPSIS
--------

New to Haml? Check out [http://haml-lang.com/tutorial.html](http://haml-lang.com/tutorial.html).

This module lets you create a Haml view for your Catalyst application:

    package MyApp::View::Web;
    use Moose;
    extends 'Catalyst::View::Haml';
    

    # ...your custom code here...
    

    1;

or use the helper to create it for you:

    myapp_create.pl view Web Haml

then you can write your templates in Haml!

    #content
      .left.column
        %h2 Welcome to our site!
        %p= $information
      .right.column
        = $item->{body}

If you want to omit sigils in your Haml templates, just set the 'vars\_as\_subs'
option:

    package MyApp::View::Web;
    use Moose;
    extends 'Catalyst::View::Haml';

    has '+vars_as_subs', default => 1;

    1;

this way the Haml template above becomes:

    #content
      .left.column
        %h2 Welcome to our site!
        %p= information
      .right.column
        = item->{body}


INSTALLATION
------------

    cpan Catalyst::View::Haml

Or, manually, after downloading and unpacking:

    perl Makefile.PL
    make
    make test
    make install


SUPPORT AND DOCUMENTATION
-------------------------

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Catalyst::View::Haml

You can also look for information at:

    RT, CPAN's request tracker
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-View-Haml


AUTHOR
------

Breno G. de Oliveira, `<garu at cpan.org>`


ACKNOWLEDGEMENTS
----------------

Viacheslav Tykhanovskyi (vti) for his awesome [Text::Haml](http://search.cpan.org/perldoc?Text::Haml) implementation of
[Haml](http://haml-lang.com), the entire Haml and Catalyst teams of devs,
and Daisuke Maki (lesterrat) for Catalyst::View::Xslate, from which lots of
this code was borrowed (sometimes nearly verbatim).


LICENSE AND COPYRIGHT
---------------------

Copyright 2010-2013 Breno G. de Oliveira.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
