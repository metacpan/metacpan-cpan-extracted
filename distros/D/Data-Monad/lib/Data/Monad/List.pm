package Data::Monad::List;
use strict;
use warnings;
use Exporter qw/import/;
use base qw/Data::Monad::Base::MonadZero/;

our @EXPORT = qw/scalar_list list_unit list_zero list_flat_map_multi 
                 list_map_multi list_sequence/;

sub scalar_list(@) { __PACKAGE__->new(map { [$_] } @_) }

sub list_unit { __PACKAGE__->unit(@_) }
sub list_zero { __PACKAGE__->zero(@_) }
sub list_flat_map_multi(&@) { __PACKAGE__->flat_map_multi(@_) }
sub list_map_multi(&@) { __PACKAGE__->map_multi(@_) }
sub list_sequence { __PACKAGE__->sequence(@_) }

sub new {
    my $class = shift;
    bless [@_], $class;
}

sub unit {
    my $class = shift;
    $class->new([@_]);
}

sub zero {
    my $class = shift;
    $class->new();
}

sub flat_map {
    my ($self, $f) = @_;
    (ref $self)->new(map { @{$f->(@$_)} } @$self);
}

sub values {
    my $self = shift;
    @$self;
}

sub scalars {
    my $self = shift;
    map {
        @$_ == 1 or die "contained multiple values.";
        @$_;
    } $self->values;
}

1;

__END__

=head1 NAME

Data::Monad::List - The List monad.

=head1 SYNOPSIS

  use Data::Monad::List;
  my $m = scalar_list(10, 20);
  $m = $m->flat_map(sub {
      my $v = shift;
      scalar_list($v + 1, $v + 2);
  });
  my @result = $m->scalars; # (11, 12, 21, 22)

=head1 DESCRIPTION

Data::Monad::List represents non-deterministic values.

This module is marked B<EXPERIMENTAL>. API could be changed without any notice.

=head1 METHODS

=over 4

=item $list = scalar_list(@single_values)

Is the same as following lines.

  $list = Data::Monad::List->new([$single_values[0]], [$single_values[1]], ...)

=item $list = list_unit(@values)

=item $list = list_zero()

=item $f = list_flat_map_multi(\&f, $list1, $list2, ...)

=item $f = list_map_multi(\&f, $list1, $list2, ...)

=item $list = list_sequence($list1, $list2, ...)

These are shorthand of methods which has the same name.

=item $list = Data::Monad::List->new(\@values1, \@values2, ...)

The constructor of this class.

=item zero

Overrides methods of L<Data::Monad::Base::MonadZero>.

=item unit

=item flat_map

Overrides methods of L<Data::Monad::Base::Monad>.

=item @values = $list->values

Retrieves list of values from C<$list>

=item @single_values = $list->scalars

Retrieves values which was set by the C<scalar_list> method.

=back

=head1 AUTHOR

hiratara E<lt>hiratara {at} cpan.orgE<gt>

=head1 SEE ALSO

L<Data::Monad::Base::Monad>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

