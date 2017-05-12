package CallBackery::GuiPlugin::AbstractHtml;
use Carp qw(carp croak);
use CallBackery::Translate qw(trm);
use CallBackery::Exception qw(mkerror);


=head1 NAME

CallBackery::GuiPlugin::AbstractHtml - render server generated HTML

=head1 SYNOPSIS

 use Mojo::Base 'CallBackery::GuiPlugin::AbstractHtml';

=head1 DESCRIPTION

The base class for html generator plugins.

=cut

use Mojo::Base 'CallBackery::GuiPlugin::Abstract';

=head1 ATTRIBUTES

The attributes of the L<CallBackery::GuiPlugin::Abstract> class plus:

=head2 screenCfg

Tells the frontend that we are going to render some HTML.

=cut

has screenCfg => sub {
    my $self = shift;
    return {
        type => 'html',
        options => {},
    }
};


=head1 METHODS

All the methods of L<CallBackery::GuiPlugin::Abstact> plus:

=cut


=head2 getData (parentFormData)

Return the data to be shown in the HTML field

=cut

sub getData {
    my $self = shift;
    my $parentFormData = shift;
    return '';
}


1;
__END__

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 COPYRIGHT

Copyright (c) 2013 by OETIKER+PARTNER AG. All rights reserved.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2015-04-29 to 1.0 first version

=cut

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4 et
