package Config::Maker::Path::This;

use utf8;
use warnings;
use strict;

use Carp;
use Config::Maker::Path;
our @ISA = qw(Config::Maker::Path);

sub new {
    shift->bhash([qw/-tail/], @_);
}

sub match {
    my ($self, $from) = @_;

    $from;
}

sub text { '.' }

1;

__END__

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
# arch-tag: cea107ac-1f38-467e-b0e1-3bb978a56893
