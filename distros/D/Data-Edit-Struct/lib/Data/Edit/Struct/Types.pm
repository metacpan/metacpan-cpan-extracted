package  Data::Edit::Struct::Types;

# ABSTRACT: Types for Data::Edit::Struct;

use strict;
use warnings;

our $VERSION = '0.06';

use Data::DPath qw[ dpath dpathi ];
use Type::Library
  -base,
  -declare => qw( Context UseDataAs IntArray DataPath );
use Type::Utils -all;
use Types::Standard -types;



declare Context,
  as InstanceOf ['Data::DPath::Context'],;

coerce Context,
  from HashRef | ArrayRef | ScalarRef, via sub { dpathi( $_ ) };

declare UseDataAs,
  as Enum [ 'element', 'container', 'auto' ];

declare IntArray,
  as ArrayRef[Int];

coerce IntArray,
  from Int, via sub { [ $_ ] };


1;


1;

#
# This file is part of Data-Edit-Struct
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

=pod

=head1 NAME

Data::Edit::Struct::Types - Types for Data::Edit::Struct;

=head1 VERSION

version 0.06

=head1 SYNOPSIS

=head1 SEE ALSO

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__


#pod =head1 SYNOPSIS
#pod
#pod
#pod =head1 SEE ALSO
