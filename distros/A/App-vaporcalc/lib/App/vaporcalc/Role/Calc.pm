package App::vaporcalc::Role::Calc;
$App::vaporcalc::Role::Calc::VERSION = '0.005004';
use Defaults::Modern;
use App::vaporcalc::Types -all;

use App::vaporcalc::Result;

use Role::Tiny;

requires qw/
  target_quantity
  base_nic_per_ml
  base_nic_type
  target_nic_per_ml
  target_pg
  target_vg
  flavor_array
/;

method _base_multiplier { 100 / ($self->base_nic_per_ml || return 1) }

method _calc_base_nic_qty {
  return 0 unless $self->target_nic_per_ml;
  my $rate = $self->target_nic_per_ml / 100;
  my $base_amt_ml = $self->target_quantity * $rate; 
  $base_amt_ml * $self->_base_multiplier
}

method _calc_total_vg_qty {
  return 0 unless $self->target_vg;
  $self->target_quantity * ($self->target_vg / 100)
}

method _calc_total_pg_qty {
  return 0 unless $self->target_pg;
  $self->target_quantity * ($self->target_pg / 100)
}

method _calc_per_flavor_qty_obj {
  my $res = hash_of Object;

  for my $flav (@{ $self->flavor_array }) {
    $flav = FlavorObject->assert_coerce($flav) unless is_FlavorObject $flav;
    my $pcnt = $flav->percentage || next;
    my $ml = $self->target_quantity * ($pcnt / 100);
    $res->set(
      $flav->tag => hash(ml => $ml, type => $flav->type)->inflate
    );
  }

  # hash( $name => $obj );
  #   $obj->ml, $obj->type
  $res
}

method calc {
  my $vg_ml = $self->_calc_total_vg_qty;
  my $pg_ml = $self->_calc_total_pg_qty;
  my $flavor_data = $self->_calc_per_flavor_qty_obj;
  my $nic_base_ml = $self->_calc_base_nic_qty;

  # Subtract our nic base total from the appropriate PG or VG total:
  sswitch ($self->base_nic_type) {
    case 'PG': { $pg_ml -= $nic_base_ml if $pg_ml }
    case 'VG': { $vg_ml -= $nic_base_ml if $vg_ml }
    default: { confess "Unknown base_nic_type ", $self->base_nic_type }
  }

  # Same for flavors:
  for my $fname ($flavor_data->keys->all) {
    my $fobj  = $flavor_data->get($fname);
    my $ftype = $fobj->type;
    my $fml   = $fobj->ml;    # no, srsly
    sswitch ($ftype) {
      case 'PG': { $pg_ml -= $fml if $pg_ml }
      case 'VG': { $vg_ml -= $fml if $vg_ml }
      default: { confess "Unknown flavor_type $ftype" }
    }
  }

  my $flavors = hash_of RoundedResult() => (
    map {; $_ => sprintf '%.1f', $flavor_data->get($_)->ml }
      $flavor_data->keys->all
  );

  App::vaporcalc::Result->new(
    vg  => sprintf('%.1f', $vg_ml),
    pg  => sprintf('%.1f', $pg_ml),
    nic => sprintf('%.1f', $nic_base_ml),
    flavors => $flavors,
    total   => $self->target_quantity,
  )
}

1;

=pod

=head1 NAME

App::vaporcalc::Role::Calc - Calculate measurements for an e-liquid recipe

=head1 SYNOPSIS

  # See App::vaporcalc::Recipe, App::vaporcalc::RecipeResultSet
  use Moo;
  with 'App::vaporcalc::Role::Calc';

=head1 DESCRIPTION

This role provides a L</calc> method that produces an
L<App::vaporcalc::Result> object.

See L<App::vaporcalc::Recipe>, L<App::vaporcalc::RecipeResultSet>.

=head2 REQUIRES

Consumers need to implement the following methods:

  # Method           Returning
  target_quantity    (ml)
  base_nic_per_ml    (mg/ml)
  base_nic_type      ('PG' or 'VG')
  target_nic_per_ml  (mg/ml)
  target_pg          (percentage)
  target_vg          (percentage)
  flavor_array       (an array of App::vaporcalc::Flavor objects)

=head2 METHODS

=head3 calc

Performs the calculation & returns an L<App::vaporcalc::Result> object.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut

