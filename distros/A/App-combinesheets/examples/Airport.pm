package Airport;

use warnings;
use strict;

use LWP::Simple;
use JSON;

# small configuration section
my $warnings_enabled = 1;

# preparing a closure in order not to fetch the same airport code
# again and again
my $already_found = make_already_found();
sub make_already_found {
    my $already_found = {};
    return sub {
        my ($airport_name, $airport_code) = @_;
        if (exists $already_found->{$airport_name}) {
            if ($airport_code) {
                $already_found->{$airport_name} = $airport_code;
            }
            return $already_found->{$airport_name};
        } else {
            $already_found->{$airport_name} = ($airport_code ? $airport_code : 1);
            return 0;
        }
    }
}

# ----------------------------------------------------------------
# TBD...
# Find and return an airport code for airport names given either in
# the "Airport From" or "Airport To" column (whichever is still not
# filled). It may return more codes, comma-separated, if the airport
# names are ambiguos. Return an empty string if no airport code found.
# ----------------------------------------------------------------
sub find_code {
    my $class = shift;
    unshift (@_, $class)
        unless $class eq __PACKAGE__;
    my ($column, $header_line, $data_line) = @_;

    my $column_with_airport_name = $column->{ocol};
    $column_with_airport_name =~ s{Code}{Airport};

    my $airport_name;
    for (my $i = 0; $i < @$header_line; $i++) {
        if ($header_line->[$i] eq $column_with_airport_name) {
            $airport_name = $data_line->[$i];
            last;
        }
    }
    return '' unless $airport_name;

    # now we have an airport name...
    my $airport_code = $already_found->($airport_name);
    return $airport_code if $airport_code;

    #... go and find its airport code
    $airport_code = '';
    my $escaped_airport_name = $airport_name;
    $escaped_airport_name =~ tr{ }{+};
    my $url = "http://airportcode.riobard.com/search?q=$escaped_airport_name&fmt=json";
    my $content = get ($url);
    warning ("Cannot get a response for '$url'")
        unless defined $content;
    my $json = JSON->new->allow_nonref;
    my $data = $json->decode ($content);
    foreach my $code (@$data) {
        $airport_code .= $code->{code} . ",";
    }
    chop ($airport_code) if $airport_code;  # removing the trailing comma

    $already_found->($airport_name, $airport_code);
    return $airport_code;
}

sub warning {
    warn shift() if $warnings_enabled;
}

1;
__END__

http://airportcode.riobard.com/search?q=london+stansted&fmt=json
[{"code": "STN", "name": "London Stansted Airport", "location": "Essex (near London), England, United Kingdom"}]

or:

http://airportcode.riobard.com/search?q=london+lhr&fmt=json
[{"code": "LHR", "name": "London Heathrow Airport", "location": "London, United Kingdom"}]

error:

http://airportcode.riobard.com/search?q=londynek&fmt=json
[]
