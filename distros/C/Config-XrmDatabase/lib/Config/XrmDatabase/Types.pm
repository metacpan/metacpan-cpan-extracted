package Config::XrmDatabase::Types;

# ABSTRACT: Types for Config::XrmDatabase;

use strict;
use warnings;

our $VERSION = '0.04';

use Type::Utils -all;
use Types::Standard qw( Enum CodeRef );
use Type::Library -base,
  -declare => qw( QueryReturnValue OnQueryFailure );

use namespace::clean;

declare QueryReturnValue,
  as Enum[ \1, 'value', 'reference', 'all' ];

declare OnQueryFailure,
  as Enum( [ \1, 'undef', 'throw']) | CodeRef;

#
# This file is part of Config-XrmDatabase
#
# This software is Copyright (c) 2021 by Smithsonian Astrophysical Observatory.
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

Config::XrmDatabase::Types - Types for Config::XrmDatabase;

=head1 VERSION

version 0.04

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-config-xrmdatabase@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Config-XrmDatabase

=head2 Source

Source is available at

  https://gitlab.com/djerius/config-xrmdatabase

and may be cloned from

  https://gitlab.com/djerius/config-xrmdatabase.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Config::XrmDatabase|Config::XrmDatabase>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
