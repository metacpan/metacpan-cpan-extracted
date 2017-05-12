# NAME

App::pfswatch - a simple utility that detects changes in a filesystem and run given command

# SYNOPSIS

    use App::pfswatch->new;
    App::pfswatch->new_with_options(@ARGV)->run;

# DESCRIPTION

Use [pfswatch](http://search.cpan.org/perldoc?pfswatch) instead of App::pfswatch.

# AUTHOR

Yoshihiro Sasaki <ysasaki at cpan.org>

# SEE ALSO

[Filesys::Notify::Simple](http://search.cpan.org/perldoc?Filesys::Notify::Simple), [App::watcher](http://search.cpan.org/perldoc?App::watcher)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# COPYRIGHT

Copyright 2011 Yoshihiro Sasaki All rights reserved.
