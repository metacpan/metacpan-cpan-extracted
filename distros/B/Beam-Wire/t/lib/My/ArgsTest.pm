package
    My::ArgsTest;

use Moo;

has got_args => ( is => 'ro' );
sub BUILDARGS {
    my ( $class, @args ) = @_;
    return { got_args => \@args };
}

sub got_args_hash {
    my ( $self, @keys ) = @_;
    my $hash = { @{ $_[0]->got_args } };
    if ( @keys ) {
        return [ map { $hash->{$_} } @keys ];
    }
    return $hash;
}

1;
