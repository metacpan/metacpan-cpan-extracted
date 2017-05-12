package Data::AsObject::Array;
BEGIN {
  $Data::AsObject::Array::VERSION = '0.07';
}

# ABSTRACT: Base class for Data::AsObject arrayrefs

use strict;
use warnings;

use Carp qw(carp croak);
use Data::AsObject qw();
use namespace::clean -except => [qw/get/];


sub get {
    my $self = shift;
    my $index = shift;

    ref($self) =~ /^.*::(\w+)$/;
    my $mode = $1;

    # user wants to fetch a value
    if (defined $index) {
        # the value exists
        if ( exists $self->[$index] ) {
            my $data = $self->[$index];

            if ( $Data::AsObject::__check_type->($data) eq "ARRAY" ) {
                return bless $data, "Data::AsObject::Array::$mode";
            } elsif ( $Data::AsObject::__check_type->($data) eq "HASH" ) {
                return bless $data, "Data::AsObject::Hash::$mode";
            } else {
                return $data;
            }
        # the value does not exist
        } else {
            my $msg = "Attempting to access non-existing array index [$index]!";

            if ($mode eq 'Strict')
            {
                carp $msg;
            }
            elsif ($mode eq 'Loose')
            {
                croak $msg;
            }

            return;
        }
    } else {
        carp "Array accessor get requires index argument!"
    }
}

sub list
{
    my $self = shift;
    croak "List does not accept arguments" if @_;

    my $mode;
    $mode = 'strict' if $self->isa('Data::AsObject::Array::Strict');
    $mode = 'loose'  if $self->isa('Data::AsObject::Array::Loose');
    $mode = 'silent' if $self->isa('Data::AsObject::Array::Silent');
    carp "Unknown class used as Data::AsObject::Array" unless $mode;

    my @array;
    foreach  my $value (@$self)
    {
        $Data::AsObject::__check_type->($value)
            ? push @array, Data::AsObject::__bless_dao($value, $mode)
            : push @array, $value;
    }
    return @array;
}

package Data::AsObject::Array::Strict;
BEGIN {
  $Data::AsObject::Array::Strict::VERSION = '0.07';
}
use base 'Data::AsObject::Array';

package Data::AsObject::Array::Loose;
BEGIN {
  $Data::AsObject::Array::Loose::VERSION = '0.07';
}
use base 'Data::AsObject::Array';

package Data::AsObject::Array::Silent;
BEGIN {
  $Data::AsObject::Array::Silent::VERSION = '0.07';
}
use base 'Data::AsObject::Array';

1;


__END__
=pod

=for :stopwords Peter Shangov AnnoCPAN Arrayrefs arrayrefs hashrefs xml isa

=head1 NAME

Data::AsObject::Array - Base class for Data::AsObject arrayrefs

=head1 VERSION

version 0.07

=head1 SYNOPSIS

See L<Data::AsObject> for more information.

=head1 NAME

Data::AsObject::Array - Base class for Data::AsObject arrays

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

