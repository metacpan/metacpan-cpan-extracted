# Apache::Session::MongoDB

## NAME

Apache::Session::MongoDB - An implementation of Apache::Session

## SYNOPSIS

    use Apache::Session::MongoDB;
     
    tie %hash, 'Apache::Session::MongoDB', $id, {
       Host => 'locahost',
       Port => 27017
    };

## DESCRIPTION

This module is an implementation of Apache::Session. It uses the MongoDB
backing store and no locking. See the example, and the documentation for
Apache::Session::Store::MongoDB for more details.

## SEE ALSO

[Apache::Session](https://metacpan.org/pod/Apache::Session)

## AUTHOR

Xavier Guimard, <x.guimard@free.fr>

##COPYRIGHT AND LICENSE

Copyright &copy;2015-2016 by Xavier Guimard, <x.guimard@free.fr>


This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.10.0 or, at
your option, any later version of Perl 5 you may have available.

## INSTALLATION

As usual

    perl Makefile.PL
    make
    make test
    sudo make install
