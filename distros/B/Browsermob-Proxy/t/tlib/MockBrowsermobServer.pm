package tlib::MockBrowsermobServer;

use JSON;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/generate_mock_server/;

my $DEFAULT_PORT = 9091;

sub generate_mock_server {
    my $mock_port = shift || $DEFAULT_PORT;

    return {
        '/proxy/' => sub {
            my $req = shift;
            if ($req->method eq 'POST') {
                my $res = {
                    port => $mock_port
                };
                return $req->new_response(200, ['Content-Type' => 'application/json'], to_json($res));
            }
        },

        '/proxy/' . $mock_port => sub {
            my ($req) = @_;

            my %params;
            eval {
                %params = @{ $req->get_from_env("spore.params") };
            };

            if ($req->method eq 'DELETE') {
                die unless $params{port};
                return $req->new_response(200, ['Content-Type' => 'application/json'], "");
            }
        }
    }
}

1;
