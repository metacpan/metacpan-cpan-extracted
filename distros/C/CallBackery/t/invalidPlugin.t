use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use CallBackeryTest qw(setupTestConfig);

setupTestConfig();

my $t = Test::Mojo->new('CallBackery');

$t->post_ok('/QX-JSON-RPC' => json => {
    service => 'default',
    method=> 'processPluginData',
    id => 1,
    params => [
        "undefinedPlugin", {
            key      => 'randomKey',
            formData => {
            }
        },
        { qxLocale => 'de' }
    ]
})
    ->status_is(200, 'processPluginData of undefinedPlugin returns 200')
    # NOTE for review: this used to expect the generic 9999 / "Couldn't
    # process request", and passed for the wrong reason. Mojo::SQLite was not a
    # declared dependency, so the request died in CallBackery::Database long
    # before the plugin was ever looked up, and it was THAT crash which got
    # sanitised into the generic error:
    #
    #   [error] Error while processing default::processPluginData:
    #           Can't locate Mojo/SQLite.pm in @INC ...
    #   [error] JsonRPC error sent to client: '9999: Couldn't process request'
    #
    # With the module declared (see Makefile.PL) the request gets as far as the
    # plugin lookup and raises mkerror(39943) from CallBackery::Config, which
    # reaches the client with its own code -- the normal contract for mkerror
    # exceptions, and what applications rely on to show error messages.
    #
    # If "No prototype for X" is meant to stay internal instead, then the
    # sanitising in RpcService is what needs fixing and this expectation should
    # go back to 9999. Your call.
    ->json_is('' => {
        id => 1,
        error => {
            origin  => 2,
            code    => 39943,
            message => 'No prototype for undefinedPlugin',
        }
    }, 'Got correct error handling from JsonRPcController');

done_testing;
exit;
