# Bio-FeatureIO 

Bio::FeatureIO is a BioPerl-based parser for feature data from common biological
sequence formats, such as GFF3, GTF, and BED. 

# Installation

To install this module type the following:

```
perl Build.PL
./Build
./Build test
./Build install
```

# Dependencies

Beyond the core BioPerl distribution, this module requires these other modules
and libraries:

* [URI::Escape](https://metacpan.org/pod/URI::Escape) - for Bio::FeatureIO::gff
* [XML::DOM::XPath](https://metacpan.org/pod/XML::DOM::XPath) - for Bio::FeatureIO::interpro

COPYRIGHT AND LICENCE

Copyright (C) 2010,2014 by Chris Fields and Allen Day

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.
