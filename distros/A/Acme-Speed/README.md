# NAME

Acme::Speed - About "SPEED" is Japanese female vocal/dance group

# SYNOPSIS

    use Acme::Speed;

    my $speed = Acme::Speed->new;

    my @members = $speed->members;

# DESCRIPTION

"SPEED" is a Japanese female vocal/dance group.

This module provides an method to check each member of SPEED.

# METHODS

## new

        my $speed = Acme::Speed->new;

    Creates and returns a new Acme::Speed object.

## members

        my @members = $speed->members;

    Returns the members as a list of the [Acme::Speed::Member::Base](http://search.cpan.org/perldoc?Acme::Speed::Member::Base) 
    based object represents each member. See also the documentation of 
    [Acme::Speed::Member::Base](http://search.cpan.org/perldoc?Acme::Speed::Member::Base) for more details.

# LICENSE

Copyright (C) Keisuke KITA.

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

# AUTHOR

Keisuke KITA <kei.kita2501@gmail.com>
