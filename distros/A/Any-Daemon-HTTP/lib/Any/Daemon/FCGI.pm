# Copyrights 2013-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Any-Daemon-HTTP. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Any::Daemon::FCGI;
use vars '$VERSION';
$VERSION = '0.29';

use parent 'IO::Socket::IP';

use warnings;
use strict;

use Log::Report      'any-daemon-http';

use Any::Daemon::FCGI::ClientConn ();


sub new(%)
{   my ($class, %args) = @_;
    $args{Listen} ||= 5;
    $args{Proto}  ||= 'tcp';
    $class->SUPER::new(%args);
}

#----------------

#----------------

sub accept(;$)
{   my $self = shift;
    my $pkg  = shift // 'Any::Daemon::FCGI::ClientConn';
    $self->SUPER::accept($pkg);
}

1;
