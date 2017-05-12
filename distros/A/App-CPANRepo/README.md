# NAME

App::CPANRepo - Resolve repository of CPAN Module

# SYNOPSIS

    use App::CPANRepo;
    my $obj = App::CPANRepo->new;
    print $obj->resolve_repo('Module::Name');

# DESCRIPTION

App::CPANRepo is to resolve repository URL by CPAN module name.

# METHODS

## `$repo_url:Str = $obj->resolve_repo($module_name:Str)`

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
