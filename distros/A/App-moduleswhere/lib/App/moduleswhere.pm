package App::moduleswhere;

use warnings;
use strict;
our $VERSION = '0.03';

1;

__END__

=head1 NAME

App::moduleswhere - show modules' locations

=head1 SYNOPSIS

    mwhere Carp                              # show location of Carp.pm
    mwhere --no-require Carp                 # ditto, but no "require"
    mwhere -n Carp                           # ditto
    mwhere Carp CGI                          # show both Carp.pm and CGI.pm

=head1 DESCRIPTION

This small script(C<mwhere>) helps you show modules' locations.

You may ask, why not using `perldoc -l`? well, if the module doesn't
have any pod( this happens occasionally but does happen ), `perldoc -l` will
fail, in this case, mwhere comes to rescue!

check out C<Module::Info> if you want to know more info of modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 SEE ALSO

C<Module::Info>

=head1 AUTHOR

sunnavy  C<< sunnavy@bestpractical.com >>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

