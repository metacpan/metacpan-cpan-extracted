# $Id: Preload.pm 4 2007-09-13 10:16:35Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot-model.googlecode.com/svn/trunk/lib/Class/Dot/Model/Preload.pm $
# $Revision: 4 $
# $Date: 2007-09-13 12:16:35 +0200 (Thu, 13 Sep 2007) $
package Class::Dot::Model::Preload;

use strict;
use warnings;
use version; our $VERSION = qv('0.1.3');
use 5.006_001;

use Class::Dot;
use Params::Util;
use Class::Plugin::Util qw(require_class);

my @PRELOAD_CLASSES = qw(
   Class::Dot::Model 
   Class::Dot::Model::Table 
   Class::Dot::Model::Util
);

sub import {

    for my $class (@PRELOAD_CLASSES) {
        require_class($class);
        if ($class->can('requires')) {
            for my $require_class ($class->requires) {
                require_class($require_class);
            }
        }
    }

    return;
}

1;

__END__

=begin wikidoc

= NAME

Class::Dot::Model::Preload - Preload Class::Dot::Model related modules.

= VERSION

This document describes Class::Dot::Model version v%%VERSION%%

= SYNOPSIS

   # in i.e your startup.pl file:
   #
   use Class::Dot::Model::Preload;

    

= DESCRIPTION

Preload Class::Dot::Model related modules in i.e a mod_perl environment.

= SUBROUTINES/METHODS

This module has no subroutines/methods.


= DIAGNOSTICS

None.

= CONFIGURATION AND ENVIRONMENT

None.

= DEPENDENCIES

* [DBIx::Class]

* [Class::Dot]

* [Class::Plugin::Util]

* [Params::Util]

* [Config::PlConfig]

* [version]

= INCOMPATIBILITIES

None known.

= BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
[bug-class-dot-model@rt.cpan.org|mailto:class-dot-model@rt.cpan.org], or through the web interface at
[CPAN Bug tracker|http://rt.cpan.org].

= SEE ALSO

== [Class::Dot::Model]

= AUTHOR

Ask Solem, [ask@0x61736b.net].

= LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem [ask@0x61736b.net|mailto:ask@0x61736b.net].

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

= DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=end wikidoc


=for stopwords expandtab shiftround
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
