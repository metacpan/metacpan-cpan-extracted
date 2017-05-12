package CGI::Wiki::Store::Pg;

use strict;

use vars qw( @ISA $VERSION );

use CGI::Wiki::Store::Database;
use Carp qw/carp croak/;

@ISA = qw( CGI::Wiki::Store::Database );
$VERSION = 0.05;

=head1 NAME

CGI::Wiki::Store::Pg - Postgres storage backend for CGI::Wiki

=head1 REQUIRES

Subclasses CGI::Wiki::Store::Database.

=head1 SYNOPSIS

See CGI::Wiki::Store::Database

=cut

# Internal method to return the data source string required by DBI.
sub _dsn {
    my ($self, $dbname, $dbhost) = @_;
    my $dsn = "dbi:Pg:dbname=$dbname";
    $dsn .= ";host=$dbhost" if $dbhost;
    return $dsn;
}

=head1 METHODS

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
        $dbh->do("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE");
        $self->verify_checksum($node, $checksum) or return 0;
        $self->write_node_post_locking( %args );
    };
    if ($@) {
        my $error = $@;
        $dbh->rollback;
	$dbh->{AutoCommit} = 1;
	if ( $error =~ /can't serialize access due to concurrent update/i
            or $error =~ /could not serialize access due to concurrent update/i
           ) {
            return 0;
        } else {
            croak $error;
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
             . " AND lower(metadata.metadata_type) = ? "
             . " AND lower(metadata.metadata_value) = ? ";
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
        return "lower($args{thing1}) = lower($args{thing2})";
    } else {
        return "$args{thing1} = $args{thing2}";
    }
}

sub _get_node_exists_ignore_case_sql {
    return "SELECT name FROM node WHERE lower(name) = lower(?) ";
}


1;
