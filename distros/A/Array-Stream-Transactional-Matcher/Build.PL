# $Id: Build.PL,v 1.1 2004/05/04 18:57:52 claes Exp $

use Module::Build;
Module::Build->new( module_name => 'Array::Stream::Transactional::Matcher',
		    license     => 'perl',
		    requires    => { Test::More => 0,
				     Array::Stream::Transactional => 1.02 },
		    create_makefile_pl => 'traditional',
		    )->create_build_script;
