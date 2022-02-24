**Data-DPath-Flatten** is Copyright (C) 2022, Robert Wohlfarth

This module converts an arbitrary Perl data structure into a flat list of 
key/value pairs. The keys are `Data::DPath` path strings that reach the 
corresponding value.

I wanted to copy raw data files of varying structure into an SQL database. In
combination with other modules, I can read JSON, XML, Excel, or CSV data. Then
store them in the exact same SQL table.

# INSTALLATION

1. `perl Makefile.PL`
1. `make`
1. `make test`
1. `make install`

# LICENSE INFORMATION

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl 5.10.0. For details, see the full text of the license in the
file LICENSE.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied
