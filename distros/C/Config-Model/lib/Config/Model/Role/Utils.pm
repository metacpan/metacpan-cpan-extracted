#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Role::Utils 2.152;

# ABSTRACT: Provide some utilities

use Mouse::Role;
use strict;
use warnings;
use 5.020;

use feature qw/signatures postderef/;
no warnings qw/experimental::signatures experimental::postderef/;

sub _resolve_arg_shortcut ($args, @param_list) {
    return $args->@* > @param_list ? $args->@*
         :                           map { $_ => shift @$args; } @param_list;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Role::Utils - Provide some utilities

=head1 VERSION

version 2.152

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005-2022 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
