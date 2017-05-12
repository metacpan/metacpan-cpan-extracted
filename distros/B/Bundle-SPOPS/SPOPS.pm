package Bundle::SPOPS;

# $Id: SPOPS.pm,v 1.11 2002/09/16 21:02:41 lachoy Exp $

use strict;

$Bundle::SPOPS::VERSION = '1.11';

1;

__END__

=head1 NAME

Bundle::SPOPS - Bundle to install all the pre-requisites for SPOPS

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::SPOPS'>

=head1 CONTENTS

Class::ISA

Test::More

Data::Dumper

Storable (1.00)

Class::Date (1.00)

Time::Piece (1.07)

Carp::Assert

Class::Fields

Class::Accessor

Devel::StackTrace

Class::Factory

SPOPS

=head1 DESCRIPTION

Install the few modules needed for SPOPS. Note that this is the bare
minimum -- to actually do something with the module you are probably
going to need at least L<DBI> plus one or more of the supported DBD
drivers (like L<DBD::mysql|DBD::mysql>, L<DBD::Sybase|DBD::Sybase>,
L<DBD::ASAny|DBD::ASAny>, L<DBD::Pg>, L<DBD::Oracle|DBD::Oracle>,
L<DBD::SQLite|DBD::SQLite>, or L<DBD::ODBC|DBD::ODBC>). You can also
currently use SPOPS with L<GDBM_File|GDBM_File>.

=head1 MORE INFORMATION

Information on the web about this module is found with OpenInteract, a
web-application server. Don't let that scare you: SPOPS is
self-contained and is very useful outside of OpenInteract.

Sourceforge Project Home:

 http://sourceforge.net/projects/openinteract/

News, package repository and more information:

 http://www.openinteract.org/

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

=cut
