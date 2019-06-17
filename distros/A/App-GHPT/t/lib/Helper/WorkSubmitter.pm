package Helper::WorkSubmitter;

use App::GHPT::Wrapper::OurMoose;

extends 'App::GHPT::WorkSubmitter';

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines, ControlStructures::ProhibitCascadingIfElse)
sub _choose {
    state $call_number;

    $call_number++;

    my $self        = shift;
    my $choose_args = shift;

    if ( $call_number == 1 ) {
        die 'unexpected arguments to _choose'
            unless $choose_args->@* == 4
            && $choose_args->[0] eq 'SRE'
            && $choose_args->[1] eq 'Team Data'
            && $choose_args->[2] eq 'Team Scotty'
            && $choose_args->[3] eq 'Team Uhura';

        return 'Team Uhura';
    }
    elsif ( $call_number == 2 ) {
        die 'unexpected arguments to _choose (2)'
            unless $choose_args->@* == 3
            && $choose_args->[0] eq 'Team Data'
            && $choose_args->[1] eq 'Team Scotty'
            && $choose_args->[2] eq 'Team Uhura';

        return 'Team Scotty';
    }
    elsif ( $call_number == 3 ) {
        die 'unexpected arguments to _choose (3)'
            unless $choose_args->@* == 2
            && $choose_args->[0] eq 'Scotty Member One'
            && $choose_args->[1] eq 'Scotty Member Two';

        return 'Scotty Member One';
    }
    elsif ( $call_number == 4 ) {
        die 'unexpected arguments to _choose (4)'
            unless $choose_args->@* == 2
            && $choose_args->[0] eq 'Scotty Member One'
            && $choose_args->[1] eq 'Scotty Member Two';

        return 'Scotty Member Two';
    }

    die 'Unexpected call to mock _choose method';
}
## use critic

1;
