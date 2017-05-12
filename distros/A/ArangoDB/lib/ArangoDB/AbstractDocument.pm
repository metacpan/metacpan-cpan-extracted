package ArangoDB::AbstractDocument;
use strict;
use warnings;
use utf8;
use 5.008001;
use Scalar::Util qw(weaken);

use overload
    q{""}    => sub { shift->document_handle },
    fallback => 1;

sub new {
    my ( $class, $conn, $doc ) = @_;
    die "Invalid argument for $class : undef" unless defined $doc;
    my $self = bless { connection => $conn, }, $class;
    weaken( $self->{connection} );
    my $id  = CORE::delete $doc->{_id};
    my $rev = CORE::delete $doc->{_rev};
    $self->{is_persistent} = defined $id && defined $rev;
    if ( $self->{is_persistent} ) {
        ( $self->{_collection_id}, $self->{_id} ) = split '/', $id;
        $self->{_document_handle} = $id;
        $self->{_rev}             = $rev;
    }
    map { $self->{$_} = CORE::delete $doc->{$_} } grep {/^_/} keys %$doc;
    $self->{document} = $doc;
    return $self;
}

sub id {
    $_[0]->{_id};
}

sub revision {
    $_[0]->{_rev};
}

sub collection_id {
    $_[0]->{_collection_id};
}

sub document_handle {
    $_[0]->{_document_handle};
}

sub content {
    return $_[0]->{document};
}

sub get {
    my ( $self, $attr_name ) = @_;
    return $self->{document}{$attr_name};
}

sub set {
    my ( $self, $attr_name, $value ) = @_;
    $self->{document}{$attr_name} = $value;
    return $self;
}

sub fetch {
    my ( $self, $no_etag ) = @_;
    my @header;
    if ( !$no_etag ) {
        push @header, 'If-None-Match' => $self->{_rev};
    }
    my $res = eval { $self->{connection}->http_get( $self->_api_path, \@header ) };
    if ($@) {
        $self->_server_error_handler( $@, 'fetch' );
    }
    if ( !defined $res || ref($res) eq 'HASH' ) {
        $self->{_rev} = delete $res->{_rev};
        $self->{document} = { map { $_ => $res->{$_} } grep { $_ !~ /^_/ } keys %$res };
    }
    return $self;
}

sub save {
    my ( $self, $with_rev_check ) = @_;
    eval {
        my $rev
            = $with_rev_check
            ? '?rev=' . $self->{_rev}
            : q{};
        $self->{connection}->http_put( $self->_api_path . $rev, $self->content );
    };
    if ($@) {
        $self->_server_error_handler( $@, 'update' );
    }
    $self->fetch(1);
    return $self;
}

sub delete {
    my $self = shift;
    eval { $self->{connection}->http_delete( $self->_api_path ) };
    if ($@) {
        $self->_server_error_handler( $@, 'delete' );
    }
    return $self;
}

sub _api_path {
    die 'Abstract method';
}

sub _server_error_handler {
    die 'Abstract method';
}

1;
__END__
