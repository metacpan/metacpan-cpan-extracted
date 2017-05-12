# @(#) $Id: Build.PL,v 1.2 2003/04/24 13:26:20 dom Exp $

use strict;
use Module::Build;

Module::Build->new(
    module_name => 'Class::DBI::ToSax',
    license     => 'perl',
    requires    => {
        # Bug in 5.6.0 isa()...
        'perl'       => '5.6.1',
        'Test::More' => 0,
        # Both of these are required by Class::DBI, so shouldn't be too
        # onerous...
        'Class::Accessor'          => 0,
        'Class::Data::Inheritable' => 0,
        # DCONWAY rocks.
        'NEXT' => 0,
        # Most people will want this and it's good for testing.
        'XML::SAX::Writer' => 0,
    },
)->create_build_script;
