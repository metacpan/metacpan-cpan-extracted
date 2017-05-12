package CatalystX::CRUD::YUI::TT;

use warnings;
use strict;
use Template::Plugin::Handy 'install';

our $VERSION = '0.031';

=head1 NAME

CatalystX::CRUD::YUI::TT - templates for your CatalystX::CRUD view

=head1 SYNOPSIS

 use CatalystX::CRUD::YUI::TT;
 
 # in a template
 [% foo.as_json %]
 [% foo.dump_data %]
 [% foo.dump_stderr %]
 [% SET foo = 1;
    foo.increment;   # foo == 2
    foo.decrement;   # foo == 1
 %]

=head1 DESCRIPTION

CatalystX::CRUD::YUI::TT adds some convenience virtual methods
to the Template::Stash namespace.

As of version 0.007 this is just a wrapper around Template::Plugin::Handy.

=cut

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud-yui@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

