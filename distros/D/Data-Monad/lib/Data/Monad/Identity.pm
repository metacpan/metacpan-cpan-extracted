package Data::Monad::Identity;
use strict;
use base;
use parent qw/Data::Monad::Base::Monad/;

sub new {
    my $class = shift;
    bless [@_], $class;
}

sub unit {
    my $class = shift;
    $class->new(@_);
}

sub flat_map {
    my ($m, $f) = @_;
    $f->($m->value);
}

sub value { wantarray ? @{$_[0]} : $_[0][0] }

1;

__END__

=head1 NAME

Data::Monad::Identity - The identity monad.

=head1 SYNOPSIS

  use Data::Monad::Identity;

  my $m = Data::Monad::Identity->new(3, 5)->map(sub { $_[0] + $_[1] });
  print $m->value, "\n";  # 8

=head1 DESCRIPTION

Data::Monad::Identity doesn't nothing. It just wraps values.

=head1 METHODS

=over 4

=item $m = Data::Monad::Identity->new(@v);

Makes the new value which represents @v.

=item unit

=item flat_map

Overrides methods of Data::Monad::Base::Monad.

=item @v = $m->value;

Retrieves wrapped values from this object.

=back

=head1 AUTHOR

hiratara E<lt>hiratara {at} cpan.orgE<gt>

=head1 SEE ALSO

L<Data::Monad::Base::Monad>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

