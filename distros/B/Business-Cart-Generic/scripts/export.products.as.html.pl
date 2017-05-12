#!/usr/bin/env perl

use strict;
use warnings;

use Business::Cart::Generic::Database::Export;

# -------------------------------

print Business::Cart::Generic::Database::Export -> new -> products_as_html;
