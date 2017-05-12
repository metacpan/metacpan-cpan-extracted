package Config::Maker::Path::Meta;

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
    $Config::Maker::Eval::config->{meta};
}

# Inherited find...

sub text { 'META:' };

sub str {
    my ($self) = @_;
    'META:' . ($self->{-tail} ? $self->{-tail}->str : '');
}

1;

__END__

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

configit(1), perl(1), Config::Maker(3pm).

=cut
# arch-tag: 7546d781-84ec-41af-95e1-31ffb5db875c
