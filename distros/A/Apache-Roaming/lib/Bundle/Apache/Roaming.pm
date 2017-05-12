# -*- perl -*-
#
#   $Id: Roaming.pm,v 1.1.1.1 1999/01/06 13:12:52 joe Exp $
#
#
#   Apache::Roaming - A mod_perl handler for Roaming Profiles
#
#
#   Based on mod_roaming by
#	Vincent Partington <vincentp@xs4all.nl>
#	See http://www.xs4all.nl/~vincentp/software/mod_roaming.html
#
#
#   Copyright (C) 1999    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#
############################################################################

package Bundle::Apache::Roaming;

$VERSION = '0.01';

1;

__END__

=head1 NAME

  Bundle::Apache::Roaming - A bundle to install Apache::Roaming and
      prerequisites


=head1 SYNOPSIS

 perl -MCPAN -e 'install Bundle::Apache::Roaming'


=head1 CONTENTS

File::Spec

Data::Dumper

Apache

Apache::Roaming


=head1 DESCRIPTION

This bundle defines all prerequisite modules for Apache::Roaming.


=head1 AUTHOR AND COPYRIGHT

This module is

    Copyright (C) 1998    Jochen Wiedmann
                          Am Eisteich 9
                          72555 Metzingen
                          Germany

                          Phone: +49 7123 14887
                          Email: joe@ispsoft.de

All rights reserved.

You may distribute this module under the terms of either
the GNU General Public License or the Artistic License, as
specified in the Perl README file.


=head1 SEE ALSO

L<CPAN(3)>, L<File::Spec(3)>, L<Data::Dumper(3)>, L<Apache(3)>,
L<Apache::Roaming(3)>

=cut
