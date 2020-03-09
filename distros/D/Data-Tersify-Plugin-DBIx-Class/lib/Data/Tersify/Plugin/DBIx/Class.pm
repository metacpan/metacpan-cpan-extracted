package Data::Tersify::Plugin::DBIx::Class;

use strict;
use warnings;

use DateTime;

our $VERSION = '1.001';
$VERSION = eval $VERSION;

=head1 NAME

Data::Tersify::Plugin::DBIx::Class - tersify DBIx::Class objects

=head1 VERSION

This is version 1.001.

=head1 SYNOPSIS

In e.g. the perl debugger

 DB<1> use Data::Tersify;
 DB<2> my $dbic_row = $schema->resultset(...)->find(...);
 DB<3> x Data::Tersify::tersify($dbic_row)

produces something like

 0 Data::Tersify::Summary::...::TableName (0xdeadbeef)=HASH(0xcafebabe)
   '_column_data' => HASH(0x1b32ca80)
      'date_created' => '2020-03-04 20:19:47'
      'id' => 558
      'status' => 'active'
   '_in_storage' => 1
   '_inflated_column' => HASH(0x1b318618)
        empty hash
   '_result_source' => Data::Tersify::Summary=SCALAR(0xbeefdead)
      -> 'DBIx::Class::ResultSource::Table (0xbabecafe) table_name'
   'related_resultsets' => HASH(0x7235e68)
      'related_table' => Data::Tersify::Summary=SCALAR(0x12345678)
         -> 'DBIx::Class::ResultSet (0x9abcdef0) ...::RelatedTable'

rather than screenfuls of stuff you don't care about.

If you delve into the guts of the result sources or result sets, you'll get
more chatty stuff, but it'll still be limited to amounts that the human brain
can deal with.

=head1 DESCRIPTION

This class provides terse description for various types of DBIx::Class
objects, when used with L<Data::Tersify>.

=head2 handles

It handles DBIx::Class::ResultSource::Table, DBIx::Class::ResultSource::View
and DBIx::Class::ResultSet objects. Surprisingly, that appears to be enough.

=cut

sub handles {
    (
        'DBIx::Class::ResultSource::Table',
        'DBIx::Class::ResultSource::View',
        'DBIx::Class::ResultSet'
    );
}

=head2 tersify

It tersifies DBIx::Class::ResultSource::Table or
DBIx::Class::ResultSource::View objects into just the name of
the table or view respectively.

It tersifies DBIx::Class::ResultSet into the name of the result class.

This tends to be the source of the vast majority of the unwanted chaff that
fills your screen. 

=cut

sub tersify {
    my ($self, $dbic_object) = @_;

    if (ref($dbic_object) =~ /^ DBIx::Class::ResultSource /x) {
        return $dbic_object->{name};
    } elsif (ref($dbic_object) eq 'DBIx::Class::ResultSet') {
        return $dbic_object->{_result_class};
    }
}

1;

