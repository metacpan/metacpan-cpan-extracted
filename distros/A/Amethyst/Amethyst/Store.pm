package Amethyst::Store;

use strict;
use vars qw(@ISA @EXPORT);
use Carp;
use Exporter;
use MLDBM qw(DB_File Storable);
use Fcntl;
# use POE;
# use Amethyst;

@ISA = qw(Exporter);
@EXPORT = qw();

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	die "No source for store" unless $self->{Source};
	my %data;
	my $dbm = tie %data, 'MLDBM', $self->{Source}, O_CREAT|O_RDWR, 0640
					or die "tie: $self->{Source}: $!";
	$self->{Data} = \%data;
	return bless $self, $class;
}

sub get { return $_[0]->{Data}->{$_[1]}; }
sub set { $_[0]->{Data}->{$_[1]} = $_[2]; }
sub unset { delete $_[0]->{Data}->{$_[1]}; }
sub keys { return keys %{ $_[0]->{Data} }; }

1;
