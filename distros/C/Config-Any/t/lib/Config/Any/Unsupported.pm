package Config::Any::Unsupported;

use strict;
use warnings;

use base 'Config::Any::Base';

sub extensions {
    return qw( unsupported );
}

sub load {
}

sub requires_all_of { 'My::Module::DoesNotExist' }

1;
