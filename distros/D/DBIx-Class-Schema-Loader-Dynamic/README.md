
[![Build Status](https://travis-ci.org/frank-carnovale/DBIx-Class-Schema-Loader-Dynamic.svg?branch=master)](https://travis-ci.org/frank-carnovale/DBIx-Class-Schema-Loader-Dynamic)

DBIx::Class::Schema::Loader::Dynamic
------------------------------------

Really dynamic schema discovery and load for DBIx::Class

Guide
-----
Guide information is embedded in the main POD text.

Running the Test application
----------------------------

```
prove -lv
```


Installing
----------
```
perl Makefile.PL
make test
make install
```

Building a distribution
-----------------------
```
make clean && rm *.tar.gz
perl Makefile.PL
make test
make manifest
make dist
cpan-upload -u USER *tar.gz
```

