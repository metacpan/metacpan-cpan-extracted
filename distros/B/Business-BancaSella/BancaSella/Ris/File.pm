package Business::BancaSella::Ris::File;


$VERSION = "0.11";
sub Version { $VERSION; }
require 5.004;
use strict;
use warnings;
use Carp;

my %fields 	=
    (
     file		=>		undef,
     );
     
my @fields_req	= qw/file/;
								

sub new
{   
	my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self,$class;
    $self->init(@_);
    return $self;
}							

sub init {
	my $self = shift;
	my (%options) = @_;
	# Assign default options
	while (my ($key,$value) = each(%fields)) {
		$self->{$key} = $self->{$key} || $value;
    }
    # Assign options
    while (my ($key,$value) = each(%options)) {
    	$self->{$key} = $value
    }
    # Check required params
    foreach (@fields_req) {
		croak "You must declare '$_' in " . ref($self) . "::new"
				if (!defined $self->{$_});
	}
}

sub check {
	my $self = shift;
	my $ris = shift;
	open(F,$self->{file}) || die "Unable to open " . $self->file;
	while (<F>) {
		chomp;
		if ($_ eq $ris) {
			close(F);
			return 1;
		}
	}
#	my @hris =  <F>;
	close(F);
	return 0;
#	chomp(@hris);
#	my %hris = map { $_ => 1} @hris;
#	return exists($hris{$ris});
}

sub remove {
	my $self = shift;
	my $ris = shift;
	open(F,$self->{file}) || die "Unable to open " . $self->file;
	my @hris =  <F>;
	close(F);
	chomp(@hris);
	my %hris = map { $_ => 1} @hris;
	if (exists($hris{$ris})) {
		delete $hris{$ris};
	} else {
		die "Unable to find $ris in " . $self->file;
	}
	@hris = map {$_ . "\n"} keys(%hris);
	open(F,">$self->{file}") || die "Unable to open " . $self->file;
	# lock the file
    my $has_lock = eval { flock(F,2) };
    if ( $@ ) {
        #warn "WARNING. this platform don't implements 'flock'\n";
    } elsif ( ! $has_lock ) {
        close(F);
        croak "SYSTEM. locking $self->{'file'} : $!\n";
    }
	print F @hris;
	close(F)
}

sub extract {
	# check password and remove it
	# return true if find it
    my ($self,$password,$only_test) = @_;
    return 0 if (!$self->check($password));
    $self->remove($password);
}

sub prepare {
    my ($self,$source_file) = @_;
    # don't do nothing :)
}


sub file { my $s=shift; return @_ ? ($s->{file}=shift) : $s->{file} }

1;
__END__
