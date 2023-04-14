
package Data::Ref::JSON;
use strict;
use Carp;
use warnings;
use diagnostics;
use Data::Dumper;
use Try::Tiny;

# 0 is 'disabled'
my $debugLevel=0;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.02';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw(&pdebug &setDebugLevel &walk);
    %EXPORT_TAGS = ();
}

my %walkType = (
	'HASH' => \&_walkHash,
	'ARRAY' => \&_walkArray,
);

sub _setDebugLevel {
	($debugLevel) = @_;
	return;
}

sub _getDebugLevel {
	return $debugLevel;
}

=head1 setDebugLevel

  For procedural use.

  Call as setDebugLevel($i);

  A value of 0 disables debugging output (default)

=cut

sub setDebugLevel {
	_setDebugLevel $_[0];
	return;
}

sub _walkArray {
	my ( $ar, $refStr) = @_;
	my ($package, $filename, $line, $subroutine) = caller(0);
	pdebug(1,"subroutine: " . $subroutine,"\n" );
	pdebug(1, "$subroutine: top dump array:\n" , Dumper($ar), "\n");
	foreach my $idx ( 0 .. $#${ar} ) {
		my $refType = ref $ar->[$idx];
		$refType = ref \$ar->[$idx] unless $refType;
		pdebug(1, "$subroutine: refType - $refType\n");
		if ( $refType eq 'SCALAR') {
			print "i:v, $idx:$ar->[$idx]\n";
			#print "refStr: $refStr" . q(->[). $idx . q(]) . "\n";
			print "refStr: $refStr" . q([). $idx . q(]) . "\n";
		} elsif ($refType eq 'ARRAY') {
			pdebug(1, "$subroutine nested array: ", Dumper($ar->[$idx]),"\n");
			pdebug(1, "$subroutine calling walk with 'ARRAY'\n","\n");
			_walk($ar->[$idx], $idx, $refStr . q([). $idx . q(]));
		} elsif ($refType eq 'HASH') {
			pdebug(1, "$subroutine calling walk with 'HASH'\n","\n");
			_walk($ar->[$idx], $idx, $refStr . q([). $idx . q(]));
		} else {
			croak "something broke in $subroutine\n";
		}
	}
}

sub _walkHash {
	my ( $hr, $refStr) = @_;

	my ($package, $filename, $line, $subroutine) = caller(0);
	pdebug(1,"subroutine: " . $subroutine,"\n" );
	pdebug(1, "$subroutine: top dump hash\n" , Dumper($hr), "\n");
	# using sort just to see results in the same order consistently when testing
	# could make use of 'sort' an option
	foreach my $key ( sort keys %{$hr}) {
		pdebug(1,"key: $key\n");
		my $keyRefType = ref $hr->{$key};
		if ( $keyRefType eq '' ) { $keyRefType = ref \$key }
		pdebug(1, "$subroutine: keyRefType - $keyRefType\n");

		pdebug(1,"key refType: $keyRefType\n");
		if ( $keyRefType eq 'SCALAR' ) {
			#print "k:v, '$key':'" . defined($hr->{$key}) ? $hr->{$key} : 'NULL' . "'\n";
			my $value = defined($hr->{$key}) ? $hr->{$key} : 'NULL';
			print "k:v, '$key':'$value'\n";
			print "refStr: $refStr" . q({'). $key . q('}) . "\n";
		} elsif ($keyRefType eq 'ARRAY') {
			pdebug(1, "$subroutine nested array: ", Dumper($hr->{$key}),"\n");
			pdebug(1, "$subroutine calling walk with 'ARRAY'\n","\n");
			_walk($hr->{$key}, $key, $refStr . q({'). $key . q('}));
		} elsif ($keyRefType eq 'HASH') {
			pdebug(1, "$subroutine nested hash ", Dumper($hr->{$key}),"\n");
			pdebug(1, "$subroutine calling walk with 'HASH'\n","\n");
			_walk($hr->{$key}, $key, $refStr . q({'). $key . q('}));
		} else {
			croak "something broke in $subroutine\n";
		}
	}

}

# key could be a hash key or an array index

sub _walk {
	
	my ($structRef, $key, $refStr) = @_;

	my ($package, $filename, $line, $subroutine) = caller(0);

	pdebug(1,"subroutine: " . $subroutine );

	my $refType =  ref $structRef;
	pdebug(1,"$subroutine refType: $refType\n");

	if ( ! defined $refStr ) {$refStr = 'VAR->'}

	pdebug(1,"$subroutine: ", Dumper ($structRef));

	# I believe this block is never executed
	if ( $refType eq '' ) { # check for scalar
		#no strict 'refs';
		my $t = $structRef;
		pdebug(2,'t: refType - ' , ref \$t, "\n");
		pdebug(2,'t: ', Dumper($t));
		warn "BLOCK HAS EXECUTED\n";
	}

	if ( $refType eq 'REF' ) {
		carp "Do not know how to handle type of 'REF'.\n";
		carp "Perhaps you have unncessarily referenced a variable with \?\n";
		croak "unsupported reference\n";
	} elsif ($refType eq '' ) { # check for scalar - leaf node
		croak "Something went wrong - refType is '$refType'\n";
	} else {
		$walkType{$refType}($structRef,$refStr);
	}
}

