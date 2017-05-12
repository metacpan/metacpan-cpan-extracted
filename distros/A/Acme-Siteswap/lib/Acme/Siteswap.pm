package Acme::Siteswap;
use strict;
use warnings;

use List::Util qw( max reduce );

=head1 NAME

Acme::Siteswap - Provide information about Juggling Siteswap patterns

=head1 SYNOPSIS

  use Acme::Siteswap;
  my $siteswap = Acme::Siteswap->new(
      pattern => '53142',
      balls => 3,
  );
  print "Awesome!\n" unless $siteswap->valid;

=cut

our $VERSION = '0.03';

=head1 FUNCTIONS

=head2 new

Create a new Acme::Siteswap object.

Options:

=over 4

=item pattern

Mandatory.  The siteswap pattern.  Should be a series of throws.

=item balls

Mandatory.  The number of balls in the pattern.

=back

=cut

sub new {
    my $class = shift;
    my $self = { @_ };
    die "A siteswap pattern is required!" unless defined $self->{pattern};
    die "The number of balls is required!" unless defined $self->{balls};
    bless $self, $class;
    return $self;
}

=head2 valid

Determines if the specified pattern is valid.

=cut

sub valid {
    my $self = shift;
    my $pattern = $self->{pattern};

    my @throws;
    eval { @throws = _pattern_to_throws($pattern) };
    if ($@) {
        $self->{error} = $@;
        return 0;
    }

    # Check that the numbers / throws == # of balls
    my $total = 0;
    for my $t (@throws) {
        if (ref $t eq 'ARRAY') {
            foreach my $m_t (@$t) {
                $total += $m_t;
            }
        }
        else {
            $total += $t;
        }
    }

    my $avg = $total / @throws;
    unless ($avg == $self->{balls}) {
        $self->{error} = "sum of throws / # of throws does not equal # of balls!";
        return 0;
    }
	
    return $self->_check_timing(@throws);
}

sub _check_timing {
    my ($self, @throws) = @_;
    
    # foreach non-zero throw, mark where the ball will next be
    # thrown and make sure that each throw is fed.
    my @throw_map = map { ref $_ eq 'ARRAY' ? scalar(@$_) 
                                            : ( $_ > 0 ? 1 : 0 ) } @throws;
    my @feeds = (0) x scalar @throws;
    for my $i (0 .. $#throws) {
        my @subthrows = ref $throws[$i] eq 'ARRAY' ? @{$throws[$i]} 
                                                   : ($throws[$i]);
        
        foreach my $throw (@subthrows) {
            next if $throws[$i] == 0;
            my $next_thrown = ($i + $throw) % scalar @throws;
            $feeds[$next_thrown]++;
        }
    }

    for my $i (0 .. $#throws) {
        if ($feeds[$i] != $throw_map[$i]) {
            $self->{error} = "Multiple throws would land at the same time.";
            return 0;
        }
    }
    return 1;
}

=head2 error

Returns an error message or empty string.

=cut

sub error { $_[0]->{error} || '' }

sub _pattern_to_throws {
    my $pattern = shift;

    my @throw_set = ();

    while ($pattern =~ m/
			# next block of non-multiplex throws
			(?: \G (\d+) ) 
			# or the next multiplex throw
			| (?: \G \[(\d+)\] )
			# or the end of the pattern
			| (?: \G \z )
			/xmg) {
        if ( defined $1 ) {
            push (@throw_set,  split (//, $1));
        }
        elsif ( defined $2 ) {
            push (@throw_set, [ split(//, $2) ]);
        }
        else {
            # if we never get here, the pattern had an issue
            return @throw_set;
        }
    }
		
    die "unable to parse pattern: $pattern";
}

sub _max_throw {
    my ($throws) = @_;

    my $max_throw = reduce { 
        my $a_1 = ( ref $a eq 'ARRAY' ? max(@$a) : $a );
        my $b_1 = ( ref $b eq 'ARRAY' ? max(@$b) : $b );
        $a_1 >= $b_1 ? $a_1 : $b_1;
    } @$throws;

    # if our pattern is a 1-length multiplex pattern, 
    # reduce returns the first element, so correct for
    # that here
    $max_throw = max(@$max_throw) if ref $max_throw eq 'ARRAY';

    return $max_throw;
}

# extend the pattern by the number of throws equal to the biggest
# throw in the pattern, to ensure that every throw in the pattern
# lands at least once.
sub _expand_throws {
    my ($throws) = @_;
    my $max_throw = _max_throw($throws);
	
    foreach my $i (0 .. $max_throw) {
        # if it's a multiplex throw, we want to copy it
        my $t = ref $throws->[$i] eq 'ARRAY' ? [@{$throws->[$i]}] 
                                             : $throws->[$i];
        push @$throws, $t; 
    }
    return $throws;
}

=head1 AUTHORS

Luke Closs, C<< <cpan at 5thplane dut com> >>
Multiplex support by Seamus Campbell, C<< <conform at deadgeek rot com >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-siteswap at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Siteswap>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT

Copyright 2007 Luke Closs, all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
