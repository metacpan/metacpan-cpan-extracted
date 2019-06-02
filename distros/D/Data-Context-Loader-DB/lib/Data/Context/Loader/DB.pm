package Data::Context::Loader::DB;

# Created on: 2016-01-18 13:31:41
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use namespace::autoclean;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Data::Context::Util qw/do_require/;
use JSON::XS;

our $VERSION = version->new('0.0.1');

extends 'Data::Context::Loader';

sub changed {
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Data::Context::Loader::DB - Loads a config from a table in a database

=head1 VERSION

This documentation refers to Data::Context::Loader::DB version 0.0.1


=head1 SYNOPSIS

   use Data::Context::Loader::DB;

   # Load data from table
   my $file = Data::Context::Loader::DB->new(
       table => '',
   );

=head1 DESCRIPTION

Loads configs found by L<Data::Context::Finder::DB> and performs checks to
see if the configs have changed.

=head1 SUBROUTINES/METHODS

=head2 C<changed ()>

Name the section accordingly.

=head2 C<loader ($str)>


=head2 C<load ()>


=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
