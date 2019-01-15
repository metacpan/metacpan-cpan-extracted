package Beam::Runner::Steps;
our $VERSION = '0.015';
# ABSTRACT: Run a series of steps

#pod =head1 SYNOPSIS
#pod
#pod     beam run <container> <service>
#pod
#pod =head1 DESCRIPTION
#pod
#pod This runnable module runs a series of other runnable modules in
#pod sequence. If any module returns a non-zero value, the steps stop.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<beam>, L<Beam::Runnable>
#pod
#pod =cut

use Moo;
use warnings;
with 'Beam::Runnable';
use Types::Standard qw( ArrayRef ConsumerOf );

#pod =attr steps
#pod
#pod The steps to run. Must be an arrayref of L<Beam::Runnable> objects.
#pod
#pod =cut

has steps => (
    is => 'ro',
    isa => ArrayRef[ConsumerOf['Beam::Runnable']],
    required => 1,
);

sub run {
    my ( $self, @args ) = @_;
    for my $step ( @{ $self->steps } ) {
        my $exit = $step->run( @args );
        return $exit if $exit != 0;
    }
    return 0;
}

1;

__END__

=pod

=head1 NAME

Beam::Runner::Steps - Run a series of steps

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    beam run <container> <service>

=head1 DESCRIPTION

This runnable module runs a series of other runnable modules in
sequence. If any module returns a non-zero value, the steps stop.

=head1 ATTRIBUTES

=head2 steps

The steps to run. Must be an arrayref of L<Beam::Runnable> objects.

=head1 SEE ALSO

L<beam>, L<Beam::Runnable>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
