#########################
## Copyright (C) 2002 Stathy G. Touloumis
## This is free software; you can redistribute it and/or modify it under
## the same terms as Perl itself.
##
package Class::Runtime;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile(

    NAME=>					__PACKAGE__,
	'PREREQ_PM'=>			{ 'File::Spec'=> 0.8, Symbol=> 1.02 },
    VERSION_FROM=>			'Runtime.pm',
	($] >= 5.005 ?
		(
			ABSTRACT_FROM =>		'Runtime.pm',
			AUTHOR=>				'Stathy G. Touloumis <stathy-classruntime@stathy.com>'
		) :
		()
	),
    dist=>					{
		COMPRESS=>			'gzip',
		SUFFIX=>			'gz',
    },

);

__END__

