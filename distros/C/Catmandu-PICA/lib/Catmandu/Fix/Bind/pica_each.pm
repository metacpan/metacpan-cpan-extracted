package Catmandu::Fix::Bind::pica_each;

our $VERSION = '1.00';

use Moo;
use Catmandu::Sane;
use Catmandu::Util;
use Catmandu::Fix::Has;
use PICA::Path;

with 'Catmandu::Fix::Bind', 'Catmandu::Fix::Bind::Group';

has done => (is => 'ro');
has pica_path => (
    fix_arg => 1,
    coerce => sub { $_[0] ne '....' ? PICA::Path->new($_[0]) : undef },
    default => sub { '....' }
);

sub unit {
    my ($self,$data) = @_;
    $self->{done} = 0;
    $data;
}

sub bind {
    my ($self,$mvar,$code) = @_;

    return $mvar if $self->done;

    my $rows = $mvar->{record} // [];

    if ($self->pica_path) {
        @$rows = grep { $self->pica_path->match_field($_) } @{$rows};
    } 

    my @new = ();

    for my $row (@{$rows}) {

        $mvar->{record} = [$row];

        my $fixed = $code->($mvar);

        push @new, @{$fixed->{record}} if defined($fixed) && exists $fixed->{record};
    }

    $mvar->{record} = \@new if exists $mvar->{record};

    $self->{done} = 1;

    $mvar;
}

1;
__END__

=head1 NAME

Catmandu::Fix::Bind::pica_each - a binder that loops over PICA fields

=head1 SYNOPSIS

    # Only add field 039D subfield $9 to the editions when the subfield $a 
    contains a 'E-Paper'
    do pica_each()
        if pica_match("039Da","E-Paper")
            pica_map("039D9",editions.$append)
        end
    end

    # Delete all the 041A subject fields
    do pica_each()
        if pica_match("041A",".*")
            reject()
        end
    end

    do pica_each("0...")
        # process only level 0 fields
    end

=head1 DESCRIPTION

The pica_each binder will iterate over each individual PICA field and execute
the fixes only in context over each individual field. The current field is
bound to C<record.0>.

If a PICA record contains:

    041A    $9040073580$8Bodenbiologie
    041A    $9040674886$8Zeitschrift 

then the fix

    do pica_each()
        pica_map("041A8",subject.$append)
    end

will have the same effect as

    pica_map("041A8",subject.$append)

because C<pica_map> by default loops over all repeated PICA fields. But the 
C<pica_each> bind has the advantage to process fields in context. E.g. to 
only map fields where the subfield $8 doesn't contain 'Miscellaneous' you 
can write:

    do pica_each()
        unless pica_match("041A8","Miscellaneous")
            pica_map("041A8",subject.$append)
        end
    end

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut
