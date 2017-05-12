# Standard and Poors web links.

# Copyright 2007, 2008, 2009, 2010, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with Chart.  If not, see <http://www.gnu.org/licenses/>.


package App::Chart::Weblink::SandP;
use 5.008;
use strict;
use warnings;
use Carp;
use Locale::TextDomain ('App-Chart');

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use base 'App::Chart::Weblink';

sub new {
  my ($class, %options) = @_;
  my $symbol_table = $options{'symbol_table'}
    || croak 'Missing symbol_table';

  # symbols with an entry in %$symbol_table, if not otherwise given
  $options{'pred'} ||= App::Chart::Sympred::Proc->new
    (sub { return exists $symbol_table->{$_[0]} });

  return $class->SUPER::new
    (%options,
     name => __('Standard and _Poors index information'),
     desc => __('Open web browser at the Standard and Poors web site page for this index'),
     proc => 'subclass');
}

# language choices at page
#     http://www2.standardandpoors.com/portal/site/sp/en/au/page.siteselection/site_selection/0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0.html
# the ones applied here are just those which follow the basic pattern
#
sub url {
  my ($self, $symbol) = @_;
  my $url = $self->{'url_pattern'};

  my $lang = App::Chart::Glib::Ex::MoreUtils::lang_select (en => 'en/us',
                                               es => 'es/la',
                                               pt => 'pt/la');
  $url =~ s/{lang}/$lang/;

  $symbol = $self->{'symbol_table'}->{$symbol};
  $url =~ s/{symbol}/$symbol/;

  return $url;
}

1;
__END__

=for stopwords weblink Poors

=head1 NAME

App::Chart::Weblink::SandP -- web page links for symbols

=head1 SYNOPSIS

 use App::Chart::Weblink::SandP;
 App::Chart::Weblink::SandP->new (symbol_table => { '^GSPC' => '500' },
                                 url_pattern  => '...{lang}...{symbol}');

=head1 CLASS HIERARCHY

C<App::Chart::Weblink::SandP> is a subclass of C<App::Chart::Weblink>.

    App::Chart::Weblink
      App::Chart::Weblink::SandP

=head1 DESCRIPTION

An C<SandP> weblink goes to the Standard and Poors web site

=over 4

L<http://www2.standardandpoors.com>

=back

with a table of symbols and a URL pattern for the link.  The name and
description parts of the weblink are set automatically.  Normally this is
just for indexes created or marketed by S&P.

=head1 FUNCTIONS

=over 4

=item App::Chart::Weblink::SandP->new (symbol_table=>..., url_pattern=>...)

...

=back

=head1 SEE ALSO

L<App::Chart::Weblink>

=cut
