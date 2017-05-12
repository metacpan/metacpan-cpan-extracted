package ChainMake::Parallel;

use strict;
use Data::Dumper;
use threads;
use base 'ChainMake';

our $VERSION = $ChainMake::VERSION;

$ChainMake::TARGETTYPE_PARAMS{parallel} = sub { (shift >= 0) };

sub _check_requirements {
    # Alle Requirements checken (d.h. make darauf ausführen),
    # ob eines der Requirements jünger als unser ältestes timestamps-File ($oldest) ist.
    my ($self,$req,$insistent,$parallel)=@_;
    return $self->SUPER::_check_requirements($req,$insistent) unless ($parallel);
    my ($youngest,$cannot);
    print "Parallel mode - output will be scrambled!\n";
    my @threads;
    $parallel=scalar @$req if ($parallel > scalar @$req);
    for my $tnum (0..($parallel-1)) {
        my $num_per_thread=int((scalar @$req)/($parallel-$tnum));
        my @thrd_req=splice @$req,0,$num_per_thread;
        $threads[$tnum]=threads->create(sub {
#           print "Ich bin Thread ".threads->self->tid(), " und stelle folgendes her: ", join(", ",@thrd_req),"\n";
            $self->SUPER::_check_requirements(\@thrd_req,$insistent)
        });
    }
    for my $thrd (@threads) {
        my ($youngest_req,$cant,$cant_name)=$thrd->join();
        if ($youngest_req) {
            $youngest=$youngest_req if (!($youngest) || ($youngest_req > $youngest));
        }
        else {
            $cannot=1;
        }
    }
    return ($cannot ? 0 : $youngest);
}

1;

__END__

=head1 NAME

ChainMake::Parallel - Check requirements in parallel

=head1 SYNOPSIS

=head1 DESCRIPTION

This module works just like the L<ChainMake> module and may be used as a drop-in replacement.

The only difference is that this module adds an additional parameter to the L<ChainMake/targets> method: parameter C<parallel>.

=head1 parallel

  %description = (
      parallel    => 5,
  );

The C<parallel> field defines whether or not requirements should be
checked in parallel. A non-zero number will be used as the number of parallel threads.

Currently experimental and only available if perl has been compiled with ithreads.

=head1 CAVEATS/BUGS

=head1 SEE ALSO

=over

=item L<ChainMake>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id: Parallel.pm 1231 2009-03-15 21:23:32Z schroeer $.

Copyright 2008-2009 Daniel Schröer (L<schroeer@cpan.org>). Any feedback is appreciated.

This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=cut  
