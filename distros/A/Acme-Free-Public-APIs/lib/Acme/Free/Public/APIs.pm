package Acme::Free::Public::APIs;

use strict;
use warnings;

our $VERSION = '0.9.8';

use HTTP::Tiny;
use JSON            qw/decode_json/;
use Util::H2O::More qw/baptise d2o ddd HTTPTiny2h2o/;

use constant {
    BASEURL => "https://www.freepublicapis.com/api/",
};

sub new {
    my $pkg  = shift;
    my $self = baptise { ua => HTTP::Tiny->new }, $pkg;
    return $self;
}

# https://www.freepublicapis.com/api/apis
# https://www.freepublicapis.com/api/apis/275

sub apis {
    my $self   = shift;
    my $params = d2o -autoundef, { @_ };
    my $URL    = sprintf "%s/apis", BASEURL;

    my $ret = [];
    if ($params->id) {
      $URL = sprintf "%s/%d", $URL, $params->id;
      my $resp = HTTPTiny2h2o $self->ua->get($URL);
      $ret = d2o -autoundef, [ $resp->content ]; # preset single item in an ARRAY
    }
    else {
      my $resp = HTTPTiny2h2o $self->ua->get($URL);
      $ret = $resp->content;
    }

    return $ret;
}


# https://www.freepublicapis.com/api/random
sub random {
    my $self = shift;
    my $URL  = sprintf "%s/random", BASEURL;
    my $resp = HTTPTiny2h2o $self->ua->get($URL);
    return $resp->content;
}

1;

__END__
=encoding UTF-8

=head1 NAME

Acme::Free::Public::APIs - Perl API client for ...

This module provides the client, "freeapis", that is available via C<PATH>
after install.

=head1 SYNOPSIS

  #!/usr/bin/env perl
    
  use strict;
  use warnings;
  
  use Acme::Free::Public::APIs qw//;

  my $api     = Acme::Free::Public::APIs->new->random;
  my $out     = <<EOAPI;
  id:            %d
  title:         %s%s
  site URL:      %s
  methods:       %s 
  health:        %d 
  documentation: %s
  description:   %s
  EOAPI
  printf $out, $api->id, ($api->emoji) ? sprintf("(%s) ",$api->emoji) : "",, $api->title, $api->source, $api->methods, $api->health, $api->documentation, $api->source;

=head2 C<freeapis> Commandline Client

After installing this module, simply run the command C<freeapis> without
any arguments, and it will print information regarding a randomly selected
free API that is listed on its site. Below you may see a project familiar
to some in the Perl community, the L<https://world.openfoodfacts.org/> Project.

  shell> freeapis
  id:            174
  title:         (🍲) OpenFoodFacts
  site URL:      https://freepublicapis.com/openfoodfacts
  methods:       1 
  health:        84 
  documentation: https://world.openfoodfacts.org/data
  description:   Open Food Facts is a food products database made by everyone, for everyone. You can use it to make better food choices, and as it is open data, anyone can re-use it for any purpose.
  shell>

=head1 DESCRIPTION

This is the Perl API for the Dog API, profiled at L<https://www.freepublicapis.com/api>. 

Contributed as part of the B<FreePublicPerlAPIs> Project described at,
L<https://github.com/oodler577/FreePublicPerlAPIs>.

This fun module is to demonstrate how to use L<Util::H2O::More> and
L<Dispatch::Fu> to make creating easily make API SaaS modules and
clients in a clean and idiomatic way. These kind of APIs tracked at
L<https://www.freepublicapis.com/> are really nice for fun and practice
because they don't require dealing with API keys in the vast majority of cases.

This module is the first one written using L<Util::H2O::More>'s C<HTTPTiny2h2o>
method that looks for C<JSON> in the C<content> key returned via L<HTTP::Tiny>'s
response C<HASH>.

=head1 METHODS

=over 4

=item C<new>

Instantiates object reference. No parameters are accepted.

