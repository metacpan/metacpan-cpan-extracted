# NAME

Data::JPack - Offline/Online Web application and data system

# SYNOPISIS

```perl
use Data::JPack;

my $packer=Data::JPack->new();
$packer->encode ($data);
```

# DESCRIPTION

Provides a mechanism to store any data type (text, binary etc) so a web browser
can load the data without the requirement of a server (ie local files) or
samesite/ origin security issues.  Data is normally compressed before encoded

It also implements a worker pool system to allow backgroun processing of data
and user exentable functions

It provides the bootstrapping to load application code, and arbitary data, by
making a file system database loadable from a webpage.

# HOW IT WORKS

The basics is data is encoded into base64 text, which is then the return value
from function. This function is the wrapper which is stored in the loadable
datafile.  This function is passed to the JPack decodeer, which calls the
function when the file is ready.
