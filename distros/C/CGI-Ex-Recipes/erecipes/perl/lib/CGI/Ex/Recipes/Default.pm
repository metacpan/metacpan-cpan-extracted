package CGI::Ex::Recipes::Default;

use warnings;
use strict;
use base qw(CGI::Ex::Recipes);
use utf8;
our $VERSION = '0.03';
sub info_complete { 0 }

sub skip { 0 }

# now the list of items is produced by CGI::Ex::Recipes::Template::Menu


1;# End of CGI::Ex::Recipes::Default

__END__


=head1 NAME

CGI::Ex::Recipes::Default - The default step!



=head1 SYNOPSIS

    http://localhost:8080/recipes/index.pl


=head1 METHODS

This step does not implement any method except C<skip> which returns 0.

=head1 AUTHOR

Красимир Беров, C<< <k.berov at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

Thanks to all good people on the planet.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Красимир Беров, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

