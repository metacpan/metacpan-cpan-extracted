package CXC::DB::DDL::Failure;

# ABSTRACT: Failure classes for App::Deosc

use v5.26;
use strict;
use warnings;

our $VERSION = '0.14';

use custom::failures qw(
  parameter_constraint
  duplicate
  create
  ddl
);

1;

#
# This file is part of CXC-DB-DDL
#
# This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::DB::DDL::Failure - Failure classes for App::Deosc

=head1 VERSION

version 0.14

=head1 DESCRIPTION

This module creates custom failure classes

=over

=item CXC::DB::DDL::Failure::parameter_constraint

=item CXC::DB::DDL::Failure::duplicate

=item CXC::DB::DDL::Failure::create

=item CXC::DB::DDL::Failure::ddl

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-db-ddl@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-DB-DDL>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-db-ddl

and may be cloned from

  https://gitlab.com/djerius/cxc-db-ddl.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::DB::DDL|CXC::DB::DDL>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