=head1 walk

 Walk the data structure and print the string required to access it

 This can be used as an object or a procedure

=cut

=head2 As Procedure

 use Data::Ref::JSON qw(walk);

 my %tc = (

     'HL01-01' => {
         'HL02-01' => [
             'element 0',
             'element 1',
             'element 2'
          ]
     },

     'HL01-02' => {
         'HL02-01' => {
             K4 => 'this is key 4',
             K5 => 'this is key 5',
             K6 => 'this is key 6'
         }
	  }

  );

 walk(\%tc);


=cut

=head2 As Object

 use Data::Ref::JSON;

 my %tc = (

     'HL01-01' => {
         'HL02-01' => [
             'element 0',
             'element 1',
             'element 2'
          ]
     },

     'HL01-02' => {
         'HL02-01' => {
             K4 => 'this is key 4',
             K5 => 'this is key 5',
             K6 => 'this is key 6'
         }
	  }

  );

 my $dr = Data::Ref::JSON->new (
   {
      DEBUG   => 0,
      DATA    => \%tc
   }
 );

 $dr->walk;


=cut

sub walk {

	if ( ref($_[0]) eq 'Data::Ref::JSON' ) {
		my $self = shift;
		_walk($self->{DATA});
	} else {
		my $data = shift;
		_walk($data);
	}

}

sub pdebug {
	my $dlvl = shift;
	print "\ndbg:", join("\ndbg: ",@_) if _getDebugLevel() and $dlvl <= _getDebugLevel();
}

=head1 new

 Given an arbitrary data structure, create a new object that can then be traversed by walk().

 walk() will print all values and the string used to access them

 Given the following structure:

  (

     'HL01-01' => {
         'HL02-01' => [
             'element 0',
             'element 1',
             'element 2'
          ]
     },

     'HL01-02' => {
         'HL02-01' => {
             K4 => 'this is key 4',
             K5 => 'this is key 5',
             K6 => 'this is key 6'
         }
	  }

  );


 This would be the output:

 i:v, 0:element 0
 refStr: VAR->{'HL01-01'}{'HL02-01'}[0]
 i:v, 1:element 1
 refStr: VAR->{'HL01-01'}{'HL02-01'}[1]
 i:v, 2:element 2
 refStr: VAR->{'HL01-01'}{'HL02-01'}[2]
 k:v, 'K4':'this is key 4'
 refStr: VAR->{'HL01-02'}{'HL02-01'}{'K4'}
 k:v, 'K5':'this is key 5'
 refStr: VAR->{'HL01-02'}{'HL02-01'}{'K5'}
 k:v, 'K6':'this is key 6'
 refStr: VAR->{'HL01-02'}{'HL02-01'}{'K6'}

 Where
   i = position in array
	k = hash key
	v = value
	refStr = the string used to access the value

=cut

#my %walkers = (
#'HASH' => 0,
#'ARRAY' => 1,
#);

sub new
{

	my $pkg = shift;
	my $class = ref($pkg) || $pkg;
	my $parms= shift;
	my $self = $parms;
	my $retval =  bless $self, $class;

	_setDebugLevel($parms->{DEBUG});

	croak "No Data Sent\n" unless $parms->{DATA};
	$parms->{WORKING_DATA} = $parms->{DATA};

	my ($package, $filename, $line, $subroutine) = caller(0);

	pdebug(1,"$subroutine parms", Dumper($parms));


	pdebug(1,"$subroutine - new self: ", Dumper($self));

	# may convert to this later
	#$self->{walkers}[$walkType{'HASH'}] = sub { $self->_walkHash(); };
	#$self->{walkers}[$walkType{'ARRAY'}] = sub { $self->_walkArray(); };

	return $retval;
}


=head1 NAME

 Data::Ref::JSON 

=head1 SYNOPSIS

  
 Walk a referenced arbitrary data structure and provide the reference to access values
 

=head1 DESCRIPTION


 When working with deeply nested complex data structures, it can be quite difficult to determine just what the key is for any value.

 Data::Ref::JSON will traverse the data, printing the values and the keys used to access them.
 

=head1 USAGE

  See the examples for walk()


=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    Jared Still
    CPAN ID: MODAUTHOR
    Pythian
    jkstill@gmail.com
    http://a.galaxy.far.far.away/modules

=head1 COPYRIGHT

This program is free software licensed under the...

	The MIT License

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

