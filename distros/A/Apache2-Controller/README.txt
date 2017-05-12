Apache2-Controller

fast MVC-style Apache2 mod_perl2 handler app framework

Apache2::Controller organizes subclassed Apache2::Request handler objects in
an MVC module structure. A YAML file maps url paths to modules. $self is $r,
the subclassed XS APR bindings with libapreq methods to load query string,
etc. Stream with $r->print or use a parallel web tree of Template::Toolkit
files. Hook in any model class like DBIx::Class or direct SQL or sockets,
connections cached across requests. Session cookie plugin. Other great stuff.


INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Apache2::Controller

You can also look for information at:

    GitHub
        https://github.com/a2c-perl/libapache2-controller-perl

    RT, CPAN's request tracker
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-Controller

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Apache2-Controller

    CPAN Ratings
        http://cpanratings.perl.org/d/Apache2-Controller

    Search CPAN
        http://search.cpan.org/dist/Apache2-Controller


COPYRIGHT AND LICENCE

Copyright (C) 2014 Mark Hedges http://www.linkedin.com/in/hedges333

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

