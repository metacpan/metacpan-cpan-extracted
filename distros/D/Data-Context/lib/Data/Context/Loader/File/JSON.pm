package Data::Context::Loader::File::JSON;

# Created on: 2013-10-29 17:34:35
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use version;
use Carp;
use English qw/ -no_match_vars /;
use JSON::XS;

our $VERSION     = version->new('0.3');

extends 'Data::Context::Loader::File';

has '+module' => (
    default => 'JSON::XS',
);

sub loader {
    my ($self, $file) = @_;
    return JSON::XS->new->utf8->shrink->decode($file);
}

1;

__END__

=head1 NAME

Data::Context::Loader::File::JSON - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to Data::Context::Loader::File::JSON version 0.3

=head1 SYNOPSIS

   use Data::Context::Loader::File::JSON;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<loader ($file)>

Loads the file as plain JSON

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

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
