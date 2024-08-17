package CVSS::v4;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use Carp       ();
use List::Util qw(max min);

use base 'CVSS::Base';
use CVSS::Constants ();

our $VERSION = '1.13';
$VERSION =~ tr/_//d;    ## no critic

use constant DEBUG => $ENV{CVSS_DEBUG};

sub ATTRIBUTES          { CVSS::Constants->CVSS4_ATTRIBUTES }
sub SCORE_SEVERITY      { CVSS::Constants->CVSS4_SCORE_SEVERITY }
sub NOT_DEFINED_VALUE   { CVSS::Constants->CVSS4_NOT_DEFINED_VALUE }
sub VECTOR_STRING_REGEX { CVSS::Constants->CVSS4_VECTOR_STRING_REGEX }
sub METRIC_GROUPS       { CVSS::Constants->CVSS4_METRIC_GROUPS }
sub METRIC_NAMES        { CVSS::Constants->CVSS4_METRIC_NAMES }
sub METRIC_VALUES       { CVSS::Constants->CVSS4_METRIC_VALUES }

my $MAX_COMPOSED       = CVSS::Constants->CVSS4_MAX_COMPOSED;
my $CVSS_LOOKUP_GLOBAL = CVSS::Constants->CVSS4_LOOKUP_GLOBAL;
my $MAX_SEVERITY       = CVSS::Constants->CVSS4_MAX_SEVERITY;

sub version {'4.0'}

