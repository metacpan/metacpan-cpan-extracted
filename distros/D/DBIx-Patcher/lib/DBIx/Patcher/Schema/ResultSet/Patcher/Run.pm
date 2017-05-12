package DBIx::Patcher::Schema::ResultSet::Patcher::Run;
BEGIN {
  $DBIx::Patcher::Schema::ResultSet::Patcher::Run::VERSION = '0.04';
}
BEGIN {
  $DBIx::Patcher::Schema::ResultSet::Patcher::Run::DIST = 'DBIx-Patcher';
}
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

=head2 create_run()

=cut
sub create_run {
    my($self) = @_;

    return $self->create({ start => \'default' });
}


1;
