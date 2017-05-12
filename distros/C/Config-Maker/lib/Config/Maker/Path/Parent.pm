package Config::Maker::Path::Parent;

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

    $from->{-parent} ? $from->{-parent} : $from;
}

sub text { '..' }

1;

__END__

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
# arch-tag: 0a096ff5-f72a-47ee-b08f-4d06ac958d46
