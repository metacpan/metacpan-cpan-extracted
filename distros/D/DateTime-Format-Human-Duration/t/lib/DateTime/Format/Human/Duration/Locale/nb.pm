package DateTime::Format::Human::Duration::Locale::nb;
use strict;
use warnings;

# TODO: find a way to test fake locales without using real codes.
#       i.e. if/when somebody adds a real NB locale, I don't want this to cause
#            issues.
sub get_human_span_from_units {
    my ($duration_units, $args_hr) = @_;

    my %n = map { ($_ => abs $duration_units->{$_}) } keys %$duration_units;

    my $s = 'now';
    if ($n{years}) {
        $s =  $n{years} . "y";
    } elsif ($n{months}) {
        $s =  $n{months} . "mo";
    } elsif ($n{weeks}) {
        $s =  $n{weeks} . "w";
    } elsif ($n{days}) {
        $s =  $n{days} . "d";
    } elsif ($n{hours}) {
        $s =  $n{hours} . "h";
    } elsif ($n{minutes}) {
        $s =  $n{minutes} . "mi";
    } elsif ($n{seconds}) {
        $s =  "moments";
    }

    my $past = grep { $_ < 0 } values %$duration_units;
    my $say = '';
    if ($past && $args_hr->{past}) {
        $say = $args_hr->{past};
    } elsif (! $past && $args_hr->{future}) {
        $say = $args_hr->{future};
    }
    if ($say) {
        $s = $say =~ m{%s} ? sprintf($say, $s): "$say $s";
    }

    return $s;
}

1;
