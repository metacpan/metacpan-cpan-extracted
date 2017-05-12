package Bigtop::Backend::CGI;

use Bigtop::Keywords;

BEGIN {
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for( 'app', 'location' )
    );

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'controller',
            qw( location rel_location )
        )
    );

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for( 'app_literal', 'PerlTop' )
    );
}

1;

=head1 NAME

Bigtop::Backend::CGI - defines the legal keywords for cgi backends

=head1 SYNOPYSIS

If you are making a cgi generating backend:

    use Bigtop::Backend::CGI

This specifies the keywords for cgi generating backends.

If you need to add a keyword which is generally useful, add it here
(and send in a patch).  If you need a backend specific keyword, register
is within your backend module.

=head1 DESCRIPTION

If you are using a Bigtop backend in the CGI family, you should
read this document to find out what the valid keywords are and what
effect they have.

If you are writing a Bigtop::CGI:: module, you should use this
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

Inside the controller braces, you may include a location or
a rel_location keyword.  Use location if you want to specify an absolute
path and rel_location if you want to specify a path relative to the
app level location.

=head1 AUTHOR

Phil Crow <crow.phil@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
