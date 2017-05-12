package Config::Maker::Path::Root;

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
    $Config::Maker::Eval::config->{root};
}

# Inherited find...

sub text { '/' };

sub str {
    my ($self) = @_;
    '/' . ($self->{-tail} ? $self->{-tail}->str : '');
}

1;

__END__

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
# arch-tag: 7fa5356d-0bfd-439f-a896-ec7436f7f387
