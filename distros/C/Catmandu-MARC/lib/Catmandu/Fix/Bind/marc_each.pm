package Catmandu::Fix::Bind::marc_each;

use Moo;
use Catmandu::Sane;
use Catmandu::Util;
use Catmandu::MARC;
use Catmandu::Fix::Has;
use namespace::clean;

our $VERSION = '1.231';

has var    => (fix_opt => 1);
has __marc => (is => 'lazy');

with 'Catmandu::Fix::Bind', 'Catmandu::Fix::Bind::Group';

sub _build___marc {
    Catmandu::MARC->instance;
}

sub unit {
    my ($self,$data) = @_;

    $data;
}

sub bind {
    my ($self,$mvar,$code) = @_;

    my $rows = $mvar->{record} // [];

    my @new = ();

    for my $row (@{$rows}) {

        $mvar->{record} = [$row];

        if ($self->var) {
            $mvar->{$self->var} = $self->__marc->marc_copy($mvar,"***")->[0]->[0];
        }

        my $fixed = $code->($mvar);

        push @new , @{$fixed->{record}} if defined $fixed && exists $fixed->{record} && defined $fixed->{record};

        if ($self->var) {
            delete $mvar->{$self->var};
        }
    }

    $mvar->{record} = \@new if exists $mvar->{record};

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

    # Loop over all the fields with a variable (see marc_copy, marc_cut and marc_paste for the content)
    do marc_each(var:this)
        if all_match(this.tag,300)
          # The '***' is short for the current tag in a marc_each loop
          marc_map(***a,test)
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

A variable name can be parsed to the marc_each, in which case an automatic marc_copy will be done
into the variable name. E.g

    do marc_each()
       marc_copy(***,this)
       ...
    end

and

    do marc_each(var:this)
       ...
    end

is similar

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut
