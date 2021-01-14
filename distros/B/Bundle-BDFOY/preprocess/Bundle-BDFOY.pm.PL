use utf8;

my $package = require './Makefile.PL';

local $/;
print $package->make_file( <DATA>, $ARGV[0] );

__END__
package Bundle::BDFOY;

our $VERSION   = '%%VERSION%%';

1;

__END__

=encoding utf8

=head1 NAME

Bundle::BDFOY - install all modules by BDFOY

=head1 SYNOPSIS

	% cpan Bundle::BDFOY

=head1 CONTENTS

=over 4

%%LIST%%

=back

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2006-2021, brian d foy.

This code is licensed under the Artisitic License 2.0

=cut




