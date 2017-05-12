use CatalystX::Declare;

application TestApp with CatalystX::Declare::TestPlugin {

    $CLASS->config(name => 'CatalystX::Declare TestApp');

    method ctx_method (ClassName $app: $arg) { $arg }
}

