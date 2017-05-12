package BSON::Stream;

use strict;
use warnings;

use BSON qw/decode/;
use Carp;

our $VERSION = '0.01';

=head1 NAME

BSON::Stream - Read BSON data from stream (file).

=head1 SYNOPSIS
  use BSON::Stream;
  
  my $file = shift @ARGV or die("Pleas specify a file to read!");
  
  open(my $INF,$file) or die("Can not open file '$file':$!");
  
  my $bsonstream = BSON::Stream->new($INF);
  
  while (my $res = $bsonstream->get) {
  
    printf("%s own %s apples\n",$res->{'name'}, $res->{'apples'});

  }
  
  close($INF);
	
=head1 DESCRIPTION

BSON::Stream allows you to read one and one BSON record from a file and get it back as a Perl structure.

=head2 Reading from STDIN

  use BSON::Stream;
  
  my $bsonstream = BSON::Stream->new(*STDIN);
  
  while (my $res = $bsonstream->get) {
  
    printf("%s own %s apples\n",$res->{'name'}, $res->{'apples'});
  
  }

BSON files can quickly become very large. One common way of dealing with this is to compress them using gzip, then use zcat to uncompressed and pipe the raw BSON data into a program on the fly.

  zcat eg/testdata/users.bson.gz | perl eg/synopsis-STDIN.pl

=cut


sub new {
	my $class = shift;

	my $self = {};  
	bless( $self, $class );
	
	$self->{'stream'} = shift;
	
	# Defaults to STDIN
	if (!$self->{'stream'}) {
		$self->{'stream'} = *STDIN;
	}
	
	# We need to set the strem to be binery so Windows (and maby others) do not tranlate \n
	binmode($self->{'stream'});
	
	return $self;
}


sub get {
	my ($self) = @_;
	
	while (1) {
		my $sizebits;
		my $n;
		my $bson;
		my $res;
		
		$n = read($self->{'stream'}, $sizebits, 4);
		if ($n != 4) {
			$self->readerror($n);
			return undef;
		}
		
		my $size = unpack("i", $sizebits);

		$size -= 4;# -4 becase the size includes itself
		
		
		$n = read($self->{'stream'}, $bson, $size); 
		if ($n != $size) {
			$self->readerror($n);
			return undef;
		}
		
		$bson = $sizebits . $bson;
		
		my $seperator = substr($bson, -1,1);

		if ($seperator ne "\x00") {
			carp("Bad record seperator '$seperator'");
			return undef;
		}

		eval {
			$res = decode( $bson );
		};
		# If we can not decode we will just skipp. Having some bad records we 
		#can not decode are unfortantly not unkommon in large datasets.
		if ($@) {
			carp $@;
			next;
		}

		
		return $res;
	
	}
	
}

sub readerror {
	my ($self, $n) = @_;
	
	if ($n == 0) {
		# End of file
	}
	elsif (!defined($n)) {
		carp("Can not read from stream: $!");
	}
	else {
		carp("Unknown error. Was not able to read all bytes.");
	}
}

=head1 EXAMPLES

Please see the C<eg/> directory for further examples.

=head1 SEE ALSO

F<BSON>

=head1 AUTHOR

    Runar Buvik
    CPAN ID: RUNARB
    runarb@gmail.com
    http://www.runarb.com

=head1 Git

https://github.com/runarbu/PerlBSONStream

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=cut

1;
