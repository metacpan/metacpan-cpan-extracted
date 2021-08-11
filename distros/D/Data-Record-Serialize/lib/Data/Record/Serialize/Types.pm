package Data::Record::Serialize::Types;

# ABSTRACT: Types for Data::Record::Serialize

use strict;
use warnings;

our $VERSION = '0.28';

use Type::Utils -all;
use Types::Standard qw( ArrayRef Str Enum );
use Type::Library -base,
  -declare => qw[ ArrayOfStr SerializeType ];

use namespace::clean;

declare ArrayOfStr,
  as ArrayRef[ Str ];

coerce ArrayOfStr,
  from Str, q { [ $_ ] };

declare SerializeType,
  as Enum[ qw( N I S B) ];

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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Data::Record::Serialize::Types - Types for Data::Record::Serialize

=head1 VERSION

version 0.28

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize

=head2 Source

Source is available at

  https://gitlab.com/djerius/data-record-serialize

and may be cloned from

  https://gitlab.com/djerius/data-record-serialize.git

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
