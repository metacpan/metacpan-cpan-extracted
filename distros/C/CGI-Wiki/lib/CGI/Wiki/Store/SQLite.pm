package CGI::Wiki::Store::SQLite;

use strict;

use vars qw( @ISA $VERSION );

use CGI::Wiki::Store::Database;
use Carp qw/carp croak/;

@ISA = qw( CGI::Wiki::Store::Database );
$VERSION = 0.05;

=head1 NAME

CGI::Wiki::Store::SQLite - SQLite storage backend for CGI::Wiki

=head1 SYNOPSIS

See CGI::Wiki::Store::Database

=cut

# Internal method to return the data source string required by DBI.
sub _dsn {
    my ($self, $dbname) = @_;
    return "dbi:SQLite:dbname=$dbname";
}

=head1 METHODS

=over 4

=item B<new>

  my $store = CGI::Wiki::Store::SQLite->new( dbname => "wiki" );

The dbname parameter is mandatory.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {};
    bless $self, $class;
    @args{qw(dbuser dbpass)} = ("", "");  # for the parent class _init
    return $self->_init(%args);
}

=over 4

=item B<check_and_write_node>

  $store->check_and_write_node( node     => $node,
				checksum => $checksum,
                                %other_args );

Locks the node, verifies the checksum, calls
C<write_node_post_locking> with all supplied arguments, unlocks the
node. Returns 1 on successful writing, 0 if checksum doesn't match,
croaks on error.

=cut

sub check_and_write_node {
    my ($self, %args) = @_;
    my ($node, $checksum) = @args{qw( node checksum )};

    my $dbh = $self->{_dbh};
    $dbh->{AutoCommit} = 0;

    my $ok = eval {
        $dbh->do("END TRANSACTION");
        $dbh->do("BEGIN TRANSACTION");
        $self->verify_checksum($node, $checksum) or return 0;
        $self->write_node_post_locking( %args );
    };
    if ($@) {
        my $error = $@;
        $dbh->rollback;
	$dbh->{AutoCommit} = 1;
	if (   $error =~ /database is locked/
            or $error =~ /DBI connect.+failed/ ) {
            return 0;
        } else {
            croak "Unhandled error: [$error]";
        }
    } else {
        $dbh->commit;
	$dbh->{AutoCommit} = 1;
	return $ok;
    }
}

sub _get_list_by_metadata_sql {
    my ($self, %args) = @_;
    if ( $args{ignore_case} ) {
        return "SELECT node.name FROM node, metadata"
             . " WHERE node.name=metadata.node"
             . " AND node.version=metadata.version"
             . " AND metadata.metadata_type LIKE ? "
             . " AND metadata.metadata_value LIKE ? ";
    } else {
        return "SELECT node.name FROM node, metadata"
             . " WHERE node.name=metadata.node"
             . " AND node.version=metadata.version"
             . " AND metadata.metadata_type = ? "
             . " AND metadata.metadata_value = ? ";
    }
}

sub _get_comparison_sql {
    my ($self, %args) = @_;
    if ( $args{ignore_case} ) {
        return "$args{thing1} LIKE $args{thing2}";
    } else {
        return "$args{thing1} = $args{thing2}";
    }
}

sub _get_node_exists_ignore_case_sql {
    return "SELECT name FROM node WHERE name LIKE ? ";
}

1;
