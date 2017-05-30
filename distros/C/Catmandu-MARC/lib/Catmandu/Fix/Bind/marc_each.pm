package Catmandu::Fix::Bind::marc_each;

use Moo;
use Catmandu::Util;

our $VERSION = '1.12';

with 'Catmandu::Fix::Bind';

has done => (is => 'ro');

sub unit {
    my ($self,$data) = @_;

    $self->{done} = 0;
    
    $data;
}

sub bind {
    my ($self,$mvar,$func,$name,$fixer) = @_;

    return $mvar if $self->done;

    my $rows = $mvar->{record} // [];

    my @new = ();

    for my $row (@{$rows}) {

        $mvar->{record} = [$row];

        my $fixed = $fixer->fix($mvar);

        push @new , @{$fixed->{record}} if defined $fixed && exists $fixed->{record} && defined $fixed->{record};
    }

    $mvar->{record} = \@new if exists $mvar->{record};

    $self->{done} = 1;

    $mvar;
}

1;

=head1 NAME

Catmandu::Fix::Bind::marc_each - a binder that loops over MARC fields

=head1 SYNOPSIS

    # Only add the 720 field to the authors when the $e subfield contains a 'promotor'
    do marc_each()
        if marc_match("720e","promotor")
            marc_map("720ab",authors.$append)
        end
    end

    # Delete all the 500 fields
    do marc_each()
        if marc_match("500",".*")
            reject()
        end
    end

=head1 DESCRIPTION

The marc_each binder will iterate over each individual MARC field and execute the fixes only 
in context over each individual field.

If a MARC record contains:

    500  $aTest
    500  $aTest2$eskip
    500  $aTest3

then the fix

    do marc_each()
        marc_map("500",note.$append)
    end

will have the same effect as

    marc_map("500",note.$append)

because C<marc_map> by default loops over all repeated MARC fields. But the C<marc_each> bind has the
advantage to process fields in context. E.g. to only map fields where the $e doesn't contain 'skip'
you can write:

    do marc_each()
        unless marc_match("500e",skip)
            marc_map("500",note.$append)
        end
    end

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut
