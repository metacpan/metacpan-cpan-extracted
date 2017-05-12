# Audio::LADSPA perl modules for interfacing with LADSPA plugins
# Copyright (C) 2003  Joost Diepenmaat.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# See the COPYING file for more information.

package Audio::LADSPA::Plugin::XS;
use strict;
use base qw(DynaLoader Audio::LADSPA::Plugin);
our $VERSION = "0.021";
use Carp;

__PACKAGE__->bootstrap($VERSION);

sub new {
    my ($class,$rate,$uid) = @_;
    $uid ||= $class->generate_uniqid;
    $class->new_with_uid($rate,$uid);
}


1;


__END__

=pod

=head1 NAME

Audio::LADSPA::Plugin::XS - XS representation of ladspa plugins

=head1 DESCRIPTION

This is the base class for 'real' ladspa plugins. It inherits from
Audio::LADSPA::Plugin. See L<Audio::LADSPA::Plugin> for the public
API.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 Joost Diepenmaat <jdiepen@cpan.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

