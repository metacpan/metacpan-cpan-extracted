#!/usr/bin/env perl

use strict;
use warnings;

use Business::Cart::Generic::Database::Create;

# ----------------------------

Business::Cart::Generic::Database::Create -> new -> drop_all_tables;
