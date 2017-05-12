# NAME

App::envfile - runs another program with environment modified according to envfile

# SYNOPSIS

    $ cat > foo.env
    FOO=bar
    HOGE=fuga
    $ envfile foo.env perl -le 'print "$ENV{FOO}, $ENV{HOGE}"'
    bar, fuga

like

    $ env FOO=bar HOGE=fuga perl -le 'print "$ENV{FOO}, $ENV{HOGE}"'

# DESCRIPTION

App::envfile is sets environment from file.

envfile inspired djb's envdir program.

# METHODS

## new()

Create App::envfile instance.

    my $envf = App::envfile->new();

## run\_with\_env(\\%env, \\@commands)

Runs another program with environment modified according to `\%env`.

    $envf->run_with_env(\%env, \@commands);

## parse\_envfile($envfile)

Parse the `envfile`. Returned value is HASHREF.

    my $env = $envf->parse_envfile($envfile);

Supported file format are:

    KEY=VALUE
    # comment
    KEY2=VALUE
    ...

Or more supported `Perl`, `JSON` and `YAML` format.
The file format is determined by the extension type. extensions map are:

    pl   => Perl
    perl => Perl
    js   => JSON
    json => JSON
    yml  => YAML
    yaml => YAML

If this list does not match then considers that file is envfile.

Also, if you use `YAML` and `JSON`, [Data::Encoder](http://search.cpan.org/perldoc?Data::Encoder) and [YAML](http://search.cpan.org/perldoc?YAML) or [JSON](http://search.cpan.org/perldoc?JSON) module is required.

# AUTHOR

xaicron <xaicron@cpan.org>

# THANKS TO

tokuhirom

# COPYRIGHT

Copyright 2011 - xaicron

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
