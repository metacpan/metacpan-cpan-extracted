#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::TypeConstraints 2.134;

use Mouse;
use Mouse::Util::TypeConstraints;

subtype 'Config::Model::TypeContraints::Path' => as 'Maybe[Path::Tiny]' ;
coerce 'Config::Model::TypeContraints::Path' => from 'Str' => via sub { defined $_ ?  Path::Tiny::path($_) : undef ; } ;

1;

# ABSTRACT: Mouse type constraints for Config::Model

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::TypeConstraints - Mouse type constraints for Config::Model

=head1 VERSION

version 2.134

=head1 SYNOPSIS

 use Config::Model::TypeConstraints ;

 has 'some_dir' => (
    is => 'ro',
    isa => 'Config::Model::TypeContraints::Path',
    coerce => 1
 );

=head1 DESCRIPTION

This module provides type constraints used by Config::Model:

=over

=item *

C<Config::Model::TypeContraints::Path>. A C<Maybe[Path::Tiny]>
type. This type can be coerced from C<Str> type if C<< coerce => 1 >>
is used to construct the attribute.

=back

=head1 SEE ALSO

L<Config::Model>,
L<Mouse::Util::TypeConstraints>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005-2019 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
