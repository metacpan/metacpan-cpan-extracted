[![Actions Status](https://github.com/janeskil1525/Daje-Workflow-FileChanged-Activity/actions/workflows/test.yml/badge.svg)](https://github.com/janeskil1525/Daje-Workflow-FileChanged-Activity/actions)
# NAME

Daje::Workflow::FileChanged::Activity

# SYNOPSIS

    use Daje::Workflow::FileChanged::Activity;

    my $activity = Daje::Workflow::FileChanged::Activity->new(
           db => $db,
           context => $context,
           error => $error,
    );

    $activity->changed_files();

# DESCRIPTION

NAME

Daje::Workflow::FileChanged::Activity - It's new $module

Daje::Workflow::FileChanged::Activity is ...

LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# REQUIRES

[Daje::Tools::Filechanged](https://metacpan.org/pod/Daje%3A%3ATools%3A%3AFilechanged) 

[Daje::Config](https://metacpan.org/pod/Daje%3A%3AConfig) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

## changed\_files($self)

    changed_files($self)();

# AUTHOR

janeskil1525 <janeskil1525@gmail.com>

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
