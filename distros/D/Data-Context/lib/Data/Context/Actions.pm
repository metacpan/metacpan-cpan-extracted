package Data::Context::Actions;

# Created on: 2012-04-13 09:54:58
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use Scalar::Util;
use List::Util;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Data::Context::Util qw/lol_path lol_iterate/;

our $VERSION = version->new('0.3');

sub expand_vars {
    my ( $self, $value, $vars, $path, $dci ) = @_;

    if ( ref $value eq 'HASH' ) {
        if ( !exists $value->{value} ) {
            $dci->dc->log->warn( "expand_vars called as a hash but without a value in ".$dci->path." at $path" ) if $dci;
            return;
        }
        $value = $value->{value} ;
    }

    # remove #'s
    $value =~ s/^[#] | [#]$//gxms;

    return Data::Context::Util::lol_path( $vars, $value );
}

1;

__END__

=head1 NAME

Data::Context::Actions - Contains all the default actions available to a config

=head1 VERSION

This documentation refers to Data::Context::Actions version 0.3.
=head1 SYNOPSIS

   use Data::Context::Actions;

   # expand variables
   my $expanded = Data::Context::Actions->expand_var( '#path.to.item#', undef, 'path.in.config', {...} );

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<expand_vars ( $value, $dc, $path, $vars )>

Expands C<$value> in C<$vars>

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

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
