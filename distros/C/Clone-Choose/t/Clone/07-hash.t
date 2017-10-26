#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} = "Clone"; }
END { delete $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} } # for VMS

require 't/07-hash.t';

