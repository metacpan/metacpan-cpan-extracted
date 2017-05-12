use strict; 
use Test::More;
use Test::Requires 'JSON';
use DateTime; 
use DateTime::Event::SolarTerm qw/major_term_after minor_term_after/; 


my $data;
{
    open my $fh, '<', 't/terms.json';
    local $/;
    $data = JSON::decode_json( scalar(<$fh>) );
}

foreach my $y (sort keys %$data) {
    my $major = $data->{$y}->{major};
    my $minor = $data->{$y}->{minor};

    my $dt = DateTime->new(year => $y, month => 1, day => 1, time_zone => 'Asia/Tokyo');
    for my $i (0..11) {
        my $major_dt = major_term_after($dt);
        $major_dt->set_time_zone('Asia/Tokyo');
        is $major_dt->ymd, $major->[$i], "Got $major_dt, expected $major->[$i]";

        my $minor_dt = minor_term_after($dt);
        $minor_dt->set_time_zone('Asia/Tokyo');
        is $minor_dt->ymd, $minor->[$i], "Got $minor_dt, expected $minor->[$i]"; 

        $dt = $major_dt->add(days => 1);
    }
}

done_testing();

