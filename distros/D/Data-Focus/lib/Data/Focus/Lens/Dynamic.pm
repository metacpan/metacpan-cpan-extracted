package Data::Focus::Lens::Dynamic;
use strict;
use warnings;
use parent qw(Data::Focus::Lens);
use Scalar::Util qw(blessed);
use Carp;

sub new {
    my ($class, $param) = @_;
    return bless \$param, $class;
}

sub _associated_lens {
    my ($self, $target) = @_;
    if(blessed($target) && $target->can("Lens")) {
        my $assoc_lens = $target->Lens($$self);
        if(! eval { $assoc_lens->isa("Data::Focus::Lens") }) {
            croak "Lens method did not return a Data::Focus::Lens";
        }
        return $assoc_lens;
    }
    my $ref = ref($target);
    if(!defined($target) || $ref eq "HASH" || $ref eq "ARRAY") {
        require Data::Focus::Lens::HashArray::Index;
        return Data::Focus::Lens::HashArray::Index->new(index => $$self);
    }
    return undef;
}

sub apply_lens {
    my ($self, $applicative_class, $part_mapper, $target) = @_;
    my $assoc_lens = $self->_associated_lens($target);
    if(defined($assoc_lens)) {
        return $assoc_lens->apply_lens($applicative_class, $part_mapper, $target);
    }else {
        return $applicative_class->pure($target);
    }
}


1;
__END__

=pod

=head1 NAME

Data::Focus::Lens::Dynamic - a lens that dynamically creates an appropriate lens for the target

=head1 SYNOPSIS

    package Blessed::Data;
    
    sub new {
        my ($class) = @_;
        return bless {
            secret_data => "hoge",
            accessible_by_lens => {
                a => "a for Blessed::Data"
            },
        }, $class;
    }
    
    sub Lens {
        my ($self, $param) = @_;
        require Data::Focus::Lens::HashArray::Index;
        return (
            Data::Focus::Lens::HashArray::Index->new(index => "accessible_by_lens", allow_blessed => 1)
            . Data::Focus::Lens::HashArray::Index->new(index => $param)
        );
    }
    
    
    package main;
    use Data::Focus qw(focus);
    use Data::Focus::Lens::Dynamic;
    
    my $plain_data = { a => "a for plain_data" };
    my $blessed_data = Blessed::Data->new;
    
    my $lens = Data::Focus::Lens::Dynamic->new("a");
    focus($plain_data)->get($lens);        ## => "a for plain_data";
    focus($blessed_data)->get($lens);      ## => "a for Blessed::Data";
    
    $plain_data->{a} = $blessed_data;
    focus($plain_data)->get($lens, $lens); ## => "a for Blessed::Data";

=head1 DESCRIPTION

This is an implementation of L<Data::Focus::Lens>,
which dynamically creates an appropriate lens for the given target.
The actual focusing job is delegated to the dynamically created lens.

=head1 CLASS METHOD

=head2 $lens = Data::Focus::Lens::Dynamic->new($param)

The constructor.

The C<$lens> keeps the given C<$param>. The C<$param> is then passed to the dynamically created lens.


=head1 DELEGATION RULES

Here's how L<Data::Focus::Lens::Dynamic> creates the lens object appropriate for the C<$target>.

=over

=item *

If the C<$target> is a B<< blessed object and has C<Lens()> method >>, it calls the C<Lens()> method to obtain the appropriate lens.

    $appropriate_lens = $target->Lens($param)

If C<Lens()> method doesn't return a L<Data::Focus::Lens> object, it throws an exception.

=item *

If the C<$target> is a non-blessed B<< hash-ref or array-ref or C<undef> >>, it creates a L<Data::Focus::Lens::HashArray::Index>.

    $appropriate_lens = Data::Focus::Lens::HashArray::Index->new(index => $param)

=item *

B<Otherwise>, it does nothing. It creates no focal points.

=back

=head1 OBJECT METHODS

=head2 apply_lens

See L<Data::Focus::Lens>.

=head1 AUTHOR

Toshio Ito C<< <debug.ito at gmail.com> >>

=cut

