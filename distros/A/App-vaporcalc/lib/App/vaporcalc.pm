package App::vaporcalc;
$App::vaporcalc::VERSION = '0.005004';
use Defaults::Modern;

use App::vaporcalc::Recipe;
use App::vaporcalc::RecipeResultSet;

use parent 'Exporter::Tiny';
our @EXPORT = our @EXPORT_OK = 'vcalc';

sub vcalc {
  my $recipe = blessed $_[0] ? $_[0] : App::vaporcalc::Recipe->new(@_);
  App::vaporcalc::RecipeResultSet->new(recipe => $recipe)
}


1;


=pod

=head1 NAME

App::vaporcalc - Calculate e-liquid recipes for DIY vaping

=head1 SYNOPSIS

  # From a shell:
  # sh$ vaporcalc

  ## From Perl:
  # use App::vaporcalc 'vcalc';
  # my $calculated = vcalc(...); 
  # (See EXPORTED)

=head1 WARNING

B<< Nicotine is a deadly poison and can be absorbed through the skin. >>

B<< Don't play with it if you don't respect it! >>

B<< Any nicotine-containing product should be tested to determine nicotine
concentration before use. Testing kits are available online. Be responsible. >>

=head1 DESCRIPTION

This is a set of simple utilities, roles, and objects for managing e-cig
liquid recipes and calculating C<ml> quantities based on a simple recipe
format.

From a shell, the L<vaporcalc(1)> frontend starts with a base recipe outline and
provides a command line interface to tweaking, saving, and loading recipes via
an extensible command engine (L<App::vaporcalc::CmdEngine>).

If you'd like to manage recipes from perl, see L</vcalc>, below (or use
L<App::vaporcalc::Recipe> directly).

=head1 EXPORTED

=head2 vcalc

  my $calculated = vcalc(
    target_quantity   => 30,   # ml

    base_nic_type     => 'PG', # nicotine base type (VG/PG, default PG)
    base_nic_per_ml   => 100,  # mg/ml (base nicotine concentration)
    target_nic_per_ml => 12,   # mg/ml (target nicotine concentration)

    target_pg         => 65,   # target PG percentage
    target_vg         => 35,   # target VG percentage

    # target flavor(s) name, percentage, base type
    # (or App::vaporcalc::Flavor objects)
    flavor_array => [
      +{ tag => 'Raspberry', percentage => 15, type => 'PG' },
      # ...
    ],
  );

  # Returns an App::vaporcalc::RecipeResultSet ->
  my $recipe = $calculated->recipe;   # App::vaporcalc::Recipe instance
  my $result = $calculated->result;   # App::vaporcalc::Result instance

A functional interface to L<App::vaporcalc::RecipeResultSet> -- takes a recipe
(as a list of key/value pairs or an L<App::vaporcalc::Recipe> object) and
returns a calculated L<App::vaporcalc::RecipeResultSet>.

See: 

L<App::vaporcalc::Recipe>

L<App::vaporcalc::Result>

L<App::vaporcalc::RecipeResultSet>

L<App::vaporcalc::Flavor>

=head1 TIPS

Less is more with many flavors; you may want to start around 5% or so and work
your way up.

Ideally, let juices steep for at least a day (longer is usually better!)
before sampling; shaking and warmth can help steep flavors faster.

Don't use flavors containing diacetyl (frequently used to create a buttery
taste). It's safe to eat, not safe to vape; the vapor causes "popcorn lung."
Acetoin will ferment into diacetyl; avoid that for the same reasons.

Anything containing artifical coloring or triglycerides is possibly not safe
to vape.

Flavors containing triacetin are reported to cause cracking in various plastic
tanks. Triacetin is a reasonable flavor carrier and probably OK to vape, but
may be rough on equipment. Same goes for citric acid -- and it may break down
into lung/throat irritants upon heating.

Buy nicotine from a reputable supplier and test it; there have been instances
of nicotine solutions marketed as 100mg/ml going as high as 250mg/ml!

=head1 TODO

=over

=item *

Optionally measuring by weight.

=item *

A pointy-clicky interface (Tkx or so?)

=item *

Integrated cost calculation

=back

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
