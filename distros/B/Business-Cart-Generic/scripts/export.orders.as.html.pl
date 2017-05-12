#!/usr/bin/env perl

use strict;
use warnings;

use Business::Cart::Generic::Database::Export;

# -------------------------------

print Business::Cart::Generic::Database::Export -> new -> orders_as_html;
