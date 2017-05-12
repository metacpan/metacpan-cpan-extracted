#!/usr/bin/env perl
use strict;
use warnings;
use CatalystX::Crudite::Script::Create;
CatalystX::Crudite::Script::Create::run('<% dist_module %>');

=head1 NAME

<% dist_file %>_crudite_create - create a Crudite component

=head1 USAGE

   $ <% dist_file %>_crudite_create resource Article

=head1 SEE ALSO

Read L<CatalystX::Crudite::Script::Create> for all the details.

=head1 AUTHOR

Marcel Gruenauer C<< <marcel@cpan.org> >>

=cut