sub macro_vector {

    my ($self) = @_;

    my $eq1 = undef;
    my $eq2 = undef;
    my $eq3 = undef;
    my $eq4 = undef;
    my $eq5 = undef;
    my $eq6 = undef;


    # Specification https://www.first.org/cvss/v4.0/specification-document


    # EQ1 (Table 24)

    # Levels    Constraints
    # 0         AV:N and PR:N and UI:N
    # 1         (AV:N or PR:N or UI:N) and not (AV:N and PR:N and UI:N) and not AV:P
    # 2         AV:P or not(AV:N or PR:N or UI:N)

    $eq1 = 0 if ($self->M('AV') eq 'N' && $self->M('PR') eq 'N' && $self->M('UI') eq 'N');

    $eq1 = 1
        if (($self->M('AV') eq 'N' || $self->M('PR') eq 'N' || $self->M('UI') eq 'N')
        && !($self->M('AV') eq 'N' && $self->M('PR') eq 'N' && $self->M('UI') eq 'N')
        && !($self->M('AV') eq 'P'));

    $eq1 = 2 if ($self->M('AV') eq 'P' || !($self->M('AV') eq 'N' || $self->M('PR') eq 'N' || $self->M('UI') eq 'N'));

    DEBUG and say STDERR "-- MacroVector - EQ1 : $eq1";


    # EQ2 (Table 25)

    # Levels    Constraints
    # 0         AC:L and AT:N
    # 1         not (AC:L and AT:N)

    $eq2 = 0 if ($self->M('AC') eq 'L' && $self->M('AT') eq 'N');
    $eq2 = 1 if (!($self->M('AC') eq 'L' && $self->M('AT') eq 'N'));

    DEBUG and say STDERR "-- MacroVector - EQ2 : $eq2";

    # EQ3 (Table 26)
    # Levels    Constraints
    # 0         VC:H and VI:H
    # 1         not (VC:H and VI:H) and (VC:H or VI:H or VA:H)
    # 2         not (VC:H or VI:H or VA:H)

    $eq3 = 0 if ($self->M('VC') eq 'H' && $self->M('VI') eq 'H');

    $eq3 = 1
        if (!($self->M('VC') eq 'H' && $self->M('VI') eq 'H')
        && ($self->M('VC') eq 'H' || $self->M('VI') eq 'H' || $self->M('VA') eq 'H'));

    $eq3 = 2 if (!($self->M('VC') eq 'H' || $self->M('VI') eq 'H' || $self->M('VA') eq 'H'));

    DEBUG and say STDERR "-- MacroVector - EQ3 : $eq3";


    # EQ4 (Table 27)
    # Levels    Constraints
    # 0         MSI:S or MSA:S
    # 1         not (MSI:S or MSA:S) and (SC:H or SI:H or SA:H)
    # 2         not (MSI:S or MSA:S) and not (SC:H or SI:H or SA:H)

    $eq4 = 0 if ($self->M('MSI') eq 'S' || $self->M('MSA') eq 'S');

    $eq4 = 1
        if (!($self->M('MSI') eq 'S' || $self->M('MSA') eq 'S')
        && ($self->M('SC') eq 'H' || $self->M('SI') eq 'H' || $self->M('SA') eq 'H'));

    $eq4 = 2
        if (!($self->M('MSI') eq 'S' || $self->M('MSA') eq 'S')
        && !(($self->M('SC') eq 'H' || $self->M('SI') eq 'H' || $self->M('SA') eq 'H')));

    DEBUG and say STDERR "-- MacroVector - EQ4 : $eq4";

    # EQ5 (Table 28)

    # Levels    Constraints
    # 0         E:A
    # 1         E:P
    # 2         E:U

    $eq5 = 0 if ($self->M('E') eq 'A');
    $eq5 = 1 if ($self->M('E') eq 'P');
    $eq5 = 2 if ($self->M('E') eq 'U');

    DEBUG and say STDERR "-- MacroVector - EQ5 : $eq5";

    # EQ6 (Table 29)

    # Levels    Constraints
    # 0         (CR:H and VC:H) or (IR:H and VI:H) or (AR:H and VA:H)
    # 1         not (CR:H and VC:H) and not (IR:H and VI:H) and not (AR:H and VA:H)

    $eq6 = 0
        if (($self->M('CR') eq 'H' && $self->M('VC') eq 'H')
        || ($self->M('IR') eq 'H' && $self->M('VI') eq 'H')
        || ($self->M('AR') eq 'H' && $self->M('VA') eq 'H'));

    $eq6 = 1
        if (!($self->M('CR') eq 'H' && $self->M('VC') eq 'H')
        && !($self->M('IR') eq 'H' && $self->M('VI') eq 'H')
        && !($self->M('AR') eq 'H' && $self->M('VA') eq 'H'));

    DEBUG and say STDERR "-- MacroVector - EQ6 : $eq6";

    my @macro_vector = ($eq1, $eq2, $eq3, $eq4, $eq5, $eq6);
    my $macro_vector = join '', @macro_vector;

    DEBUG and say STDERR "-- MacroVector : $macro_vector";

    my $SEVERITY = {0 => 'HIGH', 1 => 'MEDIUM', 2 => 'LOW'};

    $self->{exploitability} = $SEVERITY->{$eq1};
    DEBUG and say STDERR "-- MacroVector EQ1 - Exploitability : $self->{exploitability}";

    $self->{complexity} = $SEVERITY->{$eq2};
    DEBUG and say STDERR "-- MacroVector EQ2 - Complexity : $self->{complexity}";

    $self->{vulnerable_system} = $SEVERITY->{$eq3};
    DEBUG and say STDERR "-- MacroVector EQ3 - Vulnerable System : $self->{vulnerable_system}";

    $self->{subsequent_system} = $SEVERITY->{$eq4};
    DEBUG and say STDERR "-- MacroVector EQ4 - Subsequent System : $self->{subsequent_system}";

    $self->{exploitation} = $SEVERITY->{$eq5};
    DEBUG and say STDERR "-- MacroVector EQ5 - Exploitation : $self->{exploitation}";

    $self->{security_requirements} = $SEVERITY->{$eq6};
    DEBUG and say STDERR "-- MacroVector EQ6 - Security Requirements : $self->{security_requirements}";

    return wantarray ? @macro_vector : "$macro_vector";

}

sub exploitability        { shift->{exploitability} }
sub complexity            { shift->{complexity} }
sub vulnerable_system     { shift->{vulnerable_system} }
sub subsequent_system     { shift->{subsequent_system} }
sub exploitation          { shift->{exploitation} }
sub security_requirements { shift->{security_requirements} }

sub M {

    my ($self, $metric) = @_;

    my $value = $self->SUPER::M($metric);

    # (From table 12)
    # This is the default value and is equivalent to Attacked (A) for the
    # purposes of the calculation of the score by assuming the worst case.
    return 'A' if ($metric eq 'E' && $value eq 'X');

    # (From table 13)
    # [...] This is the default value. Assigning this value indicates there is
    # insufficient information to choose one of the other values. This has the
    # same effect as assigning High as the worst case.
    return 'H' if ($metric eq 'CR' && $value eq 'X');
    return 'H' if ($metric eq 'IR' && $value eq 'X');
    return 'H' if ($metric eq 'AR' && $value eq 'X');

    return $value;

}

