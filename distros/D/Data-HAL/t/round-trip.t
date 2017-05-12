use strictures;
use Test::More import => [qw(done_testing is_deeply)];
use Data::HAL qw();
use Data::Visitor::Callback qw();
use File::Slurp qw(read_file);
use JSON qw();

sub round_trip {
    my ($file_name, $json_in) = @_;
    my $json_out = Data::HAL->from_json($json_in)->as_json;
    my $in_unwrapped = Data::Visitor::Callback->new(
        array => sub {
            if (1 == @{ $_ }) {
                my ($inner) = @{ $_ };
                return $inner;
            }
            return $_;
        }
    )->visit(JSON::from_json($json_in));
    is_deeply JSON::from_json($json_out), $in_unwrapped, $file_name;
}

for my $file_name (sort glob 't/*.json') {
    round_trip($file_name, scalar read_file $file_name);
}

done_testing;
