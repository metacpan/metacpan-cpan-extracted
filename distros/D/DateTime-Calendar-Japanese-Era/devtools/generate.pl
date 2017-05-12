use strict;
use File::Spec;
use DateTime;
use Data::Dumper;
use Encode;
use YAML;

my (%ERAS_BY_ID, %ERAS_BY_NAME, @ERAS_BY_CENTURY, @SOUTH_REGIME_ERAS, @EXPORT_OK);

sub register_era {
    my %args = @_;

    my $id = $args{id};
    if (exists $ERAS_BY_ID{ $id }) {
        Carp::croak("Era with id = $id already exists!");
    }
    $ERAS_BY_ID{ $id } = \%args;

    $ERAS_BY_NAME{ $args{name} } = \%args;

    my $start_century = int($args{start}->year() / 100);
    my $end_century   = int($args{end}->year() / 100);

    $ERAS_BY_CENTURY[ $start_century ] ||= [];
    push @{ $ERAS_BY_CENTURY[ $start_century ] }, \%args;

    if ($start_century != $end_century && $end_century !~ /^-?inf/) {
        $ERAS_BY_CENTURY[ $end_century ] ||= [];
        push @{ $ERAS_BY_CENTURY[ $end_century ] }, \%args;
    }
}

sub load_from_file
{
    my($file, $opts) = @_;

    my $ID    = 0;
    my $NAME  = 1;
    my $START = 2;
    my $END   = 3;
    my @eras = @{ YAML::LoadFile($file) };
    foreach my $idx (0..$#eras) {
        my $this_era = $eras[$idx];
        my $start_date = DateTime->new(
            year      => $this_era->[$START]->[0],
            month     => $this_era->[$START]->[1],
            day       => $this_era->[$START]->[2],
            time_zone => 'Asia/Tokyo'
        );

        my $end_date;
        if ($idx == $#eras) {
            $end_date = DateTime::Infinite::Future->new();
        } else {
            my $next_era = $eras[$idx + 1];
            if ($this_era->[$END]) {
                $end_date = DateTime->new(
                    year      => $this_era->[$END]->[0],
                    month     => $this_era->[$END]->[1],
                    day       => $this_era->[$END]->[2],
                    time_zone => 'Asia/Tokyo'
                );
            } else {
                $end_date = DateTime->new(
                    year      => $next_era->[$START]->[0],
                    month     => $next_era->[$START]->[1],
                    day       => $next_era->[$START]->[2],
                    time_zone => 'Asia/Tokyo'
                );
            }
        }

        # we create the dates in Asia/Tokyo time, but for calculation
        # we really want them to be in UTC.
#        $start_date->set_time_zone('UTC');
#        $end_date->set_time_zone('UTC');

        if ( $opts->{is_south_regime} ) {
            push @SOUTH_REGIME_ERAS, [
                id => $this_era->[$ID],
                name => Encode::decode_utf8($this_era->[$NAME]),
                start => $start_date, 
                end => $end_date, 
            ];
        } else {
            register_era(
                id    => $this_era->[$ID],
                name  => Encode::decode_utf8($this_era->[$NAME]),
                start => $start_date,
                end   => $end_date
            );
        }
        push @EXPORT_OK, $this_era->[$ID];
    }
}


{
    load_from_file( File::Spec->catfile("share", "eras.yaml" ));
    load_from_file( File::Spec->catfile("share", "south-eras.yaml"), { is_south_regime => 1 });
}

local $Data::Dumper::Indent = 1;
local $Data::Dumper::Sortkeys = 1;
local $Data::Dumper::Terse = 1;

foreach my $id (keys %ERAS_BY_ID) {
    my $era = $ERAS_BY_ID{$id};
    my $start = $era->{start};
    my $end = $era->{end};
    $era->{start} = [ $start->year, $start->month, $start->day ];
    $era->{end} = [ $end->year, $end->month, $end->day ];
}

my $eras_by_id = Dumper(\%ERAS_BY_ID);
$eras_by_id =~ s/\A{/(/;
$eras_by_id =~ s/}\Z/)/;

my $eras_by_name = Dumper(\%ERAS_BY_NAME);
$eras_by_name =~ s/\A{/(/;
$eras_by_name =~ s/}\Z/)/;

print <<EOM
package DateTime::Calendar::Japanese::Era::data;
use strict;
our \%ERAS_BY_ID = $eras_by_id;
our \%ERAS_BY_NAME = $eras_by_name;
EOM

