package Catmandu::Fix::Bind::marc_each;

use Moo;
use Catmandu::Sane;
use Catmandu::Util;
use Catmandu::MARC;
use Catmandu::Fix::Has;
use namespace::clean;

our $VERSION = '1.281';

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
        if marc_has("500")
            reject()
        end
    end

=head1 DESCRIPTION

The marc_each binder will iterate over each individual MARC field and execute
the fixes on each individual field.

When a MARC record contains:

    500  $aTest
    500  $aTest2$eskip
    500  $aTest3

then the Fix bellow will copy all 500 fields to note field, except for 500 fields
with a subfield $e equal to "skip".

    do marc_each()
        unless marc_match("500e",skip)
            marc_map("500",note.$append)
        end
    end

The result will be:

    note: [Test,Test3]

=head1 CONFIGURATION

=head2 var

Optional loop variable which contains a HASH containing MARC field information
with the following fields:

    tag        - The names of the MARC field
    ind1       - The value of the first indicator
    ind2       - The value of the second indicator
    subfields  - An array of subfield items. Each subfield item is a
                 hash of the subfield code and subfield value

Given the MARC field:

    500[1, ] $aTest$bRest

the loop variable will contain:

    tag: 500
    ind1: 1
    ind2: ' '
    subfields:
        - a : Test
        - b : Rest

The loop variables can be used to have extra control over the processing of the
MARC fields.

    do marc_each(var:this)
      # Set the indicator1 of all MARC 500 field to the value "3"
      if all_match(this.tag,500)
        set_field(tag.ind1,3)
        # Store the result in the MARC file
        marc_remove(500)
        marc_paste(this)
      end
    end


=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut
