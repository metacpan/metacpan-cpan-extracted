package CogBase::Connection::FileSystem;
use strict;
use warnings;
use CogBase::Connection -base;
use IO::All;

sub fetch_node {
    my ($self, $node) = @_;
    my $node_path = $self->_node_path($node);
    for my $file ($node_path->all_files) { 
        my ($field, $value) = ($file->filename, $file->all);
        if ($field eq '!') {
            bless $node, "CogBase::$value";
        }
        else {
            $node->{$field} = $value;
        }
    }
}

sub store_node {
    my ($self, $node) = @_;
    $self->_set_new_id($node) unless ($node->Id);
    
    my $node_path = $self->_node_path($node);
    my $head_path = $self->_head_path($node);

    for my $field ($node->_fields) {
        io->catfile($node_path, $field)->assert->print($node->$field);
    }
    io->catfile($node_path, '!')->assert->print($node->Type);
    symlink($node->Revision, $head_path);
}

sub query {
    my ($self, $query) = @_;
    die "Invalid query '$query'"
      unless $query =~ /^!(\w+)$/;
    my $query_type = $1;
    my $nodes_path = io->catdir( $self->db_location, 'nodes' );
    my $results = [];
    while (my $dir = $nodes_path->readdir) {
        my $type_file = io->catfile($nodes_path, $dir, '0');
        next unless $type_file->exists;
        my $head_revision = $type_file->link->readlink;
        if (io->catfile($type_file, '!')->all eq $query_type) {
            push @$results, "$dir-$head_revision";
        }
    }
    return @$results;
}

sub _node_path {
    my ($self, $node) = @_;
    ZZZ "Can't access node without Id and Revision"
      unless $node->Id && $node->Revision;
    return io->catdir(
        $self->db_location,
        'nodes',
        $node->Id,
        $node->Revision
    );
}

sub _head_path {
    my ($self, $node) = @_;
    return io->catdir(
        $self->db_location,
        'nodes',
        $node->Id,
        '0'
    );
}

sub _set_new_id {
    my ($self, $node) = @_;
    my $id;
    while ($id = _generate_id()) {
        $id = $self->_unique_id($id)
          or next;
        last;
    }
    $node->Id($id);
    $node->Revision(1);
}

sub _unique_id {
    my ($self, $id) = @_;
    $id =~ s/(...)/$1-/;
    return $id;
}

sub _generate_id {
    if (defined $CogBase::TEST_COGBASE_IDS) {
        my $id = <$CogBase::TEST_COGBASE_IDS>;
        chomp $id;
        return $id;
    }
    return uc(
        Convert::Base32::encode_base32(
            Digest::MD5::md5(
                Data::UUID->new->create_str()
            )
        )
    );
}

1;
