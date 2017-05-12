package App::Multigit::Loop;

use strict;
use warnings;
use IO::Async::Loop;
use 5.014;

our $VERSION = '0.18';

use base qw(Exporter);

our @EXPORT_OK = qw(loop);

=head1 NAME

App::Multigit::Loop - Holds the loop for App::Multigit

=head1 DESCRIPTION

This is here so App::Multigit and App::Multigit::Repo don't have to rely on each
other.

=head1 FUNCTIONS

=head2 loop

Returns the same IO::Async::Loop every time it's called in the same process tree.

Exported by request.

=cut

sub loop {
    state $loop = IO::Async::Loop->new;
    $loop;
}

1;

__END__

=head1 AUTHOR

Alastair McGowan-Douglas, C<< <altreus at perl.org> >>

=head1 BUGS

Please report bugs on the github repository L<https://github.com/Altreus/App-Multigit>.

=head1 LICENSE

Copyright 2015 Alastair McGowan-Douglas.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
