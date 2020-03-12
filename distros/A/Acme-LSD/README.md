[![Build Status](https://travis-ci.org/thibaultduponchelle/Acme-LSD.svg?branch=master)](https://travis-ci.org/thibaultduponchelle/Acme-LSD) [![Kritika Status](https://kritika.io/users/thibaultduponchelle/repos/thibaultduponchelle+Acme-LSD/heads/master/status.svg)](https://kritika.io/users/thibaultduponchelle/repos/thibaultduponchelle+Acme-LSD)
# NAME

Acme::LSD - A dumb module that colorize your prints

# SYNOPSIS

    use Acme::LSD;

    # That's all ! 
    # (You will see the effect as soon as you print something...)
    # e.g. 
    print("Survive just one more day\n");

# DESCRIPTION

Acme::LSD is a module that overrides the **CORE::GLOBAL::print** function.

## EXAMPLE

For instance the code...

    #!/usr/bin/env perl 

    use Acme::LSD;
    print `man man`;

... will produce 

<div>
    <div style="display: flex">
    <div style="margin: 3px; flex: 1 1 50%">
    <img alt="Screenshot of Acme::LSD sample output" src="https://raw.githubusercontent.com/thibaultduponchelle/Acme-LSD/master/acmelsd.png" style="max-width: 100%" width="600">
    </div>
    </div>
</div>

# REFERENCES

- [How can I hook into Perl's print?](https://stackoverflow.com/questions/387702/how-can-i-hook-into-perls-print/388211#388211)
- My [C version](https://github.com/thibaultduponchelle/lsd)

# LICENSE

Copyright (C) Thibault DUPONCHELLE.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Thibault DUPONCHELLE <thibault.duponchelle@gmail.com>
