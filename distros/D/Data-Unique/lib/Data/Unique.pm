package Data::Unique;

use 5.006;
use strict;
use warnings;
use Storable::AMF0 qw();



=head1 NAME

Data::Unique - Module to check for duplicate item with time expiration and disk persistence.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Create a data structure that avoid duplicate entries (key) whith any data and add expiration time to clean old entries.
This module use  Storable::AMF0 for the persistence.
After some benchmark of various serialisation it is best compromise in read and write for huge quantity of data.

e.g.


        #!/usr/bin/perl
	  
	use strict;
	use warnings;
	use Data::Dumper;
	use feature qw( say );
	use Time::HiRes qw(gettimeofday usleep );
	
	use Data::Unique;
	
	
	
	my $filename = '/tmp/dedup.test';
	my @dup;
	my $dedup = Data::Unique->new( { expiration => 10, file => $filename, gc => 5 } );
	
	for my $idx ( 1 .. 6 ) {
	    my ( $seconds, $microseconds ) = gettimeofday;
	    my $time = ( $seconds * 1000000 ) + $microseconds;
	    say "$idx -> $time";
	    $dedup->item( $time, { T => $idx } ) or say "no insertion ($$time already present)";
	    push @dup, $time if ( ( $idx % 2 ) == 0 );
	    usleep 10;
	}
	say Data::Dumper::Dumper $dedup;
	say "Number of item=".$dedup->scalar;
	
	say "Expiration time ".$dedup->expiration;
	say "Number of item=".$dedup->scalar;
	
	say $dedup->expiration(6);
	sleep 15;
	
	#say "deleted item number=".$dedup->gc();
	say "Number of item=".$dedup->scalar;
	
	foreach my $ins (@dup) {
	   say  $dedup->item($ins, { T => time }) ? "inserting $ins" : "no insertion ($ins already present)";
	}
	
	say "Expiration time ".$dedup->expiration;
	say "Number of item=".$dedup->scalar. '  =>  '.scalar( keys( %{ $dedup->{data} }));




=head1 SUBROUTINES/METHODS

=head2 new

Create a new Data::Unique object.
It is possible to set the default values as parameters

    my $dedup = Data::Unique->new( 
                                {
                                  expiration => 60,  # the retention time. When reached the expiration time, the item is removed
                                  file => $filename, # the file used for the retention
                                  gc => 5            # the number of operation between garbage colletor (checking the expiration time)
                                }
                             );
                             


=cut

sub new {
    my ($class, $params) = @_;
    my %data ;
    if (-f $_[1]->{file}) {
        eval { %data = %{ Storable::AMF0::retrieve($_[1]->{file}) }; }
    }
    $data{expiration} = $params->{expiration} if $params->{expiration};
    $data{file}       = $params->{file} if $params->{file} ;
    $data{iter}       ||= 0;
    $data{gc}         = $params->{gc} if $params->{gc} ;
    bless {%data}, $class;
}

=head2 item

Add item and return 1 if succeed or return 0 if the item is already present;
The key to test for unicity is the first parameter
The second parameter is the data.

    $dedup->item( $time, $data );

If no data is provided, only test is the item is present.

    $dedup->item( $time );

=cut

sub item {
    my ($self, $key, $data) = @_;
    $self->{iter}++;
    if ($self->{expiration} > 0 && $self->{iter} >= $self->{gc}) {
        $self->gc();
        $self->{iter} = 0;
    }
    if (exists $self->{data}{$key}) {
        return 0;
    }
    else {
        if (ref $data eq '') {
            $self->{data}{$key} = { val => "$data", time => time() };
        }
        else {
            $self->{data}{$key} = { val => $data, time => time() };
        }
        return 1;
    }
}

=head2 expiration

Check or modify the expiration time (if a parameter is provided)
If the expiration is modified, the garbage colletor run.

    $dedup->expiration(6);     # set the new expiration to 6 seconds
    $exp = $dedup->expiration; # return the current expiration time

=cut

sub expiration {
    my ($self, $exp) = @_;
    if ($exp) {
        $self->{expiration} = $exp;
        $self->gc();
    }
    return $self->{expiration};
}

=head2 scalar

Return the number of item

    $nbr = $dedup->scalar;

A convenient way to do:

    scalar keys scalar keys %{ $self->{data} };

=cut

sub scalar {
    my ($self) = @_;
    return scalar keys %{ $self->{data} };
}

=head2 gc

Run the garbage collector to remove the expired item or modify the gc value if a paramter is provided.
When the garbage collector is run, a sync to disk is executed.
The garbage collector run each time the number item() action is reaching the value of the parameter gc
If the value is 0, no automatic garbage collector is run.
If the value  < 0, this value is used as a expiration time when manually running the garbage collector.

    $dedup->gc();   # force the garbage collector to run;
    $dedup->gc(10); # change the gc value;

=cut

sub gc {
    my ($self, $gc) = @_;
    my $nbr = 0;
    if ($gc && $gc > 0) {
        $self->{gc} = $gc;
    } elsif ($gc && $gc < 0) {
        my $now = time + $gc;
        foreach my $k (keys %{ $self->{data} }) {
            if ($self->{data}{$k}{time} <= $now) {
                delete $self->{data}{$k};
                $nbr++;
            }
        }
        $self->sync;        
    
    } elsif ($self->{gc} > 0 && $self->{expiration} > 0) {
        my $now = time - $self->{expiration};
        foreach my $k (keys %{ $self->{data} }) {
            if ($self->{data}{$k}{time} <= $now) {
                delete $self->{data}{$k};
                $nbr++;
            }
        }
        $self->sync;
    }
    return $nbr;
}

=head2 sync

Write the data on disk.
The sync is always done when the gc() run.
It is possible to run it (if the gc occurence is too high)

    $dedup->sync();

=cut

sub sync {
    my ($self) = @_;
    my $val = Storable::AMF0::store($self, $self->{file});
}

sub DESTROY {
    my ($self) = @_;
    $self->sync;
}

=head1 AUTHOR

DULAUNOY Fabrice, C<< <fabrice at dulaunoy.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-unique at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Unique>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TODO

add more test
add a delete method
maybe TIE support

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Unique


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Unique>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Unique>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Data-Unique>

=item * Search CPAN

L<https://metacpan.org/release/Data-Unique>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by DULAUNOY Fabrice.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Data::Unique
