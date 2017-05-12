package Data::Context::BEM::Instance;

# Created on: 2013-11-06 17:57:39
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use namespace::autoclean;
use version;
use Carp;
use Scalar::Util;
use List::Util;
#use List::MoreUtils;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Data::Context::BEM::Merge;

extends 'Data::Context::Instance';

our $VERSION = version->new('0.1');

has blocks => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {{}},
);

around process_data => sub {
    my ( $orig, $self, $count, $data, $path ) = @_;

    if ( ref $data eq 'HASH' && $data->{block} ) {
        my $module = $self->dc->block_module($data->{block});
        $self->blocks->{$data->{block}} = $module;
        if ( $module ) {
            $data->{MODULE} = $module;
        }
        $data->{processed} = 1;
    }

    return $self->$orig($count, $data, $path);
};

sub _merger {
    my ($self) = @_;

    return Data::Context::BEM::Merge->new();
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Data::Context::BEM::Instance - An instance of a BEM script

=head1 VERSION

This documentation refers to Data::Context::BEM::Instance version 0.1

=head1 SYNOPSIS

   use Data::Context::BEM::Instance;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

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
