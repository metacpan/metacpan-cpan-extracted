package Test::Catalyst::Log;

use strict;
use warnings;

sub new {
    bless {}, __PACKAGE__;
}

sub is_debug { 0 }
sub debug { }
sub is_info { 0 }
sub info { }
sub is_warn { 0 }
sub warn : method { }
sub is_error { 0 }
sub error { }
sub is_fatal { 0 }
sub fatal { }

1;
