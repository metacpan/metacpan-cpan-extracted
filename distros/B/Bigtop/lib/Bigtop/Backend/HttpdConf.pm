package Bigtop::Backend::HttpdConf;

use Bigtop::Keywords;

BEGIN {
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for( 'app', 'location' )
    );

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'controller', 'location', 'rel_location'
        )
    );

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'app_literal', 'HttpdConf', 'Location', 'PerlTop', 'PerlBlock',
        )
    );
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'controller_literal', 'Location'
        )
    );
}

1;

=head1 NAME

Bigtop::Backend::HttpdConf - defines the legal keywords for httpd conf backends

=head1 SYNOPYSIS

If you are making an httpd conf generating backend:

    use Bigtop::Backend::HttpdConf

This specifies the keywords for conf generating backends.

If you need to add a generally useful keyword, add it here
(and send in a patch).  If you need a backend specific keyword, register
it within your backend module.

=head1 DESCRIPTION

If you are using a Bigtop backend in the HttpdConf family, you should
read this document to find out what the valid keywords are and what
effect they have.

If you are writing a Bigtop::HttpdConf:: module, you should use this
module.  That will register the keywords your module will need.

=head1 BASIC STRUCTURE

A bigtop file looks like this:

    config {
    }
    app name {
        controller name {
        }
    }

=head1 KEYWORDS

Inside the app braces, you can include the location keyword.  Its value will
be the base Apache Location for the application.  The default is '/'.

Inside the controller braces, you may include a location or a
rel_location keyword.  Use location to specify the absolute Apache Location
or rel_location to specify the path relative to the app level location.

=head1 AUTHOR

Phil Crow <crow.phil@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
