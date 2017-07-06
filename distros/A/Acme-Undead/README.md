# NAME

    Acme::Undead - The Undead is not die!

# SYNOPSIS

    use Acme::Undead;
    die('undead is not die');
    print 'Hell world';

    #Hell world

    no Acme::Undead;

    die() #died;

# DESCRIPTION

    Acme::Undead is export routines, die(), bless() and sleep().
    Use Acme::Undead when dont die at die(), die at bless() and not sleep at sleep().

# OVERRIDE METHODS

## die

    undead is not die!

## sleep

    undead is not sleeping

## bless

    the god bless clean undead auras.

# LICENSE

Copyright (C) likkradyus.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

    likkradyus E<lt>perl {at} li {dot} que {dot} jpE<gt>
