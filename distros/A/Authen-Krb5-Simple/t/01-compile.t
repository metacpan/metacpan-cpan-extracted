###############################################################################
# Authen::Krb5::Simple Test Script
#
# File: 01-compile.t
#
# Purpose: Make sure the modules compiles and loads with no error
#
###############################################################################
#
use Test::More tests => 3;

# 1 - Use test.
#
BEGIN { use_ok('Authen::Krb5::Simple') }

# 2 - Require test.
#
require_ok( Authen::Krb5::Simple );

# 3 - Is what we is.
#
my $krb = Authen::Krb5::Simple->new();
isa_ok( $krb, 'Authen::Krb5::Simple');

###EOF###
