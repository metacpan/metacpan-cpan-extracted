package Data::Pipeline::Action::Regex;

use Moose;
with 'Data::Pipeline::Action';

has rules => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy => 1,
    default => sub { [ ] },
    predicate => 'has_rules',
);

sub map_item {
    my($self, $item) = @_;

    return $item unless $self -> has_rules;

    my($target_hash, $target_e);

    for(my $i = 0; $i < @{$self -> rules}; $i += 2) {
        ($target_hash, $target_e) = $self -> _decompose($self -> rules -> [$i], $item);
        local($_) = $target_hash -> {$target_e};
        $self -> rules -> [$i+1] -> ( $target_hash -> {$target_e} );
        $target_hash -> {$target_e} = $_;
    }

    return $item;
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

