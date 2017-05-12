# NAME

Acme::Github::Test - A test distribution for Github

# SYNOPSIS

    use 5.014;
    use Acme::Github::Test;

    my $acme = Acme::Github::Test->new( 23 => 'skidoo' );
    $acme->freep;
    $acme->frobulate('barbaz');

# ATTRIBUTES

The [Acme::Github::Test](http://search.cpan.org/perldoc?Acme::Github::Test) object will accept a list of initializers, but they don't do anything.

# METHODS

- new()

    This method initializes the object.  It can take a list of hash keys and values and store them. Returns
    the initialized [Acme::Github::Test](http://search.cpan.org/perldoc?Acme::Github::Test) object.

- freep()

    This method prints the string scalar "Freep!" on standard out.  It takes no input values. Returns a true
    value.

- frobulate()

    Takes an optional scalar value as input. The value '42' is the default value for this method. Returns the
    passed value or the default. (That means if you pass 0 or some other untrue scalar value, the return value 
    will be false.)

# AUTHOR

Mark Allen `<mallen@cpan.org>`

# SEE ALSO

- https://github.com/mrallen1/Acme-Github-Test
- https://speakerdeck.com/mrallen1/intro-to-git-for-the-perl-hacker

# LICENSE

Copyright (c) 2012 by Mark Allen

This library is free software; you can redistribute it and/or modify it
under the terms of the Perl Artistic License (version 1) or the GNU 
Public License (version 2)
