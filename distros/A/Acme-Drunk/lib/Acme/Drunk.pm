package Acme::Drunk;
use strict;

require Exporter;
use base qw[Exporter];
use vars qw[$VERSION @EXPORT %EXPORT_TAGS];

$VERSION     = '0.03';
@EXPORT      = qw[MALE FEMALE drunk floz_to_etoh proof_to_percent];
%EXPORT_TAGS = ( ':all' => \@EXPORT );

sub ML_IN_FLOZ () { 0.0338140226 }

sub   MALE () { 0 }
sub FEMALE () { 1 }

# Widmark r factor (reduced body mass).
# Men:   0.50-0.90 avg 0.68.
# Women: 0.45-0.63 avg 0.55.
sub   MALE_WIDMARK_R () { 0.68 }
sub FEMALE_WIDMARK_R () { 0.55 }

# Widmark beta factor (alcohol metabolized per hour).
# Between 1.0% and 2.4%, avg 1.7%.
sub WIDMARK_BETA () { 0.017 };

# Ethyl Alcohol weight in pounds.
sub ETOH_WEIGHT () { 0.0514 }

# 1987, Fitzgerald & Hume discover specific
# gravity of blood is important, at 1.055 g/ml.
sub GRAVITY_OF_BLOOD () { 1.055 }

# Body Alcohol Concentration
sub bac {
    my ($body_weight, $alcohol_weight) = @_;
    $alcohol_weight / $body_weight * 100;
}

# Portion of body that holds alcohol.
sub bha {
    my ($body_weight, $gender) = @_;
    $body_weight * ( $gender == MALE ? MALE_WIDMARK_R : FEMALE_WIDMARK_R );
}

# Water Tissue Alcohol Concentration
sub wtac {
    my ($body_weight, $alcohol_weight, $gender) = @_;
    bac( bha($body_weight, $gender), $alcohol_weight );
}

# Proof goes to 200.
sub proof_to_percent {
    my ($proof) = @_;
    $proof / 2;
}

# For N fluid ounces of alcohol, find pure alcohol content.
sub floz_to_etoh {
    my ($ounces, $percent) = @_;
    $ounces * $percent;
}

# For N ml of alcohol, find pure alcohol content.
sub ml_to_etoh {
    floz_to_etoh( $_[0] * ML_IN_FLOZ, $_[1] );
}

# Convert fluid_ounces of EtOH to weight in pounds.
sub etoh_to_lbs {
    my ($ounces) = @_;
    $ounces * ETOH_WEIGHT;
}

# multiply wtac with gravity of blood.
sub consider_gravity {
    my ($alcohol_weight) = @_;
    $alcohol_weight * GRAVITY_OF_BLOOD;
}

# Remove metabolized alcohol over drinking time.
sub remove_metabolized_alcohol {
    my ($alcohol_weight, $hours) = @_;
    $alcohol_weight - ( $hours * WIDMARK_BETA );
}

# Are you drunk?
sub drunk {
    my (%params) = @_;
    $params{gender} = MALE unless defined $params{gender};
    $params{body_weight}    ||= 150;
    $params{hours}          ||= 2;
    $params{alcohol_weight} = consider_gravity( etoh_to_lbs( $params{alcohol_weight} || 3 ) );

    my $concentration = wtac( @params{qw[body_weight alcohol_weight gender]} );
       $concentration = remove_metabolized_alcohol( $concentration, $params{hours} );

    return $concentration;
}

1;

__END__

=head1 NAME

Acme::Drunk - Get Drunk, Acme Style

=head1 SYNOPSIS

    use Acme::Drunk;

    my $bac = drunk(
		    gender         => MALE, # or FEMALE
		    hours          => 2,    # since start of binge
		    body_weight    => 160,  # in lbs
		    alcohol_weight => 3,    # oz of alcohol
                   );

   $bac >= 0.08 ? call_cab() : walk_home();

=head1 DESCRIPTION

Calculating an accurate Blood Alcohol Concentration isn't as easy as it
sounds. Acme::Drunk helps elevate the burden placed on the Average Joe,
or Jane, to know if they've had too much to drink.

You might think to yourself, "but wait a minute, all I need is a fancy
breathalizer test!" You'd be wrong. For the same reasons that The Man
are often wrong on the street, and have to bring you in for a blood
test. Those generic devices don't take into account important issues in
drunkenness, but Acme::Drunk does.

Now all you need to be a law abiding citizen is your laptop, and we all
have those at the pub, right? Right.

=head2 Constants

Acme::Drunk exports two constants, C<MALE> and C<FEMALE>. You're drunk
if you don't know which one to use.

=head2 C<drunk()>

C<drunk()> takes four named parameters, detailed below, and returns the
Blood Alcohol Concentration (BAC) as a number. Note that C<drunk()>
couldn't return a true value for drunkenness because not all
jurisdictions agree on what the proper BAC level is to be drunk.

=over 4

=item gender

Currently Acme::Drunk only works for humans, and only recognizes C<MALE>
and C<FEMALE> human genders. Use the constants exported for you to
identify your gender.

If your gender or species isn't supported, please email the author.

If you don't know your gender or species, you are drunk.

=item hours

This numeric value represents how long you have been drinking. If you
took your first sip three hours ago, it's important to note. Your body
metabolizes alcohol at a steady per-hour pace.

=item body_weight

Your body weight is also important. Not all people are created equal,
and the amount of alcohol one body can saturate is much different than
another body.

=item alcohol_weight

The weight of alcohol you've had in ounces. This can be hard to
calculate, and two helpful functions are exported for your use. Here is
a common example, Guiness Gold Lager.

  my $alcohol_weight = floz_to_etoh( 16, proof_to_percent( 8.48 ) );

Acme::Drunk can't do these sorts of calculations for you. You might
be a raging alcoholic, drinking 45 beers a night, or so many different
drinks that Acme::Drunk can no-longer keep track.

If there is interest, Acme::Drunk may have an accompanying
Acme::Drunk::Drinks package containing constants such as
C<GUINESS_DRAUGHT_CAN>, C<JACK_DANIELS>, or C<NyQUIL>. Please contact
the author.  Here would be an example.

  alcohol_weight => ( GUINESS_DRAUGHT_CAN*7 + JACK_DANIELS*3 ),

If you can't come up with the alcohol_weight you've had, don't worry,
you might not yet be drunk.

=back

=head2 C<proof_to_percent()>

Accepts one argument, the proof number. Does a simple calculation to
convert it to percent. Returns the percentage.

=head2 C<floz_to_etoh()>

Accepts two arguments, the number of ounces a drink was, and the
percentage of that drink that was alcohol. Returns the fluid ounces of
alcohol contained in the drink.

=head2 C<ml_to_etoh()>

For our less US-centric friends, this function is exactly like
C<floz_to_etoh()>, except its first argument is the number of ml
in a drink.

=head2 How it Works

Widmark's Formula for Blood Alcohol Content

  ( ( (FlozEtOH * 0.0514 lb/flozEtOH) * 1.044 g/ml )
    / (Lbs of person * Widmark r g%/mlhr) )
  - (Hours since first drink * Widmark beta)
  = BAC g%/ml = BAC g/dL = BAC% w/v

'nuff said.

=head1 AUTHOR

Casey West <F<casey@geeknest.com>>

=head1 COPYRIGHT

Copyright (c) 2003 Casey West, All Rights Reserved.
This module is released under the same terms as Perl itself.

=cut
