package Data::Record::Serialize::Types;

# ABSTRACT: Types for Data::Record::Serialize

use strict;
use warnings;

our $VERSION = '0.15';

use Type::Utils -all;
use Types::Standard -types;
use Type::Library -base,
  -declare => qw[ ArrayOfStr ];

use namespace::clean;

declare ArrayOfStr,
  as ArrayRef[ Str ];

coerce ArrayOfStr,
  from Str, q { [ $_ ] };


#
# This file is part of Data-Record-Serialize
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=head1 NAME

Data::Record::Serialize::Types - Types for Data::Record::Serialize

=head1 VERSION

version 0.15

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Data::Record::Serialize|Data::Record::Serialize>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
