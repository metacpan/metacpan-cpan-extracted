package Bigtop::Backend::Conf;

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
                'app_literal', 'Conf'
        )
    );
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
                'controller_literal', 'GantryLocation',
        )
    );
}

1;

=head1 NAME

Bigtop::Backend::Conf - defines the legal keywords for conf backends

=head1 SYNOPYSIS

If you are making an conf generating backend:

    use Bigtop::Backend::Conf

This specifies the keywords for conf generating backends.  Note
that you don't need inherit from this module, simply use it.

If you need to add a generally useful keyword, add it here
(and send in a patch).  If you need a backend specific keyword, register
it within your backend module.

=head1 DESCRIPTION

If you are using a Bigtop backend in the Conf family, you should
read this document to find out what the valid keywords are and what
effect they have.

If you are writing a Bigtop::Conf:: module, you should use this
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
be the base Apache Location for the application.  Location defaults to '/'.

Inside the controller braces, you may include a location or a
rel_location keyword.  Use location to specify the absolute Apache Location
or rel_location to specify the path relative to the app level location.

You can also add literal output in the generated conf file at either the
top level or at locations.  Use literal Conf at the app level and/or literal
GantryLocation at the controller level to generate it.

=head1 AUTHOR

Phil Crow <crow.phil@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
