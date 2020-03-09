# NAME

Block::NJH - Prevent your tests from running on NJH's broken smokers.

# DESCRIPTION

Nigel Horne is trying to do a good thing by providing a lot of smokers to test
perl modules. I thank him for this effort. However his smokers have long been
broken providing bad results. Many distributions are flooded with invalid
failure results. Attempts have been made to get this fixed, but so far they are
still broken.

This module has code that makes it refuse to install on NJH's machines. As a
result you simply need to list this module in your prereq's to block him from
sending bad test reports for your modules.

# SOURCE

The source code repository for Block-NJH can be found at
`http://github.com/exodist/Block-NJH/`.

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright 2020 Chad Granum <exodist7@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `http://dev.perl.org/licenses/`
