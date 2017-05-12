package Data::Keys::E::Store::Dir;

=head1 NAME

Data::Keys::E::Store::Dir - folder storage

=head1 SYNOPSIS

	my $dk = Data::Keys->new(
		'base_dir'    => '/some/folder',
		'extend_with' => 'Store::Dir',
    );

=head1 DESCRIPTION

Store values into a folder. Keys are the file names.

=head1 METHODS

=cut

use warnings;
use strict;

our $VERSION = '0.04';

use Moose::Role;

has 'base_dir' => ( isa => 'Str', is => 'rw',);

after 'init' => sub {
    my $self  = shift;

    confess 'base_dir is a mandatory argument'
        if not $self->base_dir;
    confess $self->base_dir.' is not a writable folder'
        if (not -d $self->base_dir) or (not -w $self->base_dir);
    
    return;
};

=head2 get($filename)

Reads C<$filename> and returns its content.

=cut

sub get {
    my $self = shift;
    my $key  = shift;
    confess 'too many arguments ' if @_;
    
    my $filename = $self->_make_filename($key);
    return eval { IO::Any->slurp([$filename]) };
}

=head2 set($filename, $content)

Writes C<$content> into the C<$filename>. Returns C<$filename>.

=cut

sub set {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;
    confess 'too many arguments ' if @_;

    my ($new_key, $filename) = $self->_make_filename($key);

    # if value is undef, remove the file
    if (not defined $value) {
        unlink($filename) || (not -f $filename) || warn 'failed to remove "'.$filename.'"';
        return $new_key;
    }

    eval { IO::Any->spew([$filename], $value, { 'atomic' => 1 }); };
    confess 'failed to store "'.$key.'" - '.$@
        if $@;
    
    return $new_key;
}

sub _make_filename {
    my $self = shift;
    my $key  = shift;
    confess 'need key (with length > 0) as argument'
        if ((not defined $key) or (length($key) == 0));
    confess 'too many arguments ' if @_;
    
    my $filename = File::Spec->catfile(
        $self->base_dir,
        $key
    );
    
    return ($key, $filename)
        if wantarray;
    return $filename;
}

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
