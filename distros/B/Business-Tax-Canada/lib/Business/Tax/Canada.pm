package Business::Tax::Canada;

use strict;
use warnings;
use Carp;

use vars qw/$VERSION @provinces/;
$VERSION = '0.04';
@provinces = qw/ab bc mb nb nf nt ns nu on pe qc sk yt/;

=head1 NAME

Business::Tax::Canada - perform Canadian GST/HST/PST calculations

=head1 SYNOPSIS

  use Business::Tax::Canada;

  my $tax = Business::Tax::Canada->new;

  my $price               = $tax->item(
                                from  => 'ab',
                                to    => 'ab'
                                price => 120);
  my $price_to_customer   = $price->full;     # 126.00
  my $gst_charged         = $price->gst;      # 6.00
  my $pst_charged         = $price->pst;      # 0
  my $net_charged         = $price->net;      # 120
  
=cut

sub new {
    my $class = shift;
    my %provinces = map { $_ => 1 } @provinces;
    bless {
        default   => $_[0],
        provinces => \%provinces,
    }, $class;
}

sub item { my $self = shift; $self->_item(@_) }

sub _item {
    my $self = shift;
    my %params = @_;
    my $province_from = $params{from} or croak "No 'from' province specified";
    my $province_to = $params{to} or croak "No 'to' province specified";
    my $price = $params{price} or croak "No price specified";
    return Business::Tax::Canada::Price->new($self, $price, $province_from, $province_to);
}

package Business::Tax::Canada::Price;

use vars qw/%GST_RATE %PST_RATE/;
%GST_RATE = (
    ab => 5,    bc => 12,   mb => 5,    nb => 13,
    nf => 13,   nt => 5,    ns => 15,   nu => 5,
    on => 13,   pe => 5,    qc => 5,    sk => 5,
    yt => 5,
);

%PST_RATE = (
    ab => 0,    bc => 0,    mb => 7,     nb => 0,
    nf => 0,    nt => 0,    ns => 0,     nu => 0,
    on => 0,    pe => 10,   qc => 9.975, sk => 5,
    yt => 0,
);

sub new {
    my ($class, $tax_obj, $price, $province_from, $province_to) = @_;
    my $self = {};
    
    my $gst_rate = ($GST_RATE{lc $province_to} || 0) / 100;
    my $pst_rate = ($PST_RATE{lc $province_to} || 0) / 100;

    $self->{net}  = $price;
    $self->{gst}  = $self->{net} * $gst_rate;
    $self->{pst} = 0;
    $self->{pst}  = $self->{net} * $pst_rate if (lc $province_from eq lc $province_to);
    if (lc $province_from =~ /pe/ || $province_to =~ /pe/) {
        # PEI charges PST tax on the GST tax amount
        $self->{pst} = ($self->{net} + $self->{gst}) * $pst_rate if (lc $province_from eq lc $province_to);
    }
    $self->{full} = $self->{net} + $self->{gst} + $self->{pst};

    bless $self, $class;
}

sub full { $_[0]->{full} || 0 }
sub gst  { $_[0]->{gst} || 0 }
sub pst  { $_[0]->{pst} || 0 }
sub tvq  { $_[0]->pst  }
sub net  { $_[0]->{net} || 0 }

=head1 DESCRIPTION

This module will allow you to calculate the Canadian GST and PST
charges on items.

There are several key processes:

=head1 CONSTRUCTING A TAX OBJECT

  my $tax = Business::Tax::Canada->new;

First, construct a tax object.  There is no need to specify a list of
provinces as all are supported.

=head1 PRICING AN ITEM

  my $price = $tax->item(
    from => $province_code,
    to => $province_code,
    $unit_price => $province_code);

You create a Price object by calling the 'item' constructor, with the
seller's location (from), the buyer's location (to), and the unit price.
From and to locations are used to determine if PST tax should be charged.

You must supply all values or you will receive an error.

=head1 CALCULATING THE COMPONENT PRICES

  my $price_to_customer = $price->full;
  my $gst_charged       = $price->gst;
  my $pst_charged       = $price->pst;
  my $tvq_charged       = $price->tvq;
  my $net_price_to_me   = $price->net;

Once you have the price, you can query it for either the 'full' price
that will be charged (GST + PST if applicable), the 'gst' amount, the 'pst'
amount, or the 'net' amount, which will be the same number you entered
in the item method.  tvq (Quebec's PST) is simply an alias to the pst
method.

=head1 PROVINCES AND RATES

This module uses the following rates and codes:

  Code  Province                GST/HST PST
  ab    Alberta                 5%      N/A
  bc    British Columbia        12%     N/A
  mb    Manitoba                5%      7%
  nb    New Brunswick           13%     N/A
  nf    Newfoundland & Labrador 13%     N/A
  nt    Northwest Territories   5%      N/A
  ns    Nova Scotia             15%     N/A
  nu    Nunavut                 5%      N/A
  on    Ontario                 13%     N/A
  pe    Prince Edward Island    5%      10%     *
  qc    Quebec                  5%      9.975%
  sk    Saskatchewan            5%      5%
  yt    Yukon Territory         5%      N/A
  
  * In Prince Edward Island only, the GST is included in the
    provincial sales tax base. You are also charged PST on GST.  

=head1 FEEDBACK

If you find this module useful, or have any comments, suggestions or
improvements, please let me know.  Patches are welcome!

=head1 AUTHOR

Created by Andy Grundman.  Updated and maintained by Steve Simms.

=head1 THANKS

This module was heavily inspired by Tony Bowden's Business::Tax::VAT.

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 WARRANTY

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;
