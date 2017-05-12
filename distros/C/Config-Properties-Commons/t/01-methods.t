#!perl

####################
# LOAD CORE MODULES
####################
use strict;
use warnings FATAL => 'all';
use Test::More;

# Autoflush ON
local $| = 1;

####################
# LOAD DIST MODULES
####################
use Config::Properties::Commons;

####################
# RUN TESTS
####################

# Init object
my $cpc = Config::Properties::Commons->new();

# Public
my @method_list = qw(
  new
  load
  get_property
  require_property
  add_property
  properties
  property_names
  is_empty
  has_property
  delete_property
  clear_properties
  reset_property
  save_to_string
  save
  get_files_loaded
);

# Aliases
push @method_list, qw(
  load_fh
  load_file
  store
  save_as_string
  saveToString
  getProperty
  addProperty
  requireProperty
  set_property
  setProperty
  changeProperty
  clear
  clearProperty
  deleteProperty
  containsKey
  getProperties
  subset
  getKeys
  propertyNames
  getFileNames
  isEmpty
);

# Internal
push @method_list, qw(
  _set_options
  _load
  _interpolate
  _save
);

# Utils
push my @utils_list, qw(
  _sep_regex
  _esc_key
  _esc_val
  _esc_delim
  _unesc_key
  _unesc_val
  _unesc_delim
  _wrap
);

# Test methods
can_ok( $cpc, @method_list );

# Test Utils
can_ok( 'Config::Properties::Commons', @utils_list );

####################
# DONE
####################
done_testing();
exit 0;
