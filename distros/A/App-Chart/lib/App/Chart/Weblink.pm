# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Weblink;
use 5.006;
use strict;
use warnings;
use Carp;
# use Locale::TextDomain ('App-Chart');

use App::Chart;

# uncomment this to run the ### lines
#use Smart::Comments;

our @weblinks_list = ();

sub new {
  my ($class, %self) = @_;
  my $self = bless \%self, $class;
  require App::Chart::Sympred;
  App::Chart::Sympred::validate ($self->{'pred'});
  if (! ($self->{'url'} || $self->{'proc'})) {
    croak "Missing weblink url or proc\n";
  }
  if (! $self->{'name'}) {
    croak "Missing weblink name";
  }

  push @weblinks_list, $self;
  @weblinks_list = sort { $a->{'name'} cmp $b->{'name'} } @weblinks_list;
  return $self;
}

sub links_for_symbol {
  my ($class, $symbol) = @_;
  App::Chart::symbol_setups ($symbol);
  return grep { $_->{'pred'}->match($symbol) } @weblinks_list;
}

sub url {
  my ($self, $symbol) = @_;
  return $self->{'url'}
    || $self->{'proc'}->($symbol);
}

sub name {
  my ($self) = @_;
  return $self->{'name'};
}

sub sensitive {
  my ($self, $symbol) = @_;
  # But should check without any downloading ...
  return scalar ($self->url ($symbol));
}

sub open {
  my ($self, $symbol, $parent) = @_;
  my $url = $self->url($symbol);
  require App::Chart::Gtk2::GUI;
  App::Chart::Gtk2::GUI::browser_open ($url, $parent);
}

1;
__END__

=for stopwords weblink weblinks Eg url ie

=head1 NAME

App::Chart::Weblink -- web page links for symbols

=head1 SYNOPSIS

 use App::Chart::Weblink;

=head1 DESCRIPTION

A weblink is a URL to some web site page related to a symbol, such as a
company information page or commodity contract specifications.  The weblinks
for a given symbol are presented under the "View/Web" menu in the main Chart
GUI.

=head1 FUNCTIONS

=over 4

=item App::Chart::Weblink->new (name=>..., pred=>...)

Create and register a new weblink.  The return is a new
C<App::Chart::Weblink> object, though usually this is not of interest (only
all the links later with C<links_for_symbol> below).

=item @list = App::Chart::Weblink->links_for_symbol ($symbol)

Return a list of C<App::Chart::Weblink> objects for use on the given symbol.
Eg.

    my @links = App::Chart::Weblink->links_for_symbol ('BHP.AX');

=back

=head1 METHODS

=over 4

=item C<< $string = $weblink->name >>

Return the menu item name for C<$weblink>.  This can include a "_"
underscore for a mnemonic.

=item C<< $string = $weblink->url ($symbol) >>

Return the url for C<$weblink> on C<$symbol>.

=item C<< $bool = $weblink->sensitive ($symbol) >>

Return true if the menu item for C<$weblink> should be sensitive for
C<$symbol>, ie. there's a target URL for that symbol.

=item C<< $weblink->open ($symbol) >>

Open a web browser to show C<$weblink> for C<$symbol>.

=back

=head1 SEE ALSO

L<App::Chart::Weblink::SandP>, L<App::Chart::Gtk2::WeblinkMenu>

=cut
