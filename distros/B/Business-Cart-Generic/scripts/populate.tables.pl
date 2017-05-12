#!/usr/bin/env perl

use strict;
use warnings;

use Business::Cart::Generic::Database::Import;

# ----------------------------

Business::Cart::Generic::Database::Import -> new -> populate_all_tables;
