package Apache::Wyrd::Site::WidgetIndex;
use base qw(Apache::Wyrd::Services::Index);
use strict;
use Carp;
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Site::WidgetIndex - Wrapper class to support Widget Class

=head1 SYNOPSIS

Typical BASENAME::WidgetIndex Implementation:

  package BASENAME::WidgetIndex;
  use strict;
  use base qw(Apache::Wyrd::Site::WidgetIndex);
  
  1;

Typical BASENAME::Widget Implementation:

  package BASENAME::Widget;
  use base qw(Apache::Wyrd::Site::Widget);
  use BASENAME::WidgetIndex;
  
  sub index {
    my ($self) = @_;
    return BASENAME::WidgetIndex->new;
  }
  
  1;



=head1 DESCRIPTION

Provides a simple interface to a MySQL table for storing data about widgets.

=head1 BUGS/CAVEATS

Not the most efficient way to store Widget information, but quick to
implement.  No BDB backend has been offered for this class, but a Widget's
index can be implemented for a non-mysql environment using an instance of
the C<Apache::Wyrd::Services::Index> class with the following code:

  package BASENAME::WidgetIndex;
  use base qw(Apache::Wyrd::Services::Index);
  
  sub new {
    my ($class) = @_;
    my $init = {
      file => '/var/www/BASENAME/db/widgetindex.db',
      strict => 1
    };
    return Apache::Wyrd::Services::Index::new($class, $init);
  }
  
  sub update_entry {
    my ($self, $entry) = @_;
    my $changed = 0;
    my $index = $self->read_db;
    my ($id, $id_is_new) = $self->get_id($entry->index_name);
    $index->db_get("\x02\%$id", my $digest);
    if ($digest ne $entry->index_digest) {
      $index = $self->write_db;
      $self->update_key($id, $entry->index_name);
      $self->update_key("\x00%" . $entry->index_name, $id);
      $self->update_key("\x02%" . $id, $entry->index_digest);
      $changed = 1;
    }
    $self->close_db;
    return $changed;
  }

1;

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Site::Widget

Base object for Widgets - semi-independent objects which enrich the content
of a page

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

sub new {
	my ($class, $init) = @_;
	$init = {} unless (ref($init) eq 'HASH');
	my $self = {};
	$self->{'table'} = $init->{'table'} || '_wyrd_widgets';
	bless $self, $class;
	return $self;
}

sub update_entry {
	my ($self, $entry) = @_;
	my $dbh = $entry->dbl->dbh;
	my $table = $self->{'table'};
	my $changed = 0;
	my $sh = $dbh->prepare("select digest from $table where name=?");
	my $stored_digest = undef;
	$sh->execute($entry->index_name);
	if ($sh->err) {
		my $failed = $self->_init_table($dbh, $table);
		#if the DB can't be used, assume the widget has changed
		return 1 if ($failed);
	} else {
		my $datum = $sh->fetchrow_arrayref;
		$stored_digest = $datum->[0];
	}
	if ($stored_digest ne $entry->index_digest) {
		if (not defined($stored_digest)) {
			#new entry, use insert;
			my $sh = $dbh->prepare("insert into $table set name=?, digest=?");
			$sh->execute( $entry->index_name, $entry->index_digest);
		} else {
			#new entry, use update;
			my $sh = $dbh->prepare("update $table set digest=? where name=?");
			$sh->execute($entry->index_digest, $entry->index_name);
		}
		$changed = 1;
	}
	return $changed;
}

sub _init_table {
	my ($self, $dbh, $table) = @_;
	my $sh = $dbh->prepare('show tables');
	unless ($dbh->ping) {
		carp "database handle stale.";
		return 1;
	}
	$sh->execute;
	my $exists = 0;
	while (my $aref = $sh->fetchrow_arrayref) {
		if ($aref->[0] eq $table) {
			$exists = 1;
		}
	}
	if ($exists) {
		carp "table exists, but can't be read.  Manual intervention is necessary";
		return 1;
	}
	my $error = 0;
	my $table_def =<<"DEF";
create table $table (
	name varchar(255),
	digest char(40)
) ENGINE=InnoDB CHARSET=UTF8
DEF
	$dbh->do($table_def);
	if ($dbh->err) {
		carp "Could not create widget table: " . $dbh->errstr;
	}
	$dbh->do("alter table $table add index (name)");
	return 0;
}

1;