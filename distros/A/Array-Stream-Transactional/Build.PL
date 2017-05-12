# $Id: Build.PL,v 1.2 2004/03/29 20:26:52 claes Exp $

use Module::Build;
Module::Build->new( module_name => 'Array::Stream::Transactional',
		    license     => 'perl',
		    requires    => { Test => 0 },
		    create_makefile_pl => 'traditional',
		  )->create_build_script;
