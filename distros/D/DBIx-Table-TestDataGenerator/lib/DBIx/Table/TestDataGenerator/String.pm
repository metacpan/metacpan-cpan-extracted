package DBIx::Table::TestDataGenerator::String;
use Moo;

use strict;
use warnings;

our $VERSION = "0.005";
$VERSION = eval $VERSION;

use Carp;

sub remove_package_prefix {
    my ( $self, $pck_name ) = @_;
    $pck_name =~ s/(?:.*::)?([^:]+)/$1/;
    return $pck_name;
}

1;    # End of DBIx::Table::TestDataGenerator::String

__END__

=pod

=head1 NAME

DBIx::Table::TestDataGenerator::String - string manipulation

=head1 DESCRIPTION

This measly utility class collects methods operating purely on strings. I could not find a better place to stuck the sole method in, so here it is.

=head1 SUBROUTINES/METHODS

=head2 remove_package_prefix

Argument: package name.

Returns the last part of the package name.

=head1 AUTHOR

Jose Diaz Seng, C<< <josediazseng at gmx.de> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Jose Diaz Seng.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For more details, see the full text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose. 