sub calculate_score {

    my ($self) = @_;

    if (%{$self->metrics}) {
        for (@{$self->METRIC_GROUPS->{base}}) {
            Carp::croak sprintf('Missing base metric (%s)', $_) unless ($self->metrics->{$_});
        }
    }

    # Set NOT_DEFINED
    $self->metrics->{E} //= 'X';

    $self->metrics->{CR}  //= 'X';
    $self->metrics->{IR}  //= 'X';
    $self->metrics->{AR}  //= 'X';
    $self->metrics->{MAV} //= 'X';
    $self->metrics->{MAC} //= 'X';
    $self->metrics->{MAT} //= 'X';
    $self->metrics->{MPR} //= 'X';
    $self->metrics->{MUI} //= 'X';
    $self->metrics->{MVC} //= 'X';
    $self->metrics->{MVI} //= 'X';
    $self->metrics->{MVA} //= 'X';
    $self->metrics->{MSC} //= 'X';
    $self->metrics->{MSI} //= 'X';
    $self->metrics->{MSA} //= 'X';

    $self->metrics->{S}  //= 'X';
    $self->metrics->{AU} //= 'X';
    $self->metrics->{R}  //= 'X';
    $self->metrics->{V}  //= 'X';
    $self->metrics->{RE} //= 'X';
    $self->metrics->{U}  //= 'X';


    # The following defines the index of each metric's values.
    # It is used when looking for the highest vector part of the
    # combinations produced by the MacroVector respective highest vectors.
    my $AV_levels = {N => 0.0, A => 0.1, L => 0.2, P => 0.3};
    my $PR_levels = {N => 0.0, L => 0.1, H => 0.2};
    my $UI_levels = {N => 0.0, P => 0.1, A => 0.2};

    my $AC_levels = {L => 0.0, H => 0.1};
    my $AT_levels = {N => 0.0, P => 0.1};

    my $VC_levels = {H => 0.0, L => 0.1, N => 0.2};
    my $VI_levels = {H => 0.0, L => 0.1, N => 0.2};
    my $VA_levels = {H => 0.0, L => 0.1, N => 0.2};

    my $SC_levels = {H => 0.1, L => 0.2, N => 0.3};
    my $SI_levels = {S => 0.0, H => 0.1, L => 0.2, N => 0.3};
    my $SA_levels = {S => 0.0, H => 0.1, L => 0.2, N => 0.3};

    my $CR_levels = {H => 0.0, M => 0.1, L => 0.2};
    my $IR_levels = {H => 0.0, M => 0.1, L => 0.2};
    my $AR_levels = {H => 0.0, M => 0.1, L => 0.2};

    my $E_levels = {U => 0.2, P => 0.1, A => 0.0};

    if (   $self->M('VC') eq 'N'
        && $self->M('VI') eq 'N'
        && $self->M('VA') eq 'N'
        && $self->M('SC') eq 'N'
        && $self->M('SI') eq 'N'
        && $self->M('SA') eq 'N')
    {
        $self->{scores}->{base} = '0.0';
        return 1;
    }

    my @macro_vector = $self->macro_vector;
    my $macro_vector = join '', @macro_vector;

    $self->{macro_vector} = $macro_vector;

    my ($eq1, $eq2, $eq3, $eq4, $eq5, $eq6) = @macro_vector;

    my $value = $CVSS_LOOKUP_GLOBAL->{$macro_vector};

    my $eq1_next_lower_macro          = join '', ($eq1 + 1, $eq2, $eq3, $eq4, $eq5, $eq6);
    my $eq2_next_lower_macro          = join '', ($eq1, $eq2 + 1, $eq3, $eq4, $eq5, $eq6);
    my $eq3eq6_next_lower_macro       = undef;
    my $eq3eq6_next_lower_macro_left  = undef;
    my $eq3eq6_next_lower_macro_right = undef;

    if ($eq3 == 1 && $eq6 == 1) {
        $eq3eq6_next_lower_macro = join '', ($eq1, $eq2, $eq3 + 1, $eq4, $eq5, $eq6);
    }
    elsif ($eq3 == 0 && $eq6 == 1) {
        $eq3eq6_next_lower_macro = join '', ($eq1, $eq2, $eq3 + 1, $eq4, $eq5, $eq6);
    }
    elsif ($eq3 == 1 && $eq6 == 0) {
        $eq3eq6_next_lower_macro = join '', ($eq1, $eq2, $eq3, $eq4, $eq5, $eq6 + 1);
    }
    elsif ($eq3 == 0 && $eq6 == 0) {
        $eq3eq6_next_lower_macro_left  = join '', ($eq1, $eq2, $eq3, $eq4, $eq5, $eq6 + 1);
        $eq3eq6_next_lower_macro_right = join '', ($eq1, $eq2, $eq3 + 1, $eq4, $eq5, $eq6);
    }
    else {
        $eq3eq6_next_lower_macro = join '', ($eq1, $eq2, $eq3 + 1, $eq4, $eq5, $eq6 + 1);
    }

    my $eq4_next_lower_macro = join '', ($eq1, $eq2, $eq3, $eq4 + 1, $eq5, $eq6);
    my $eq5_next_lower_macro = join '', ($eq1, $eq2, $eq3, $eq4, $eq5 + 1, $eq6);

    my $score_eq1_next_lower_macro          = $CVSS_LOOKUP_GLOBAL->{$eq1_next_lower_macro} || 'NaN';
    my $score_eq2_next_lower_macro          = $CVSS_LOOKUP_GLOBAL->{$eq2_next_lower_macro} || 'NaN';
    my $score_eq3eq6_next_lower_macro_left  = undef;
    my $score_eq3eq6_next_lower_macro_right = undef;
    my $score_eq3eq6_next_lower_macro       = undef;

    if ($eq3 == 0 && $eq6 == 0) {

        # multiple path take the one with higher score
        $score_eq3eq6_next_lower_macro_left  = $CVSS_LOOKUP_GLOBAL->{$eq3eq6_next_lower_macro_left}  || 'NaN';
        $score_eq3eq6_next_lower_macro_right = $CVSS_LOOKUP_GLOBAL->{$eq3eq6_next_lower_macro_right} || 'NaN';

        $score_eq3eq6_next_lower_macro = max($score_eq3eq6_next_lower_macro_left, $score_eq3eq6_next_lower_macro_right);

    }
    else {
        $score_eq3eq6_next_lower_macro = $CVSS_LOOKUP_GLOBAL->{$eq3eq6_next_lower_macro} || 'NaN';
    }


    my $score_eq4_next_lower_macro = $CVSS_LOOKUP_GLOBAL->{$eq4_next_lower_macro} || 'NaN';
    my $score_eq5_next_lower_macro = $CVSS_LOOKUP_GLOBAL->{$eq5_next_lower_macro} || 'NaN';

    #   b. The severity distance of the to-be scored vector from a
    #      highest severity vector in the same MacroVector is determined.
    my $eq1_maxes     = $MAX_COMPOSED->{eq1}->{$eq1};
    my $eq2_maxes     = $MAX_COMPOSED->{eq2}->{$eq2};
    my $eq3_eq6_maxes = $MAX_COMPOSED->{eq3}->{$eq3}->{$eq6};
    my $eq4_maxes     = $MAX_COMPOSED->{eq4}->{$eq4};
    my $eq5_maxes     = $MAX_COMPOSED->{eq5}->{$eq5};

    # compose them
    my @max_vectors = ();
    for my $eq1_max (@{$eq1_maxes}) {
        for my $eq2_max (@{$eq2_maxes}) {
            for my $eq3_eq6_max (@{$eq3_eq6_maxes}) {
                for my $eq4_max (@{$eq4_maxes}) {
                    for my $eq5_max (@{$eq5_maxes}) {
                        push @max_vectors, join '', ($eq1_max, $eq2_max, $eq3_eq6_max, $eq4_max, $eq5_max);
                    }
                }
            }
        }
    }

    DEBUG and say STDERR "-- MaxVectors: @max_vectors";

    my $severity_distance_AV = undef;
    my $severity_distance_PR = undef;
    my $severity_distance_UI = undef;

    my $severity_distance_AC = undef;
    my $severity_distance_AT = undef;

    my $severity_distance_VC = undef;
    my $severity_distance_VI = undef;
    my $severity_distance_VA = undef;

    my $severity_distance_SC = undef;
    my $severity_distance_SI = undef;
    my $severity_distance_SA = undef;

    my $severity_distance_CR = undef;
    my $severity_distance_IR = undef;
    my $severity_distance_AR = undef;


    # Find the max vector to use i.e. one in the combination of all the highests
    # that is greater or equal (severity distance) than the to-be scored vector.
DISTANCE: foreach my $max_vector (@max_vectors) {

        $severity_distance_AV
            = $AV_levels->{$self->M("AV")} - $AV_levels->{$self->extract_value_metric("AV", $max_vector)};
        $severity_distance_PR
            = $PR_levels->{$self->M("PR")} - $PR_levels->{$self->extract_value_metric("PR", $max_vector)};
        $severity_distance_UI
            = $UI_levels->{$self->M("UI")} - $UI_levels->{$self->extract_value_metric("UI", $max_vector)};

        $severity_distance_AC
            = $AC_levels->{$self->M("AC")} - $AC_levels->{$self->extract_value_metric("AC", $max_vector)};
        $severity_distance_AT
            = $AT_levels->{$self->M("AT")} - $AT_levels->{$self->extract_value_metric("AT", $max_vector)};

        $severity_distance_VC
            = $VC_levels->{$self->M("VC")} - $VC_levels->{$self->extract_value_metric("VC", $max_vector)};
        $severity_distance_VI
            = $VI_levels->{$self->M("VI")} - $VI_levels->{$self->extract_value_metric("VI", $max_vector)};
        $severity_distance_VA
            = $VA_levels->{$self->M("VA")} - $VA_levels->{$self->extract_value_metric("VA", $max_vector)};

        $severity_distance_SC
            = $SC_levels->{$self->M("SC")} - $SC_levels->{$self->extract_value_metric("SC", $max_vector)};
        $severity_distance_SI
            = $SI_levels->{$self->M("SI")} - $SI_levels->{$self->extract_value_metric("SI", $max_vector)};
        $severity_distance_SA
            = $SA_levels->{$self->M("SA")} - $SA_levels->{$self->extract_value_metric("SA", $max_vector)};

        $severity_distance_CR
            = $CR_levels->{$self->M("CR")} - $CR_levels->{$self->extract_value_metric("CR", $max_vector)};
        $severity_distance_IR
            = $IR_levels->{$self->M("IR")} - $IR_levels->{$self->extract_value_metric("IR", $max_vector)};
        $severity_distance_AR
            = $AR_levels->{$self->M("AR")} - $AR_levels->{$self->extract_value_metric("AR", $max_vector)};


        my @check = (
            $severity_distance_AV, $severity_distance_PR, $severity_distance_UI, $severity_distance_AC,
            $severity_distance_AT, $severity_distance_VC, $severity_distance_VI, $severity_distance_VA,
            $severity_distance_SC, $severity_distance_SI, $severity_distance_SA, $severity_distance_CR,
            $severity_distance_IR, $severity_distance_AR
        );

        # if any is less than zero this is not the right max
        foreach (@check) {
            next DISTANCE if ($_ < 0);
        }

        # if multiple maxes exist to reach it it is enough the first one
        last;
    }

    my $step = 0.1;

    my $current_severity_distance_eq1 = ($severity_distance_AV + $severity_distance_PR + $severity_distance_UI);
    my $current_severity_distance_eq2 = ($severity_distance_AC + $severity_distance_AT);
    my $current_severity_distance_eq3eq6
        = (   $severity_distance_VC
            + $severity_distance_VI
            + $severity_distance_VA
            + $severity_distance_CR
            + $severity_distance_IR
            + $severity_distance_AR);
    my $current_severity_distance_eq4 = ($severity_distance_SC + $severity_distance_SI + $severity_distance_SA);
    my $current_severity_distance_eq5 = 0;

    # if the next lower macro score do not exist the result is Nan
    # Rename to maximal scoring difference (aka MSD)
    my $available_distance_eq1    = $value - $score_eq1_next_lower_macro;
    my $available_distance_eq2    = $value - $score_eq2_next_lower_macro;
    my $available_distance_eq3eq6 = $value - $score_eq3eq6_next_lower_macro;
    my $available_distance_eq4    = $value - $score_eq4_next_lower_macro;
    my $available_distance_eq5    = $value - $score_eq5_next_lower_macro;

    my $percent_to_next_eq1_severity    = 0;
    my $percent_to_next_eq2_severity    = 0;
    my $percent_to_next_eq3eq6_severity = 0;
    my $percent_to_next_eq4_severity    = 0;
    my $percent_to_next_eq5_severity    = 0;

    my $normalized_severity_eq1    = 0;
    my $normalized_severity_eq2    = 0;
    my $normalized_severity_eq3eq6 = 0;
    my $normalized_severity_eq4    = 0;
    my $normalized_severity_eq5    = 0;

    # multiply by step because distance is pure
    my $max_severity_eq1    = $MAX_SEVERITY->{eq1}->{$eq1} * $step;
    my $max_severity_eq2    = $MAX_SEVERITY->{eq2}->{$eq2} * $step;
    my $max_severity_eq3eq6 = $MAX_SEVERITY->{eq3eq6}->{$eq3}->{$eq6} * $step;
    my $max_severity_eq4    = $MAX_SEVERITY->{eq4}->{$eq4} * $step;


    #   c. The proportion of the distance is determined by dividing
    #      the severity distance of the to-be-scored vector by the depth
    #      of the MacroVector.
    #   d. The maximal scoring difference is multiplied by the proportion of
    #      distance.

    my $n_existing_lower = 0;

    if (!isNaN($available_distance_eq1) && $available_distance_eq1 >= 0) {
        $n_existing_lower += 1;
        $percent_to_next_eq1_severity = ($current_severity_distance_eq1) / $max_severity_eq1;
        $normalized_severity_eq1      = $available_distance_eq1 * $percent_to_next_eq1_severity;
    }

    if (!isNaN($available_distance_eq2) && $available_distance_eq2 >= 0) {
        $n_existing_lower += 1;
        $percent_to_next_eq2_severity = ($current_severity_distance_eq2) / $max_severity_eq2;
        $normalized_severity_eq2      = $available_distance_eq2 * $percent_to_next_eq2_severity;
    }

    if (!isNaN($available_distance_eq3eq6) && $available_distance_eq3eq6 >= 0) {
        $n_existing_lower += 1;
        $percent_to_next_eq3eq6_severity = ($current_severity_distance_eq3eq6) / $max_severity_eq3eq6;
        $normalized_severity_eq3eq6      = $available_distance_eq3eq6 * $percent_to_next_eq3eq6_severity;
    }

    if (!isNaN($available_distance_eq4) && $available_distance_eq4 >= 0) {
        $n_existing_lower += 1;
        $percent_to_next_eq4_severity = ($current_severity_distance_eq4) / $max_severity_eq4;
        $normalized_severity_eq4      = $available_distance_eq4 * $percent_to_next_eq4_severity;
    }

    if (!isNaN($available_distance_eq5) && $available_distance_eq5 >= 0) {
        $n_existing_lower += 1;
        $percent_to_next_eq5_severity = 0;
        $normalized_severity_eq5      = $available_distance_eq5 * $percent_to_next_eq5_severity;
    }

    my $mean_distance = undef;

    # 2. The mean of the above computed proportional distances is computed.
    if ($n_existing_lower == 0) {
        $mean_distance = 0;
    }
    else {
      # sometimes we need to go up but there is nothing there, or down but there is nothing there so it's a change of 0.
        $mean_distance
            = (   $normalized_severity_eq1
                + $normalized_severity_eq2
                + $normalized_severity_eq3eq6
                + $normalized_severity_eq4
                + $normalized_severity_eq5)
            / $n_existing_lower;
    }

    # /

    DEBUG and say STDERR "-- Value: $value - MeanDistance: $mean_distance";

    # 3. The score of the vector is the score of the MacroVector
    #    (i.e. the score of the highest severity vector) minus the mean
    #    distance so computed. This score is rounded to one decimal place.
    $value -= $mean_distance;

    DEBUG and say STDERR "-- Value $value";

    $value = max(0.0, $value);
    $value = min(10.0, $value);

    my $base_score = sprintf('%.1f', $value);

    DEBUG and say STDERR "-- BaseScore: $base_score ($value)";

    $self->{scores}->{base} = $base_score;

    return 1;

}

