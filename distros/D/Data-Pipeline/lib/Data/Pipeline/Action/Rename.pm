package Data::Pipeline::Action::Rename;

use Moose;
with 'Data::Pipeline::Action';

has renames => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy => 1,
    default => sub { [ ] },
    predicate => 'has_renames',
);

has copies => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy => 1,
    default => sub { [ ] },
    predicate => 'has_copies',
);

sub map_item {
    my($self, $item) = @_;

    return $item unless $self -> has_renames || $self -> has_copies;

    my $i;
    my $num = scalar(@{$self -> copies});
    for($i = 0; $i < $num; $i+=2) {
        $self -> _copy( $self -> copies -> [$i], $self -> copies -> [$i+1], $item );
    }

    $num = scalar(@{$self -> renames});
    for($i = 0; $i < $num; $i+=2) {
        $self -> _rename( $self -> renames -> [$i], $self -> renames -> [$i+1], $item );
    }

    return $item;
}

sub _copy {
    my($self, $from, $to, $hash) = @_;

    my($to_hash, $to_e) = $self -> _decompose( $to, $hash );
    my($from_hash, $from_e) = $self -> _decompose( $from, $hash );

    $to_hash -> {$to_e} = $from_hash -> {$from_e} if $to_hash && $from_hash;
}

sub _rename {
    my($self, $from, $to, $hash) = @_;

    my($to_hash, $to_e) = $self -> _decompose( $to, $hash );
    my($from_hash, $from_e) = $self -> _decompose( $from, $hash );

    if($to_hash && $from_hash) {
        $to_hash -> {$to_e} = $from_hash -> {$from_e};
        delete $from_hash -> {$from_e};
    }
}

sub _decompose {
    my($self, $path, $hash) = @_;

    my($root, $rest) = split(/\./, $path, 2);

    if( !defined( $rest ) || $rest == '' ) {
        return($hash, $root);
    }

    if( !exists( $hash -> {$root} ) ) {
        $hash -> {$root} = { };
        return $self -> _decompose( $rest, $hash -> {$root} );
    }

    if( is_HashRef( $hash -> {$root} ) ) {
        return $self -> _decompose( $rest, $hash -> {$root} );
    }

    return( undef, undef );
}

1;

__END__

