#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Role::Constants 2.145;

# ABSTRACT: Provide some constant data.

use Mouse::Role;
use strict;
use warnings;
use 5.020;

use feature qw/signatures postderef/;
no warnings qw/experimental::signatures experimental::postderef/;

my %all_props = (
    status      => 'standard',
    level       => 'normal',
    summary     => '',
    description => '',
);

sub get_default_property ($prop) {
    return $all_props{$prop};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Role::Constants - Provide some constant data.

=head1 VERSION

version 2.145

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005-2021 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
