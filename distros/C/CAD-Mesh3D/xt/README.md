# Author Tests

## run

    prove -l xt

## run with test coverage

    perl Makefile.PL && gmake testcover TEST_FILES='xt/*.t'

## run with coverage on extra libraries

For example, if I want to cover CAD::Format::STL as well...
Right now, the way I know how to do it is to copy any extra
folders/modules into the lib hierarchy... Then the following
will include the STL library coverage as well...

    perl Makefile.PL && gmake testcover TEST_FILES='xt/*.t'

There might be another way of doing it... but for now,
that's acceptible.