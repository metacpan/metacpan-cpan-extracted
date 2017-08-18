#Algorithm::Evolutionary::Simple version 0.2

A simple and straightforward implementation of an evolutionary algorithm. Thought for demos and also for speed.

[![Build Status](https://travis-ci.org/JJ/algorithm-evolutionary-simple.svg?branch=master)](https://travis-ci.org/JJ/algorithm-evolutionary-simple)

##INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install
	
But you will probably use

	cpanm Algorithm::Evolutionary::Simple

or

	sudo cpan Algorithm::Evolutionary::Simple

This module is apparently also available at the OpenSUSE repos. To install it, I guess, you should use:

	zypper install perl-Algorithm-Evolutionary-Simple

or via YaST

##DEPENDENCIES

As shown in the Makefile.PL file; mainly Sort::Key::Top.

##SYNOPSIS

Very simple evolutionary algorithm in Perl, mainly with pedagogical
purposes. Once installed, use the provided functions or run
simple-EA.pl

##References

You are very welcome to use this module for research. I would be grateful, however, if you referenced one of our papers such as

```
@inproceedings{merelo2012pool,
  title={Pool vs. island based evolutionary algorithms: an initial exploration},
  author={Merelo, Juan Julian and Mora, Antonio Miguel and Fernandes, Carlos M and Esparcia-Alcazar, Anna I and Laredo, Juan LJ},
  booktitle={P2P, Parallel, Grid, Cloud and Internet Computing (3PGCIC), 2012 Seventh International Conference on},
  pages={19--24},
  year={2012},
  organization={IEEE}
}
```



##COPYRIGHT AND LICENCE

Copyright (C) 2011, JJ Merelo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
