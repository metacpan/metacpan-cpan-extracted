package Data::Context::Loader;

# Created on: 2013-10-27 20:02:41
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use version;
use Carp;
use Scalar::Util;
use List::Util;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;


our $VERSION = version->new('0.3');

has raw => (
    is  => 'rw',
);

sub load {
    my ($self) = @_;

    return $self->raw;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Data::Context::Loader - Base class for Data::Context Loader modules

=head1 VERSION

This documentation refers to Data::Context::Loader version 0.3


=head1 SYNOPSIS

   use Data::Context::Loader;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Parent class for specific data loaders. See L<Data::Context::Loader::File> for
an example/default data loader.

=head1 SUBROUTINES/METHODS

=head2 C<changed ()>

Implemented by child classes, checks if the configuration has changed.

=head2 C<loader ($str)>

Implemented by child classes, does the actual loading of Data::Context
configurations.

=head2 C<load ()>

Default load just return the raw value from C<loader()>.

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
