# $Id: 00-load.t 2 2010-06-25 14:41:40Z twilde $


use Test::More tests => 2;
use strict;

BEGIN { 
    use_ok('Data::CGIForm'); 
    use_ok('t::FakeRequest');
}
