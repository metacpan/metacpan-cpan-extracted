    use Class::Plugin::Util qw(supports);
    use MyPlugin::XMLSupport;

    # The plugin we want to use has a requires class method that
    # returns an array of modules it needs to function properly:
    
    my @required_modules = MyPlugin::XMLSupport->requires;

    # The plugin shouldn't use the required modules itself
    # it should only return the modules it needs to use in
    # in the required method above. The supports method checks
    # if the required modules are available and loads the modules
    # for us.

    if (supports( @required_modules )) {
        print 'We have XML support', "\n";

        my $xml = MyPlugin::XMLSupport->new( );
    
    }