=item C<< apis( [id => INT] ) >>

Requires no parameters, but may be passed the named parameter C<id>.

When called without any parameters, caller will get an C<ARRAY> reference
list of all APIs currently being reported as working.

When passed a specific API id, the returned C<ARRAY> reference contains just
the requested API C<HASH>..

See the C<freeapis> client's C<apis> subcommand for an example of what can
be done with the output of this method.

=item C<< random >>

Accepts no parameters. Returns full C<HASH> of information on a random
API. See the C<freeapis> client's C<random> subcommand to see an example of
what can be done with the output.

=back

=head1 C<freeapis> OPTIONS

=over 4

=item C<apis [--id INT] [--details]>

If called without the option C<--id> parameter, this returns a full list
sorted by C<id> in ascending order. Optional parameter, C<--details>,
will dump all the information available for each API.

   shell> freeapi apis | sort -k2 -r -n | less # sorting on column #2
   319   80 Monster Hunter World API
   320   95 World Wonders
   321  100 Church Calendar API
   322   95 Motivational API
   323   95 Buddha Quotes API
   324   95 Fortnite API
   325   95 Dragon Ball API
   326   95 Demon Slayer API
   327   90 Jojo's Bizarre API
  Found 300 APIs

Naturally, it can be used with the commandline to sort on other fields such
as C<health>, e.g.:

  shell> freeapi apis | sort -k2 -r -n | less # sorting on column #2
  321  100 Church Calendar API
  191  100 IP Geolocation & Currency Converter
  129  100 IP Geolocation API
   92   99 French Address API
   94   95 Carbon Intensity API
   90   95 JSONPlaceholder
   88   95 Stadt Land Fluss
   80   95 Dungeons and Dragons
   77   95 Digimon API
   75   95 Rick and Morty API
   72   95 kanye.rest
   71   95 Coinpaprika API
   70   95 Met Museum Collection
   68   95 Data USA
   62   95 Harry Potter API
   54   95 Star Wars API
   53   95 Nationalize API
   51   95 The Cat API
   48   95 Open Brewery DB
   47   95 Fruityvice
   46   95 Useless Facts API
   45   95 Corporate Bullshit Generator
   44   95 Virenmonitoring API
   36   95 Open Meteo
   35   95 CoinGecko API
   34   95 Agify.io
  326   95 Demon Slayer API
  ...
  shell>

Similarly, some clever commandline antics will allow one to do specific
queries by C<id> (first column) when piped to other commands.

When C<--id> is specified, it outputs just the corresponding line for the
referened API.

  shell>freeapi apis --id 321
  321  100 Church Calendar API

When C<--details> is added, it shows the full amount of information:

  shell>freeapi apis --id 321 --details
  id:            321
  title:         (📅) Church Calendar API
  site URL:      https://freepublicapis.com/church-calendar-api
  methods:       2 
  health:        100 
  documentation: http://calapi.inadiutorium.cz/api-doc
  description:   The Church Calendar API provides access to calendar data for any day, allowing users to retrieve various liturgical celebrations and details. It supports multiple languages and enables specific queries for feast names and calendar descriptions based on the selected calendar system.
  Found 1 API

=item C<random>

This subcommand takes no arguments. When run it prints out to C<STDOUT> all
the information provided for it.

  shell>
  id:            320
  title:         (🌍) World Wonders
  site URL:      https://freepublicapis.com/world-wonders
  methods:       2 
  health:        95 
  documentation: https://www.world-wonders-api.org/v0/docs
  description:   Free and open source API providing information about world wonders
  shell>

=back

=head2 Internal Methods

There are no internal methods to speak of.

=head1 ENVIRONMENT

Nothing special required.

=head1 AUTHOR

Brett Estrade L<< <oodler@cpan.org> >>

=head1 BUGS

Please report.

=head1 LICENSE AND COPYRIGHT

Same as Perl/perl.
