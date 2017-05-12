package AlignDB::SQL::Library;
use Moose;
use AlignDB::SQL;

has 'lib' => ( is => 'rw', isa => 'Str', required => 1 );
has 'contents' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

sub BUILD {
    my $self = shift;

    my @lib_arr = ();
    if ( -e $self->lib ) {
        open my $lib_fh, '<', $self->lib
            or die "Cannot open file: $!";
        @lib_arr = <$lib_fh>;
        close $lib_fh;
    }

    my $curr_name = '';
    foreach (@lib_arr) {
        next if m{^\s*$};
        next if m{^\s*#};
        next if m{^\s*//};
        if (m{^\[([^\]]+)\]}) {
            $curr_name = $1;
            next;
        }
        if ($curr_name) {
            $self->{contents}->{$curr_name} .= $_;
        }
    }

    return;
}

sub retr {
    my $self        = shift;
    my $entity_name = shift;
    return $self->{contents}->{$entity_name};
}

#@method
#@returns AlignDB::SQL
sub retrieve {
    my $self        = shift;
    my $entity_name = shift;

    my $thaw_sql = AlignDB::SQL->thaw( $self->retr($entity_name) );
    return $thaw_sql;
}

sub set {
    my $self        = shift;
    my $entity_name = shift;
    my $entity      = shift;

    if ( ref $entity eq 'AlignDB::SQL' ) {
        $entity->_sql( $entity->as_sql );
        $self->{contents}->{$entity_name} = $entity->freeze;
    }
    else {
        $self->{contents}->{$entity_name} = $entity;
    }

    return $self;
}

sub drop {
    my $self        = shift;
    my $entity_name = shift;
    delete $self->{contents}->{$entity_name};
    return $self;
}

sub elements {
    my $self = shift;
    return sort keys %{ $self->{contents} };
}

sub dump {
    my $self   = shift;
    my $output = '';
    foreach ( sort keys %{ $self->{contents} } ) {
        $output .= sprintf "[%s]\n%s\n", $_, $self->{contents}->{$_};
    }
    return $output;
}

sub write {
    my $self = shift;

    open my $lib_fh, '>', $self->lib
        or die "Cannot open file: $!";
    print {$lib_fh} $self->dump;
    close $lib_fh;

    return $self;
}

1;

__END__
