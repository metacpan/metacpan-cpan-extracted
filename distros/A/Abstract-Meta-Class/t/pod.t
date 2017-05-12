use warnings;
use strict;

use Test::Pod tests => 3;           
 
pod_file_ok( 'lib/Abstract/Meta/Class.pm', "should have value lib/Abstract/Meta/Class.pm POD file" );
pod_file_ok( 'lib/Abstract/Meta/Attribute.pm', "should have value lib/Abstract/Meta/Attribute.pm POD file" );
pod_file_ok( 'lib/Abstract/Meta/Attribute/Method.pm', "should have value lib/Abstract/Meta/Attribute/Method.pm POD file" );