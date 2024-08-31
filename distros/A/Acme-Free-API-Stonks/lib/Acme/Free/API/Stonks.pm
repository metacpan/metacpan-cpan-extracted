package Acme::Free::API::Stonks;

use strict;
use warnings;

our $VERSION = '1.0.0';

use HTTP::Tiny;
use JSON            qw/decode_json/;
use Util::H2O::More qw/baptise ddd d2o/;

use constant {
    BASEURL => "https://tradestie.com/api/v1/apps/reddit",
};

sub new {
    my $pkg  = shift;
    my $self = baptise { ua => HTTP::Tiny->new }, $pkg;
    return $self;
}

sub get {
    my $self = shift;
    my $resp = d2o $self->ua->get(BASEURL);
    return d2o -autoundef, decode_json $resp->content;
}

sub stonks {
    my $self = shift;
    return $self->get;
}

1;

__END__

=head1 NAME

Acme::Free::API::Stonks - Perl API client for the, I<top 50 stocks discussed on le'Reddit
subeddit - r/Wallstreetbets>, L<https://tradestie.com/apps/reddit/api/>.

This module provides the client, "stonks", that is available via C<PATH> after install.

=head1 SYNOPSIS

  #!/usr/bin/env perl
  
  use strict;
  use warnings;
  
  use Util::H2O::More qw/ddd/;
  use Acme::Free::API::Stonks qw//;
  
  my $stonk = Acme::Free::API::Stonks->new;
  
  printf STDERR "%-5s %-8s %-4s %4s\n", "tick", "sentiment", "score", "comments"; 
  foreach my $s (sort {$a->ticker cmp $b->ticker} $stonk->stonks->all) {
    printf "%-5s %-8s % 4.3f % 4d\n", $s->ticker // "na", $s->sentiment // "na", $s->sentiment_score // "nan", $s->no_of_comments // "nan";
  }

=head2 C<stonks> Commandline Client

After installing this module, simply run the command C<stonks> without any arguments, and it
will print a 4-column list of the top 50 stocks discussed on Reddit subeddit, C<r/Wallstreetbets>.

The example below is printing out the full list (at the time of this writing), sorting by the
4th column using C<sort> (this is the proper way to do it on the cli).

  shell> stonks | sort -nr -k 4
  tick  sentiment score comments
  NVDA  Bearish  -0.033  138
  INTC  Bullish   0.206   34
  AI    Bullish   0.245   26
  DG    Bearish  -0.049   19
  SMCI  Bullish   0.129   18
  QQQ   Bullish   0.294    9
  DLTR  Bullish   0.015    9
  AMD   Bullish   0.226    8
  TSLA  Bullish   0.168    7
  DELL  Bullish   0.120    6
  MU    Bullish   0.074    5
  LULU  Bearish  -0.050    5
  EOD   Bearish  -0.013    5
  AVGO  Bullish   0.116    5
  AAPL  Bullish   0.385    5
  OPEN  Bearish  -0.062    4
  DKS   Bearish  -0.444    4
  BABA  Bearish  -0.112    4
  AU    Bullish   0.063    4
  ULTA  Bullish   0.179    3
  PTON  Bullish   0.048    3
  IBM   Bullish   0.393    3
  HPE   Bullish   0.101    3
  CRWD  Bullish   0.503    3
  BBBY  Bearish  -0.060    3
  AMZN  Bearish  -0.045    3
  AFRM  Bearish  -0.144    3
  WOW   Bullish   0.586    2
  VS    Bearish   0.000    2
  UI    Bearish  -0.001    2
  SAVE  Bullish   0.809    2
  PDD   Bullish   0.230    2
  ON    Bearish  -0.379    2
  NOW   Bearish  -0.155    2
  MRVL  Bullish   0.335    2
  GOOG  Bearish  -0.463    2
  EV    Bullish   0.077    2
  UBS   Bearish   0.000    1
  TA    Bearish   0.000    1
  SR    Bearish  -0.359    1
  SIRI  Bearish   0.000    1
  PANW  Bullish   0.660    1
  MDB   Bullish   0.340    1
  FTC   Bearish  -0.758    1
  FAT   Bearish   0.000    1
  ESTC  Bearish   0.000    1
  COOL  Bullish   0.515    1
  CONE  Bearish   0.000    1
  ATEC  Bearish  -0.665    1
  ABC   Bearish  -0.563    1

=head1 DESCRIPTION

This fun module is to demonstrate how to use L<Util::H2O::More> to make
API SaaS modules and clients in a clean and idiomatic way. These kind of
APIs tracked at L<https://www.freepublicapis.com/> are really nice for
fun and practice because they don't require dealing with API keys in the
vast majority of cases. In some cases, the are actually useful.

=head1 METHODS

=over 4

=item C<new>

Instantiates object reference. No parameters are accepted.

=item C<stonks>

Object method that returns an ARRAY reference (based on the JSON returned
by this service), that's been give the additional ARRAY vmethods via
L<Util::H2O::More> such as C<< ->all >> (used in the L<SYNOPSIS> above).

=back

=head2 Internal Methods

=over 4

=item C<get>

Called internally by C<quote>. This method uses L<HTTP::Tiny> to call to the API.
Then L<Util::H2O::More>'s C<d2o> is used to deal with the resulting respons that has
an accessor called C<quote>. This is what's invoked that returns the actual ARRAY
refernce of stonks records (HASH refs).

=back

=head1 ENVIRONMENT

Nothing special required.

=head1 AUTHOR

Brett Estrade L<< <oodler@cpan.org> >>

=head1 BUGS

Please report.

=head1 LICENSE AND COPYRIGHT

Same as Perl/perl.
