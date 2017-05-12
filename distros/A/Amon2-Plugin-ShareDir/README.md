# NAME

Amon2::Plugin::ShareDir - (EXPERIMENTAL) share directory

# SYNOPSIS

    # MyApp.pm
    __PACKAGE__->load_plugin('ShareDir');

    # in your app
    my $tmpl_path = catdir(MyApp->share_dir(), 'tmpl');

# DESCRIPTION

Put assets to share/ directory. Please look [Ukigumo::Agent](https://metacpan.org/pod/Ukigumo::Agent) for example.

**THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE**.

# STRATEGY

- `use catdir($c->base_dir, 'share')` if not installed to system
- use `dist_dir($dist_name)` if installed to system

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

[Amon2](https://metacpan.org/pod/Amon2), [File::ShareDir](https://metacpan.org/pod/File::ShareDir)

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
