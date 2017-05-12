package Class::DBI::UUID;
# $Id: UUID.pm,v 1.1 2005/01/31 18:51:22 cwest Exp $
use strict;

=head1 NAME

Class::DBI::UUID - Provide Globally Unique Column Values

=head1 SYNOPSIS

  package MyApp::User;
  use base qw[Class::DBI];

  __PACKAGE__->connection('dbi:SQLite:dbfile', '', '');
  __PACKAGE__->table(q[users]);
  __PACKAGE__->columns(Primary => 'id');
  __PACKAGE__->columns(Essential => qw[username password]);

  use Class::DBI::UUID;
  __PACKAGE__->uuid_columns('id');

  # Elsewhere..
  my $user = MyApp::User->create({
      username => 'user',
      password => 'pass',
  });
  
  print $user->id; # A UUID string.

=head1 DESCRIPTION

This module implements globally unique columns values. When an object
is created, the columns specified are given unique IDs. This is particularly
helpful when running in an environment where auto incremented primary
keys won't work, such as multi-master replication.

=cut

use base qw[Exporter Class::Data::Inheritable];
use vars qw[@EXPORT $VERSION];
$VERSION = sprintf "%d.%02d", split m/\./, (qw$Revision: 1.1 $)[1];
@EXPORT  = qw[uuid_columns uuid_columns_type];

use Data::UUID;

=head2 uuid_columns

  MyApp::User->uuid_columns(MyApp::User->columns('Primary'));

A C<before_create> trigger will be set up to set the values of each column
listed as input to a C<Data::UUID> string. Change the type of string output
using the C<uuid_columns_type> class method.

=cut

sub uuid_columns {
    my ($class, @cols) = @_;
    my $type = 'create_' . __PACKAGE__->_uuid_type;
    $class->add_trigger(before_create => sub {
        my ($self) = @_;
        foreach ( @cols ) {
            $self->{$_} = Data::UUID->new->$type;
        }
    });
}

=head2 uuid_columns_type

  MyApp::User->uuid_columns_type('bin'); # keep it small

By default the type will be C<str>. It's the largest, but its also the
safest for general use. Possible values are C<bin>, C<str>, C<hex>, and
C<b64>. Basically, anything that you can append to C<create_> and still
get a valid method name from C<Data::UUID>. Also returns the type to be
used.

Do not change this value on a whim. If you do change it, change it before
your call to C<uuid_columns>, or, call C<uuid_columns> again after it is
changed (therefore calling it before C<uuid_columns>, but also adding extra
triggers without need).

=cut

__PACKAGE__->mk_classdata('_uuid_type');
__PACKAGE__->_uuid_type('str');
sub uuid_columns_type {
    my $class = shift;
    return __PACKAGE__->_uuid_type(shift) if @_;
    return __PACKAGE__->_uuid_type;
}

1;

__END__

=head1 EXPORTS

This module is implemented as a mixin and therefore exports the
functions C<uuid_columns>, and C<uuid_columns_type> into
the caller's namespace. If you don't want these to be exported, then
load this module using C<require>.

=head1 SEE ALSO

L<Class::DBI>,
L<Data::UUID>,
L<perl>.

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2005 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut
