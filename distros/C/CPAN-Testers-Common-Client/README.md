### CPAN-Testers-Common-Client ###

Common code for CPAN Testers' clients

[![Build Status](https://travis-ci.org/garu/CPAN-Testers-Common-Client.svg?branch=master)](https://travis-ci.org/garu/CPAN-Testers-Common-Client)
[![Coverage Status](https://coveralls.io/repos/garu/CPAN-Testers-Common-Client/badge.svg?branch=master)](https://coveralls.io/r/garu/CPAN-Testers-Common-Client?branch=master)

This module provides a common client for constructing metabase facts and
the legacy email message sent to CPAN Testers in a way that is properly
parsed by the extraction and report tools. It is meant to be used by all
the CPAN clients (and standalone tools) that want/need to support the
CPAN Testers infrastructure.

For the complete documentation, please refer to:

http://metacpan.org/module/CPAN::Testers::Common::Client

That same documentation will also be available to you after installation
at the command line. Just type:

    perldoc CPAN::Testers::Common::Client

after the the module is installed.


#### Installation ####

    cpanm CPAN::Testers::Common::Client

Or manually, by running the following commands:

	perl Makefile.PL
	make
	make test
	make install


#### COPYRIGHT AND LICENCE ####

Copyright (C) 2012-2015, Breno G. de Oliveira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
