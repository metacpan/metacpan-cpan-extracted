# NAME

Acme::Addslashes - Perl twist on the most useful PHP function ever - addslashes

# SYNOPSIS

Do you have some text? Have you ever wanted to add some slashes to it? Well now you can!

PHP has a totally awesome `addslashes()` function - [http://php.net/addslashes](http://php.net/addslashes).

PERL has long been lacking such a function, and at long last here it is. Of
course the PERL version is better. Here is a run down of what's better in PERL:

- 1 PHP's addslashes can only adds slashes before characters.

Thanks to unicode, PERL's version doesn't have this limitation. We add slashes
_directly to the characters_. Isn't that cool?

- 2 PHP's addslashes only adds slashes to some characters

Why not add slashes to all characters? More slashes directly equals safer code.
That is scientific fact. There is no real evidence for it, but it is scientific fact.

__UPDATE__ Now with extra long slashes for even more protection! Thanks ~SKINGTON!

# USAGE

    use Acme::Addslashes qw(addslashes);

    my $unsafe_string = "Robert'); DROP TABLE Students;--";
    

    my $totally_safe_string = addslashes($unsafe_string);

    # $totally_safe_string now contains:
    # R̸o̸b̸e̸r̸t̸'̸)̸;̸ ̸D̸R̸O̸P̸ ̸T̸A̸B̸L̸E̸ ̸S̸t̸u̸d̸e̸n̸t̸s̸;̸-̸-̸

    # If that's not enough slashes to be safe, I don't know what is

# FUNCTIONS

## addslashes

    my $totally_safe_string = addslashes("Robert'); DROP TABLE Students;--");

The only function exported by this module. Will literally add slashes to anything.

Letters, numbers, punctuation, whitespace, unicode symbols.
You name it, this function can add a slash to it.

Will return you a `utf8` encoded string containing your original string, but with
enough slashes added to make Freddy Krueger jealous.

# AUTHOR

James Aitken <jaitken@cpan.org>



# COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by James Aitken.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
