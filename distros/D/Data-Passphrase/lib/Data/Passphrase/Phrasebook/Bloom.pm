# $Id: Bloom.pm,v 1.4 2007/01/30 20:09:03 ajk Exp $

use strict;
use warnings;

package Data::Passphrase::Phrasebook::Bloom; {
    use Object::InsideOut qw(Data::Passphrase::Phrasebook);

    use Bloom::Filter;
    use Carp;

    # object attributes
    my @capacity   :Field(Std => 'capacity  ', Type => 'numeric');
    my @error_rate :Field(Std => 'error_rate', Type => 'numeric');

    my %init_args :InitArgs = (
        capacity   => {               Field => \@capacity,   Type => 'numeric'},
        error_rate => {Def => 0.0001, Field => \@error_rate, Type => 'numeric'},
    );

    # overload constructor so we can automatically determine the capacity
    sub new {
        my ($class, $arg_ref) = @_;

        # unpack arguments
        my $debug = $arg_ref->{debug};

        $debug and warn 'initializing ', __PACKAGE__, ' object';

        # base the capacity of the Bloom filter on the length of the file
        if (!exists $arg_ref->{capacity} && exists $arg_ref->{file}) {
            my $dictionary_file = $arg_ref->{file};
            open my ($dictionary_handle), $dictionary_file;
            while (<$dictionary_handle>) {
                ++$arg_ref->{capacity};
            }
            close $dictionary_handle;
        }

        # construct object
        my $self = $class->SUPER::new($arg_ref);

        return $self;
    }

    # construct a bloom filter
    sub init_filter {
        my ($self) = @_;

        $self->get_debug() and warn 'initializing bloom filter';

        return $self->set_filter(
            Bloom::Filter->new(
                capacity   => $self->get_capacity(),
                error_rate => $self->get_error_rate(),
            )
        );
    }

    # add phrases to the book
    sub add {
        my ($self, $phrase) = @_;
        return $self->get_filter()->add(ref $phrase ? @$phrase : $phrase);
    }

    # check the book
    sub has {
        my ($self, $phrase) = @_;
        return $self->get_filter()->check($phrase);
    }
}

1;
__END__

=head1 NAME

Data::Passphrase::Phrasebook::Bloom - Bloom filter phrasebooks

=head1 SYNOPSIS

See L<Data::Passphrase::Phrasebook/SYNOPSIS>.

=head1 DESCRIPTION

This module subclasses
L<Data::Passphrase::Phrasebook|Data::Passphrase::Phrasebook> to use a
Bloom filter to store the phrasebook instead of a Perl hash.  Bloom
filters offer memory economy at the cost of false positives.

=head2 Attributes

This module provides the following attributes in addition to the
attributes inherited from
L<Data::Passphrase::Phrasebook|Data::Passphrase::Phrasebook>.  These
attributes are passed along to the contained
L<Bloom::Filter|Bloom::Filter> object.

=head3 capacity

The total number of items the Bloom filter can hold.

=head3 error_rate

The maximum error rate of the Bloom filter.  The default is 0.0001.

=head1 AUTHOR

Andrew J. Korty <ajk@iu.edu>

=head1 SEE ALSO

Bloom::Filter(3), Data::Passphrase(3)
