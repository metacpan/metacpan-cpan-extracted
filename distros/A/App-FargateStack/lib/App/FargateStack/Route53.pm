package App::FargateStack::Route53;

use strict;
use warnings;

use App::FargateStack::Constants;
use App::Route53;

use CLI::Simple::Constants qw(:booleans);

use Carp;
use Data::Dumper;
use English qw(no_match_vars);
use Text::ASCIITable::EasyTable;

use Role::Tiny;

########################################################################
sub cmd_list_zones {
########################################################################
  my ($self) = @_;

  my ($domain) = $self->get_args;

  croak sprintf "usage: %s list-zones domain\n", $ENV{SCRIPT_NAME}
    if !$domain;

  print {*STDOUT} $self->display_hosted_zones($domain);

  return $SUCCESS;
}

########################################################################
sub display_hosted_zones {
########################################################################
  my ( $self, $domain ) = @_;

  my $route53 = $self->fetch_route53;

  my $hosted_zones = $route53->list_hosted_zones;

  return
    if !$hosted_zones || !@{ $hosted_zones->{HostedZones} };

  my @zones = @{ $hosted_zones->{HostedZones} };

  my @data;

  foreach my $zone (@zones) {
    my $name = $zone->{Name};
    $name =~ s/[.]$//xsm;

    next if $domain !~ /$name/xsm;

    my ($zone_id) = ( split /\//xsm, $zone->{Id} )[-1];

    push @data, { 'Zone Id' => $zone_id, Name => $zone->{Name} };
  }

  my $title = sprintf 'Hosted Zones (%s)', $domain;

  my $table = easy_table(
    data          => [@data],
    table_options => { headingText => $title },
    columns       => [ 'Zone Id', 'Name' ],
  );

  return $table;
}

1;
