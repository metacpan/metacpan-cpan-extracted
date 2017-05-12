#
# This file is part of Dancer2-Plugin-BrowserDetect
#
# This software is copyright (c) 2016 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package TestApp;

use Dancer2;
use Dancer2::Plugin::BrowserDetect;

use Data::Dumper;

get '/' => sub {
    return Dumper(browser_detect());
};

1;
