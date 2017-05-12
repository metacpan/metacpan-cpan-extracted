package AnnoCPAN::Perldoc::DBI;

$VERSION = '0.22';

use strict;
use warnings;
use base 'Class::DBI';
use AnnoCPAN::Config;

our $dbh;
sub db_Main {
    my ($self) = @_;
    $dbh ||= DBI->connect(
        AnnoCPAN::Config->option('annopod_dsn'),
        { $self->_default_attributes },
    );
    return $dbh;
}

package AnnoCPAN::Perldoc::DBI::PodVer;
use base 'AnnoCPAN::Perldoc::DBI';
__PACKAGE__->table('podver');
__PACKAGE__->columns(Essential => qw(id name signature));

package AnnoCPAN::Perldoc::DBI::Note;
use base 'AnnoCPAN::Perldoc::DBI';
__PACKAGE__->table('note');
__PACKAGE__->columns(Essential => qw(id note user time));

package AnnoCPAN::Perldoc::DBI::NotePos;
use base 'AnnoCPAN::Perldoc::DBI';
__PACKAGE__->table('notepos');
__PACKAGE__->columns(Essential => qw(id podver note pos));
__PACKAGE__->has_a(note   => 'AnnoCPAN::Perldoc::DBI::Note');
__PACKAGE__->has_a(podver => 'AnnoCPAN::Perldoc::DBI::PodVer');

AnnoCPAN::Perldoc::DBI::PodVer->has_many(
    notepos => 'AnnoCPAN::Perldoc::DBI::NotePos');
AnnoCPAN::Perldoc::DBI::Note->has_many(
    notepos => 'AnnoCPAN::Perldoc::DBI::NotePos');




1;
