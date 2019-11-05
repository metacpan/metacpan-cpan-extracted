# Copyrights 2013-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Any-Daemon-HTTP. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Any::Daemon::HTTP::UserDirs;
use vars '$VERSION';
$VERSION = '0.29';

use parent 'Any::Daemon::HTTP::Directory';

use warnings;
use strict;

use Log::Report    'any-daemon-http';


sub init($)
{   my ($self, $args) = @_;

    my $subdirs = $args->{user_subdirs} || 'public_html';
    my %allow   = map +($_ => 1), @{$args->{allow_users} || []};
    my %deny    = map +($_ => 1), @{$args->{deny_users}  || []};
    $args->{location} ||= $self->userdirRewrite($subdirs, \%allow, \%deny);

    $self->SUPER::init($args);
    $self;
}

#-----------------

sub userdirRewrite($$$)
{   my ($self, $udsub, $allow, $deny) = @_;
    my %homes;  # cache
    sub { my $path = shift;
          my ($user, $pathinfo) = $path =~ m!^/\~([^/]*)(.*)!;
          return if keys %$allow && !$allow->{$user};
          return if keys %$deny  &&  $deny->{$user};
          return if exists $homes{$user} && !defined $homes{$user};
          my $d = $homes{$user} ||= (getpwnam $user)[7];
          $d ? "$d/$udsub$pathinfo" : undef;
        };
}

1;
