class Artist {

    has artworks   ( type => ArrayRef );
    has collectors ( type => ArrayRef, default => sub { [] } );
    has collected  ( type => Bool, default => false, is => rw );
    has status (
        enum => [ 'underground', 'homogenic' ],
        handles => 1,
        default => sub {
            my $self = shift;
            $self->has_collectors ? 'homogenic' : 'underground'
        }
    );

    method create {
        say $self->name . " create !";
    }

    method have_idea {
        say $self->name . ' have shitty idea' if true;
    }

    method has_collectors {
        if ( scalar @{ $self->collectors }  > 1 ) {
            $self->collected( true );
        }
    }

    # method new ($id, $name, @artworks, @collectors) {
    #     self.bless(:$id, :$name, :@artworks, :@collectors);
    # }
}
