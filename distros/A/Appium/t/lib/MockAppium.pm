package MockAppium;

use strict;
use warnings;
use JSON;
use Appium;
use Test::More;
use Test::Deep;
use Test::LWP::UserAgent;
use Test::MockObject::Extends;

our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/endpoint_ok alias_ok/;

my $mock_appium;
my @aliases = keys %{ Appium::Commands->new->get_cmds };

sub new {
    my ($self, %args) = @_;
    my $tua = Test::LWP::UserAgent->new;
    my $fake_session_response = {
        cmd_return => {},
        cmd_status => 'OK',
        sessionId => '123124123'
    };

    $tua->map_response(qr{status}, HTTP::Response->new(200, 'OK'));
    $tua->map_response(qr{session}, HTTP::Response->new(204, 'OK', ['Content-Type' => 'application/json'], to_json($fake_session_response)));

    my $init_args = {ua => $tua};
    if (%args) {
        foreach (keys %args) {
            $init_args->{$_} = $args{$_};
        }
    }
    else {
        $init_args->{caps} = { app => 'fake' };
    }
    my $appium = Appium->new($init_args);

    $mock_appium = Test::MockObject::Extends->new($appium);

    $mock_appium->mock('_execute_command', sub { shift; wantarray ? @_ : \@_;});

    return $mock_appium;

}

sub endpoint_ok {
    my ($endpoint, $args, $expected) = @_;

    my ($res, $params) = $mock_appium->$endpoint(@{ $args });

    # check it's in the commands hash
    alias_ok($endpoint, $res);

    # validate the args get processed as expected
    cmp_deeply($params, $expected, $endpoint . ': params are properly organized');
}

sub alias_ok {
    my ($endpoint, $res) = @_;
    my @alias_found = grep { $_ eq $res->{command} } @aliases;
    return ok(@alias_found, $endpoint . ': has a valid endpoint alias');
}



1;
