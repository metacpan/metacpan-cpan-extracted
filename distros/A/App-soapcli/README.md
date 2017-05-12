[![Build Status](https://travis-ci.org/dex4er/soapcli.png?branch=master)](https://travis-ci.org/dex4er/soapcli)

# NAME

App::soapcli - SOAP client for CLI with YAML and JSON input and output

# SYNOPSIS

    my $app = App::soapcli->new(argv => [qw( calculator.yml calculator.url )]);
    $app->run;

# DESCRIPTION

This is core module for [soapcli](https://metacpan.org/pod/soapcli) utility.

# ATTRIBUTES

- argv : ArrayRef

    Arguments list with options for the application.

# METHODS

- new (_%args_)

    The default constructor.

- new\_with\_options (%args)

    The constructor which initializes the object based on `@ARGV` variable or
    based on array reference if _argv_ option is set.

- run ()

    Run the main job

# SEE ALSO

[http://github.com/dex4er/soapcli](http://github.com/dex4er/soapcli), [soapcli](https://metacpan.org/pod/soapcli).

# AUTHOR

Piotr Roszatycki <dexter@cpan.org>

# LICENSE

Copyright (c) 2011-2015 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)