sub extract_value_metric {
    my ($self, $metric, $vector_string) = @_;
    my %metrics = split /[\/:]/, $vector_string;
    return $metrics{$metric};
}

sub isNaN { !defined($_[0] <=> 9**9**9) }

sub to_xml {

    my ($self) = @_;

    my $metric_value_names = $self->METRIC_NAMES;

    $self->calculate_score unless ($self->base_score);

    my $version                = $self->version;
    my $metrics                = $self->metrics;
    my $base_score             = $self->base_score;
    my $base_severity          = $self->base_severity;
    my $environmental_score    = '';
    my $environmental_severity = '';

    my $xml_metrics = <<"XML";
  <base_metrics>
    <attack-vector>$metric_value_names->{AV}->{values}->{$metrics->{AV}}</attack-vector>
    <attack-complexity>$metric_value_names->{AC}->{values}->{$metrics->{AC}}</attack-complexity>
    <attack-requirements>$metric_value_names->{AT}->{values}->{$metrics->{AT}}</attack-requirements>
    <privileges-required>$metric_value_names->{PR}->{values}->{$metrics->{PR}}</privileges-required>
    <user-interaction>$metric_value_names->{UI}->{values}->{$metrics->{UI}}</user-interaction>
    <confidentiality-of-vulnerable-system>$metric_value_names->{VC}->{values}->{$metrics->{VC}}</confidentiality-of-vulnerable-system>
    <integrity-of-vulnerable-system>$metric_value_names->{VI}->{values}->{$metrics->{VI}}</integrity-of-vulnerable-system>
    <availability-of-vulnerable-system>$metric_value_names->{VA}->{values}->{$metrics->{VA}}</availability-of-vulnerable-system>
    <confidentiality-of-subsequent-system>$metric_value_names->{SC}->{values}->{$metrics->{SC}}</confidentiality-of-subsequent-system>
    <integrity-of-subsequent-system>$metric_value_names->{SI}->{values}->{$metrics->{SI}}</integrity-of-subsequent-system>
    <availability-of-subsequent-system>$metric_value_names->{SA}->{values}->{$metrics->{SA}}</availability-of-subsequent-system>
    <base-score>$base_score</base-score>
    <base-severity>$base_severity</base-severity>
  </base_metrics>
XML

    if ($self->metric_group_is_set('threat')) {
        $xml_metrics .= <<"XML";
  <threat_metrics>
    <exploit-maturity>$metric_value_names->{E}->{values}->{$metrics->{E}}</exploit-maturity>
  </threat_metrics>
XML
    }

    if ($self->metric_group_is_set('environmental')) {
        $xml_metrics .= <<"XML";
  <environmental_metrics>
    <confidentiality-requirement>$metric_value_names->{CR}->{values}->{$metrics->{CR}}</confidentiality-requirement>
    <integrity-requirement>$metric_value_names->{IR}->{values}->{$metrics->{IR}}</integrity-requirement>
    <availability-requirement>$metric_value_names->{AR}->{values}->{$metrics->{AR}}</availability-requirement>
    <modified-attack-vector>$metric_value_names->{MAV}->{values}->{$metrics->{MAV}}</modified-attack-vector>
    <modified-attack-complexity>$metric_value_names->{MAC}->{values}->{$metrics->{MAC}}</modified-attack-complexity>
    <modified-attack-requirements>$metric_value_names->{MAT}->{values}->{$metrics->{MAT}}</modified-attack-requirements>
    <modified-privileges-required>$metric_value_names->{MPR}->{values}->{$metrics->{MPR}}</modified-privileges-required>
    <modified-user-interaction>$metric_value_names->{MUI}->{values}->{$metrics->{MUI}}</modified-user-interaction>
    <modified-confidentiality-of-vulnerable-system>$metric_value_names->{MVC}->{values}->{$metrics->{MVC}}</modified-confidentiality-of-vulnerable-system>
    <modified-integrity-of-vulnerable-system>$metric_value_names->{MVI}->{values}->{$metrics->{MVI}}</modified-integrity-of-vulnerable-system>
    <modified-availability-of-vulnerable-system>$metric_value_names->{MVA}->{values}->{$metrics->{MVA}}</modified-availability-of-vulnerable-system>
    <modified-confidentiality-of-subsequent-system>$metric_value_names->{MSC}->{values}->{$metrics->{MSC}}</modified-confidentiality-of-subsequent-system>
    <modified-integrity-of-subsequent-systemt>$metric_value_names->{MSI}->{values}->{$metrics->{MSI}}</modified-integrity-of-subsequent-systemt>
    <modified-availability-of-subsequent-system>$metric_value_names->{MSA}->{values}->{$metrics->{MSA}}</modified-availability-of-subsequent-system>
    <environmental-score>$environmental_score</environmental-score>
    <environmental-severity>$environmental_severity</environmental-severity>
  </environmental_metrics>
XML
    }

    if ($self->metric_group_is_set('supplemental')) {
        $xml_metrics .= <<"XML";
  <supplemental_metrics>
    <safety>$metric_value_names->{S}->{values}->{$metrics->{S}}</safety>
    <automatable>$metric_value_names->{AU}->{values}->{$metrics->{AU}}</automatable>
    <recovery>$metric_value_names->{R}->{values}->{$metrics->{R}}</recovery>
    <value-density>$metric_value_names->{V}->{values}->{$metrics->{V}}</value-density>
    <vulnerability-response-effort>$metric_value_names->{RE}->{values}->{$metrics->{RE}}</vulnerability-response-effort>
    <provider-urgency>$metric_value_names->{U}->{values}->{$metrics->{U}}</provider-urgency>
  </supplemental_metrics>
XML
    }

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<cvssv$version xmlns="https://www.first.org/cvss/cvss-v$version.xsd"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="https://www.first.org/cvss/cvss-v$version.xsd https://www.first.org/cvss/cvss-v$version.xsd"
  >

$xml_metrics
</cvssv$version>
XML

}

