package Bloom::Faster;

use 5.008005;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Bloom ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	HASHCNT
	SET
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	HASHCNT
	SET
);


sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Bloom::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}


our $VERSION = '1.7';


require XSLoader;
XSLoader::load('Bloom::Faster', $VERSION);


sub new {
    my ($package,$data)  = @_;
    my %struct;
    if (! (ref $data)) {
	$struct{vector} = bdeserialize($data);
    } else {
	if (defined($data->{e}) && defined($data->{n})) {
	    $struct{vector} = binit_sugg($data->{n},$data->{e});
	} elsif (defined($data->{m}) && defined($data->{k})) {
			$data->{n} = $data->{e} = 0;
	    $struct{vector} = binit($data->{m},$data->{k},$data->{n},$data->{e});
	} else {
	    $! = "invalid arguments to Bloom::Faster";
	    return undef;
	}
	
	if (!defined($struct{vector})) {
	    $! = "bloom init failure\n";
	    return undef;
	}
    }
    # binit will implicitly set m to a close prime
    ###$struct{inserts} = 0;
    
    bless \%struct => $package;
}

sub from_file {
    my ($self, $filename) = @_;
    bloom_destroyer($self->{vector});
    $self->{vector} = bdeserialize($filename);
}

sub to_file {
    my ($self, $filename) = @_;
    return bserialize($self->{vector}, $filename);

}

sub vector {
    my ($self) = @_;	
    
    return get_vector($self->{vector});
}

sub get_suggestion {
    my ($n,$e) = @_;
    
    my ($m,$k);
    $m = $k = 0;
    
    suggestion($n,$e,$m,$k);
    
    return ($m,$k);
}

sub DESTROY {
    my ($self) = @_;
    defined($self->{vector}) and bloom_destroyer($self->{vector});
}

sub get_inserts {
    my ($self) = @_;
    ##return $self->{inserts};
    return binserts($self->{vector});
}

sub key_count {
    my ($self) = @_;
    return $self->get_inserts();
}

sub capacity {
    my ($self) = @_;
    return bcapacity($self->{vector});
}

sub get_vectorsize {
    my ($self) = @_;
    return belements($self->{vector});
}

sub test {
    my ($self,$str) = @_;
    
    return $self->add($str);
}

sub check {
    my ($self,$str) = @_;
    
    ##$self->{inserts}++;
    return test_bloom($self->{vector},$str,0);
}

sub add {
    my ($self,$str) = @_;
    
    ##$self->{inserts}++;
    return test_bloom($self->{vector},$str,1);
}



# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Bloom::Faster - Perl extension for the c library libbloom.

=head1 INSTALLATION

see INSTALL

=head1 SYNOPSIS

  use Bloom::Faster;
  
  # m = ideal vector size.  
  # k = # of hash functions to use. 

  my $bloom = new Bloom::Faster({m => 1000000,k => 5});

  # this gives us very tight control of memory usage (a function of m)
  # and performance (a function of k).  but in most applications, we won't
  # know the optimal values of either of these.  for these cases, it is 
  # much easier to supply:
  #
  # n = number of expected elements to check for duplicates,
  # e = acceptable error rate (probability of false positive)
  #
  # my $bloom = new Bloom::Faster({n => 1000000, e => 0.00001});

  while (<>) {
	chomp;
	# Bloom::Faster->add() returns true when the value is a duplicate.
	if ($bloom->add($_)) {
		print "DUP: $_\n";
	}
  }

  if ($bloom->check("foo")) {
    print " foo has been seen ";
  }

  # for annoying backwards-compatibility reasons, we also provide a "test" method. 
  # this method is EQUIVALENT to the add() method and should not be used since it's
  # extremely confusing.  This method is now deprecated.


  # serialize to disk
  $bloom->to_file("/path/to/file");

  # read from disk
  my $another_bloom = new Bloom::Faster("/path/to/another/file");

  # manually free the data structures 
  $bloom->DESTROY;
 

=head1 DESCRIPTION

Bloom filters are a lightweight duplicate detection algorithm proposed by Burton Bloom (http://portal.acm.org/citation.cfm?id=362692&dl=ACM&coll=portal), with applications in stream data processing, among others.  Bloom filters are a very cool thing.  Where occasional false positives are acceptable, bloom filters give us the ability to detect duplicates in a fast and resource-friendly manner.

The allocation of memory for the bit vector is handled in the c layer, but perl's oo capability handles the garbage collection.  when a Bloom::Faster object goes out of scope, the vector pointed to by the c structure will be free()d.  to manually do this, the DESTROY builtin method can be called.

A bloom filter perl module is currently avaible on CPAN, but it is slow and cannot handle large vectors.  This alternative uses a more efficient c library which can handle very large vectors.
=head2 EXPORT

None by default.

=head2 Exportable constants

  HASHCNT
  PRIME_SIZ
  SIZ



=head1 SEE ALSO

libbbloom.so 


=head1 AUTHOR

Peter Alvaro and Dmitriy Ryaboy, E<lt>palvaro@cpan.orgE<gt> E<lt>dvryaboy@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2009 by Peter Alvaro and Dmitriy Ryaboy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
