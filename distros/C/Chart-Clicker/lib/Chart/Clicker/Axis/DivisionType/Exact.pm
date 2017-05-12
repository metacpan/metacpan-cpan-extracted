package Chart::Clicker::Axis::DivisionType::Exact;
$Chart::Clicker::Axis::DivisionType::Exact::VERSION = '2.90';
use Moose::Role;
with qw{Chart::Clicker::Axis::DivisionType};

sub best_tick_size {
    my ($self) = @_;

    return $self->range->span / ( $self->ticks - 1 );
}

sub _real_divvy {
    my ($self) = @_;

    my $per = $self->best_tick_size;

    my @vals;
    for ( 0 .. ( $self->ticks - 1 ) ) {
        push( @vals, $self->range->lower + ( $_ * $per ) );
    }

    return \@vals;
}

no Moose;
1;

__END__

=pod

=head1 NAME

Chart::Clicker::Axis::DivisionType::Exact

=head1 VERSION

version 2.90

=head1 SYNOPSIS

  use Chart::Clicker::Axis;

  my $axis = Chart::Clicker::Axis->new({
    tick_division_type  => 'Exact'
  });

=head1 DESCRIPTION

Role describing how to divide data for Chart::Clicker::Axis.

=head1 NAME

Chart::Clicker::Axis::DivisionType::Exact - Divide axis in exact increments, linear scale.

=head1 METHODS

=head2 best_tick_size

The tick division calculated by taking the range and dividing by the requested number of ticks.

=head2 divvy

Divides the range up into exact division for L<Chart::Clicker::Axis>.

=head1 AUTHOR

Rod Taylor <chartclicker@rbt.ca>

=head1 SEE ALSO

perl(1)

=head1 LICENSE

You can redistribute and/or modify this code under the same terms as Perl
itself.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
