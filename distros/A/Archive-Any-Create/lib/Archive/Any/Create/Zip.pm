package Archive::Any::Create::Zip;
use strict;

use Archive::Zip qw(:ERROR_CODES);

sub init {
    my $self = shift;
    my($opt) = @_;
    $self->{zip}  = Archive::Zip->new;
}

sub container {
    my $self = shift;
    my($dir) = @_;
    $self->{container} = $dir;
    $self->{zip}->addDirectory("$dir/");
}

sub add_file {
    my $self = shift;
    my($file, $data) = @_;
    $file = "$self->{container}/$file" if $self->{container};
    $self->{zip}->addString($data, $file);
}

sub write_file {
    my $self = shift;
    my($file) = @_;
    my $err = $self->{zip}->writeToFileNamed($file);
    $err == AZ_OK
        or throw Archive::Any::Create::Error(error => "write_file failed ($err)");
    1;
}

sub write_filehandle {
    my $self = shift;
    my($fh)  = @_;
    my $err = $self->{zip}->writeToFileHandle($fh);
    $err == AZ_OK
        or throw Archive::Any::Create::Error(error => "write_filehandle failed ($err)");
    1;
}

1;
