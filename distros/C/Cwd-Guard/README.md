# NAME

Cwd::Guard - Temporary changing working directory (chdir)

# SYNOPSIS

    use Cwd::Guard qw/cwd_guard/;
    use Cwd;

    my $dir = getcwd;
    MYBLOCK: {
        my $guard = cwd_guard('/tmp/xxxxx') or die "failed chdir: $Cwd::Guard::Error";
        # chdir to /tmp/xxxxx
    }
    # back to $dir

# DESCRIPTION

CORE::chdir Cwd:: Guard can change the current directory (chdir) using a limited scope.

# FUNCTIONS

- cwd\_guard($dir);

    chdir to $dir and returns Cwd::Guard object. return to current working directory, if this object destroyed.
    if failed to chdir, cwd\_guard return undefined value. You can get error messages with $Gwd::Guard::Error.

# AUTHOR

Masahiro Nagano <kazeburo {at} gmail.com>

# SEE ALSO

[File::chdir](https://metacpan.org/pod/File::chdir), [File::pushd](https://metacpan.org/pod/File::pushd)

# LICENSE

Copyright (C) Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
