cpanthanks
==========

Thank a CPAN author today!

This program will parse all perl files/modules from a given list of directories
to try and find module authors to thank for. If you can, please find the time
to thank every author whose module helped you in your projects/work :D


#### Installation ####

From CPAN:

    cpanm App::cpanthanks

From within this repository:

    cpanm .

### Usage ###

    cpanthanks [options] -- path [, path2, ...]

    Options:
        --limit NUMBER                     only shows top NUMBER entries (default: 5)
        --order-by popularity|diversity    order your results (default: popularity)
        --skip-modules LIST                skip modules (default: lib strict warnings)
        --skip-authors LIST                skip authors (default: none skipped)


### Examples ###

    cpanthanks --skip-authors MYCPANID --limit 3 -- some/path other/path
    cpanthanks --order-by=diversity -- my/project/path


THANKS!
-------

This tiny app would not be possible without the incredible developers who
wrote the modules that it depends on! So...

* Thank you **Masaaki Goshima** for Compiler::Lexer!

*  Thank you **David Golden** for Path::Class::Rule!

*  Thank you **Mickey Nasriachi** and **Sawyer** for MetaCPAN::Client!

*  Thank you **Tatsuhiko Miyagawa** and **Audrey Tang** for Term::Encoding!

*  Thank you **Russ Allbery** for Term::ANSIColor!

*  Thank you **Jean-Louis Morel** for Win32::Console::ANSI!

*  Thank you **Graham Barr** and **Paul Evans** for List::Util!

*  Thank you **Yuval Kogman** and **Jesse Luehrs** for Try::Tiny!

*  Thank you **Johan Vromans** for Getopt::Long!

*  Thank you **Marek Rouchal** and **Brad Appleton** for Pod::Usage!

### License and Copyright ###

Copyright (c) 2014, Breno G. de Oliveira. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See the "perlartistic" license.


