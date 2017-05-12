package AnyEvent::DBI::Abstract::Limit;

use strict;
use warnings;
our $VERSION = '0.02';

use parent 'AnyEvent::DBI::Abstract';
use SQL::Abstract::Limit;
use DBI;

sub new {
    my ($class, $dsn, $user, $pass, %arg) = @_;
    my $self =  $class->SUPER::new($dsn, $user, $pass, %arg);
    $self->{_DBI_abstract} = SQL::Abstract::Limit->new;
    $self->abstract->{limit_dialect} = [ DBI->parse_dsn($dsn) ]->[1];
    return $self;
}

1;
__END__

=head1 NAME

AnyEvent::DBI::Abstract::Limit - AnyEvent::DBI + SQL::Abstract::Limit

=head1 SYNOPSIS

  use AnyEvent::DBI::Abstract::Limit;

=head1 DESCRIPTION

AnyEvent::DBI::Abstract::Limit is AnyEvent::DBI::Abstract subclass 
that uses SQL::Abstract::Limit.

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 SEE ALSO

L<AnyEvent::DBI::Abstract>

L<AnyEvent::DBI>

L<SQL::Abstract::Limit>

L<SQL::Abstract>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
