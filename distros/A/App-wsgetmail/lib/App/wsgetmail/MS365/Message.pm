# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 2020-2022 Best Practical Solutions, LLC
#                                          <sales@bestpractical.com>
#
# (Except where explicitly superseded by other copyright notices)
#
#
# LICENSE:
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
#
#
# CONTRIBUTION SUBMISSION POLICY:
#
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
#
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
#
# END BPS TAGGED BLOCK }}}

package App::wsgetmail::MS365::Message;
use Moo;

=head1 NAME

App::wsgetmail::MS365::Message

=head2 DESCRIPTION

Simple Moo class representing an Microsoft/Outlook 365 message.

=head2 ATTRIBUTES

All attributes are read-only.

=over 4

=item * id

=item * status

=item * recipients

=back

=cut

has id => (
    is => 'ro',
    required => 1
);

has status => (
    is => 'ro',
    required => 1
);

has recipients => (
    is => 'ro',
    required => 1
);

has _details => (
    is => 'ro',
    required => 1
);

# have client
around BUILDARGS => sub {
  my ( $orig, $class, $details ) = @_;

  my $args = {
      id => $details->{id},
      status => $details->{status},
      recipients => $details->{toRecipients},
      _details => $details
  };

  return $class->$orig($args);
};

=head1 SEE ALSO

=over 4

=item * L<App::wsgetmail::MS365>

=back

=head1 AUTHOR

Best Practical Solutions, LLC <modules@bestpractical.com>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
