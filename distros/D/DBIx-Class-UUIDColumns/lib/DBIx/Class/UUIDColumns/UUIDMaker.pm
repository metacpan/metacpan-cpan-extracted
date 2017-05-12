package DBIx::Class::UUIDColumns::UUIDMaker;

use strict;
use warnings;

sub new {
    return bless {}, shift;
};

sub as_string {
    return undef;
};

1;
__END__

=head1 NAME

DBIx::Class::UUIDColumns::UUIDMaker - UUID wrapper module

=head1 SYNOPSIS

  package CustomUUIDMaker;
  use base qw/DBIx::Class::UUIDColumns::UUIDMaker/;

  sub as_string {
    my $uuid;
    ...magic incantations...
    return $uuid;
  };

=head1 DESCRIPTION

DBIx::Class::UUIDColumns::UUIDMaker is a base class used by the various uuid generation
subclasses.

=head1 METHODS

=head2 as_string

Returns the new uuid as a string.

=head2 new

Returns a new uuid maker subclass.

=head1 SEE ALSO

L<DBIx::Class::UUIDColumns>,
L<DBIx::Class::UUIDColumns::UUIDMaker::UUID>,
L<DBIx::Class::UUIDColumns::UUIDMaker::APR::UUID>,
L<DBIx::Class::UUIDColumns::UUIDMaker::Data::UUID>,
L<DBIx::Class::UUIDColumns::UUIDMaker::Win32::Guidgen>,
L<DBIx::Class::UUIDColumns::UUIDMaker::Win32API::GUID>,
L<DBIx::Class::UUIDColumns::UUIDMaker::Data::Uniqid>

=head1 AUTHOR

Chris Laco <claco@chrislaco.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.
