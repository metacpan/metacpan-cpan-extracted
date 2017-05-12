package Business::BancaSella::Ric::File;

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

sub extract {
    my $self = shift;

    my $password;

    # open the file
    open(REQUEST,"+<$self->{'file'}")
        || die "SYSTEM. opening $self->{'file'} : $!\n";

    eval {

        # lock the file
        my $has_lock = eval { flock(REQUEST,2) };
        if ( $@ ) {
            warn "WARNING. this platform don't implements 'flock'\n";
        } elsif ( ! $has_lock ) {
            die "SYSTEM. locking $self->{'file'} : $!\n";
        }

        # length of a row of password
        my $row_length = 33;

        my $size_bytes;
        unless ( $size_bytes = (stat(REQUEST))[7] ) {
            die (( $! ) ? $! : "EMPTY : the file $self->{'file'} is empty\n" );
        }
        if ( $size_bytes % $row_length != 0 ) {
            die "CORRUPT. dimension of $self->{'file'} is wrong\n";
        }

        # number of passwords in the file
        my $size = $size_bytes / $row_length;

        # read the last password
        my $row;
        seek(REQUEST,($size-1)*$row_length,0)
            || die "SYSTEM. while seek in $self->{'file'} : $!\n";

        read(REQUEST,$row,$row_length) || die "SYSTEM. reading $self->{'file'} : $!\n";

        unless ( $row =~ /^([a-zA-Z0-9]{32})\n$/ ) {
            die "CORRUPT. file $self->{'file'} corrupted at last line\n";
        }
        $password = $1;

        # delete the last password
        my $is_truncate = eval { truncate(REQUEST,($size-1)*$row_length) };
        if ( $@ ) {
            die "SYSTEM. the 'truncate' function is not implemented on this platform!\n";
        }
        unless ( $is_truncate ) {
            die "SYSTEM. while truncate $self->{'file'} : $!\n";
        }

    }; # end eval
    my $error = $@;

    # close the file
    close(REQUEST);

    # die on error
    die $error if $error;

    # return the password
    return $password;
}

sub prepare {
    my ($self,$source_file) = @_;
    # don't do nothing :)
}

sub file { my $s=shift; return @_ ? ($s->{file}=shift) : $s->{file} }

1;
__END__