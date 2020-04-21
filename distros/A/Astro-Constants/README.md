# Astro-Constants
This Perl module provides physical constants useful for astronomy and physics
in the MKS and CGS systems.

Tired of your programs producing garbage because you mis-typed the gravitational constant
or assigned a value instead of checking equality?  Why not rely on a module that does
all that work for you and gives you all the constants ready to use with a simple
```
use Astro::Constants qw/:cosmology/;
```
instead of relying on 
[Magic Numbers](https://en.wikipedia.org/wiki/Magic_number_%28programming%29#Unnamed_numerical_constants)
which only serve to obscure your intent from everyone, including yourself
six months from now.  C'mon now, **make your programs _readable_**!

**Make your programs _faster!!!_**

The benchmarks show that all of the long name constants are at least **3 times faster**
in calculations than using variables, short names or other constant modules to hold the values.

While no-one can give bomb-proof guarantees that these values are correct (indeed, 
some of them are liable to change in time), rest assured that these values
will be checked against standards bodies and the relevant references and urls
provided for you to decide how much you want to trust the values in this module.

Check the ChangeLog for changes in any variables.

## Astroconst
This module started out as a Perl port of Jeremy Bailin's Astroconst package.
The url http://astroconst.org used to house this project.  It's now been abandoned.

## Racing Stripes
Looking for speed in your script?  Consider upgrading your perl to v5.23.4
which has a 40% improvement over v5.20.3
