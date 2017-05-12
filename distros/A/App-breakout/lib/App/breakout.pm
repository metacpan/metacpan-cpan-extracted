package App::breakout;

use strict;
use 5.008_005;
our $VERSION = '0.04';

1;
__END__

=encoding utf-8

=head1 NAME

App::breakout - a command line tool to breakout from chroot jail

=head1 SYNOPSIS

  breakout /bin/bash

=head1 DESCRIPTION

App::breakout provides a command line application I<breakout>,
that executes the given command after breaking out the chroot jail
with root permission.

This application is for B<test only>. It does not exploit any OS vulnerability.
This tool can be used just by root user.

=head1 AUTHOR

Tomoya KABE E<lt>limitusus@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2015- Tomoya KABE

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
