# DESCRIPTION


A [Dancer](https://metacpan.org/module/Dancer) plugin that provides syntax
sugar for setting the status and returning a response in one shot.
This plugin imports the function `res()`.

# INSTALLATION

    cpan Dancer::Plugin::Res

# EXAMPLE

    use Dancer;
    use Dancer::Plugin::Res;
    post '/widgets' => sub {
        return res 400 => to_json { err => 'name is required' }
            unless param 'name';
        # ...
        return res 201, to_json { widget => $widget };
    };
    dance;

# DOCUMENTATION

See [Dancer::Plugin::Res](https://metacpan.org/module/Dancer::Plugin::Res).
Also, after installation, you can view the documentation via `man` or `perldoc`:

    man Dancer::Plugin::Res
