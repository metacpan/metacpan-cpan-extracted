package Data::Keys::E::Dir::Auto;

=head1 NAME

Data::Keys::E::Dir::Auto - auto create folder when needed

=head1 DESCRIPTION

When the key fails to do set a folder part from the key is extracted and when the
folder doesn't exist, it is created.

=cut

use warnings;
use strict;

our $VERSION = '0.04';

use Moose::Role;
use File::Basename 'dirname';
use Carp::Clan 'confess', 'croak';
use File::Path 'mkpath';

has 'auto_folders' => ( isa => 'Bool', is => 'rw', default => 1 );

requires('set');

around 'set' => sub {
	my $set   = shift;
	my $self  = shift;
	my $key   = shift;
	my $value = shift;
	
    # call set
    my $ret = eval { $self->$set($key, $value); };
	if ($@) {
	    my ($new_key, $filename) = $self->_make_filename($key);
        my $folder = dirname($filename);
        # check if we need to create a folder
        if (not -d $folder and $self->auto_folders) {
            mkpath($folder)
                or croak 'failed to store "'.$key.'", folder "'.$folder.'" could not be create - '.$!;
        }
		$ret = eval { $self->$set($key, $value); };
        croak $@
            if $@;
	}
    
    return $ret;
};

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
