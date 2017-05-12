package Apache::Session::Serialize::MongoDB;

use 5.010;
use strict;

our $VERSION = '0.16';

sub serialize {
    my $session = shift;
}

sub unserialize {
    my $session = shift;
}

1;
__END__

=head1 NAME

Apache::Session::Serialize::MongoDB - Does nothing since MongoDB can store Perl
objects;

=head1 SYNOPSIS

 use Apache::Session::MongoDB;
 
 tie %hash, 'Apache::Session::MongoDB', $id, {};

=head1 DESCRIPTION

This module does nothing.

=head1 SEE ALSO

L<Apache::Session::MongoDB>

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2016 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
