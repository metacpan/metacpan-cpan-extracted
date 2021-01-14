use utf8;

my $package = require './Makefile.PL';

local $/;
print $package->make_file( <DATA>, $ARGV[0] );

__END__
use 5.008;
use strict;
use warnings;

package Task::BDFOY;

our $AUTHORITY = 'cpan:BDFOY';
our $VERSION   = '%%VERSION%%';

1;

__END__

=pod

=encoding utf8

=head1 NAME

Task::BDFOY - All of BDFOY's distributions

=head1 DESCRIPTION

Task::BDFOY installs the modules authored or maintained by brian d foy.

Although this Task module requires 5.008, some of the modules require
higher versions.

=over 4

%%LIST%%

=back

=head1 BUGS

Please report any bugs to the GitHub project
L<https://github.com/briandfoy/Bundle-BDFOY>.

=head1 SEE ALSO

L<Task>.

=head1 AUTHOR

brian d foy C<< <bdfoy@gmail.com> >>

=head1 COPYRIGHT AND LICENCE

Copyright © 2014-2021, brian d foy.

This code is licensed under the Artisitic License 2.0

=cut