1;

1;
__END__

=pod

=head1 NAME

CVSS::v4 - Parse and calculate CVSS v4.0 scores


=head1 DESCRIPTION

=head2 METHODS

L<CVSS::v4> inherits all methods from L<CVSS::Base> and implements the following new ones.

=over

=item $cvss->macro_vector

Calculate the macro vector.

=item $cvss->exploitability

Return the Exploitability severity.

=item $cvss->complexity

Return the Complexity severity.

=item $cvss->vulnerable_system

Return the Vulnerable System severity.

=item $cvss->subsequent_system

Return the Subsequent System severity.

=item $cvss->exploitation

Return the Exploitation severity.

=item $cvss->security_requirements

Return the Security Requirements severity.

=back

=head3 BASE METRICS

=over

=item $cvss->AV | $cvss->attackVector

=item $cvss->AC | $cvss->attackComplexity

=item $cvss->AT | $cvss->attackRequirements

=item $cvss->PR | $cvss->privilegesRequired

=item $cvss->UI | $cvss->userInteraction

=item $cvss->VC | $cvss->vulnConfidentialityImpact

=item $cvss->VI | $cvss->vulnIntegrityImpact

=item $cvss->VA | $cvss->vulnAvailabilityImpact

=item $cvss->SC | $cvss->subConfidentialityImpact

