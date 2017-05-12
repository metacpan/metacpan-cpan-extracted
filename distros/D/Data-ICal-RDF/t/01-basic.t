#!perl
# -*- perl -*-

use Test::More tests => 1;

use_ok 'Data::ICal::RDF';

# things we need to test:

# that it behaves properly when reading a bunk Data::ICal object

# that it behaves properly when reading bunk-yet-syntactically-valid
# data within the Data::ICal object

# that it behaves properly when executing resolve_uid

# that it behaves properly when executing resolve_binary

# that it properly inserts all the relevant content into the model

# LOL that's all gonna happen later folks
