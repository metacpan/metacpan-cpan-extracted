##
## Copyright (c) 1998-2025, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

our $VERSION = '1.57';

use strict;
use warnings;
package Crypt::Random::Provider::devurandom; 
use Crypt::Random::Provider::File;
use vars qw(@ISA);
@ISA = qw(Crypt::Random::Provider::File);

sub _defaultsource { return "/dev/urandom" } 

1;