=item $cvss->SI | $cvss->subIntegrityImpact

=item $cvss->SA | $cvss->subAvailabilityImpact

=back

=head3 THREAT METRICS

=over

=item $cvss->E | $cvss->exploitMaturity

=back

=head3 ENVIRONMENTAL METRICS

=over

=item $cvss->CR | $cvss->confidentialityRequirement

=item $cvss->IR | $cvss->integrityRequirement

=item $cvss->AR | $cvss->availabilityRequirement

=item $cvss->MAV | $cvss->modifiedAttackVector

=item $cvss->MAC | $cvss->modifiedAttackComplexity

=item $cvss->MAT | $cvss->modifiedAttackRequirements

=item $cvss->MPR | $cvss->modifiedPrivilegesRequired

=item $cvss->MUI | $cvss->modifiedUserInteraction

=item $cvss->MVC | $cvss->modifiedVulnConfidentialityImpact

=item $cvss->MVI | $cvss->modifiedVulnIntegrityImpact

=item $cvss->MVA | $cvss->modifiedVulnAvailabilityImpact

=item $cvss->MSC | $cvss->modifiedSubConfidentialityImpact

=item $cvss->MSI | $cvss->modifiedSubIntegrityImpact

=item $cvss->MSA | $cvss->modifiedSubAvailabilityImpact

=back

=head3 SUPPLEMENTAL METRICS

=over

=item $cvss->S | $cvss->Safety

=item $cvss->AU | $cvss->Automatable

=item $cvss->R | $cvss->Recovery

=item $cvss->V | $cvss->valueDensity

=item $cvss->RE | $cvss->vulnerabilityResponseEffort

=item $cvss->U | $cvss->providerUrgency

=back


=head1 SEE ALSO

L<CVSS>, L<CVSS::v2>, L<CVSS::v3>

=over 4

=item [FIRST] CVSS Data Representations (L<https://www.first.org/cvss/data-representations>)

=item [FIRST] CVSS v4.0 Specification (L<https://www.first.org/cvss/v4.0/specification-document>)

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CVSS/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CVSS>

    git clone https://github.com/giterlizzi/perl-CVSS.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
