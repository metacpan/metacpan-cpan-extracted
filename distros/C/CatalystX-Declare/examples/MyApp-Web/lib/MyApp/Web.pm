use CatalystX::Declare;

# specified roles (or rather: plugins) will be passed to ->setup().
application MyApp::Web
       with ConfigLoader
       with Static::Simple {

    # the $CLASS variable is automatically provided via CLASS.pm
    $CLASS->config(name => 'MyApp-Web');
}
