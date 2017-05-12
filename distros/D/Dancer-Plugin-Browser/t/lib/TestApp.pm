#
# This file is part of Dancer-Plugin-Browser
#
# This software is copyright (c) 2013 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::TestApp;

use Dancer;
use Dancer::Plugin::Browser::Detect;

get '/' => sub {
    return browser_detect();;
};

1;
