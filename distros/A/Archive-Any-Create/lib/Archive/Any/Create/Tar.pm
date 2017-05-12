package Archive::Any::Create::Tar;
use strict;

use Archive::Tar;

sub init {
    my $self = shift;
    my($opt) = @_;
    $self->{tar}  = Archive::Tar->new;
    $self->{comp} = $opt->{comp};
}

sub container {
    my $self = shift;
    my($dir) = @_;
    $self->{container} = $dir;
}

sub add_file {
    my $self = shift;
    my($file, $data) = @_;
    $self->{tar}->add_data($file, $data);
}

sub write_file {
    my $self = shift;
    return $self->write_filehandle(@_); # Accepts files or handles
}

sub write_filehandle {
    my $self = shift;
    my($fh)  = @_;
    my $comp = $self->{comp} ? COMPRESS_GZIP : undef;
    $self->{tar}->write($fh, $comp, $self->{container})
        or throw Archive::Any::Create::Error(error => $self->{tar}->error);
    1;
}

1;
