package Data::All::IO::FTP;

#   $Id: FTP.pm,v 1.1.1.1 2005/05/10 23:56:20 dmandelbaum Exp $


use strict;
use warnings;

use Data::All::IO::Plain '-base';
use Net::FTP::Common;
use File::Temp;
use IO::All;

our $VERSION = 0.11;

internal 'FTP';
internal 'fp';
internal 'ft_conf'  =>
{
    TEMPLATE    => "/tmp/data-all-$Data::All::VERSION-XXXXX",
    SUFFIX      => '.tmp'    
};



sub open($)
{
    my $self = shift;
    my $filepath;
    
    #warn " -> Opening ftp connection ", $self->ioconf()->{'perm'};
    
    #   Download and open a filehandle to files for reading.
    #   Create a temporary FH for writes.
    $filepath = ($self->ioconf->{'perm'} eq 'w')
        ? $self->_create_temp_filepath()
        : $self->_get_file();
    
    my $fh = FileHandle->new($filepath, $self->ioconf()->{'perm'}); 
    my $IO = $fh;
    
    
    $self->__IO( $IO );
    $self->__fh( $fh );
    $self->__fp( $filepath );
    
    $self->is_open(1);
    
    $self->_extract_fields();             #   Initialize field names 
    return $self->is_open();
}

sub close()
{
    my $self = shift;
    $self->__IO()->close();
    $self->is_open(0);
    
    $self->_put_file() if ($self->ioconf->{'perm'} eq 'w');
    
    #warn    "Deleting temp file: ", $self->__fp(); 
    unlink $self->__fp();
}

sub _create_temp_file()
#   Create a temporary file and open it
{
    my $self = shift;
    
    my $fh = File::Temp->new(%{ $self->__ft_conf() });    

    #warn "created temp file ". $fh->filename;
    
    return $fh;
}

sub _create_temp_filepath()
#   Create a temporary filename without creating the file
{
    my $self = shift;
    return mktemp($self->__ft_conf()->{'TEMPLATE'});   
}

sub _split_path_from_file()
#    IN: /some/file/path.txt
#   OUT: (/some/file, path.txt);
{
    my $self = shift;
    my $filepath = shift;
    my @elements = split('/', $filepath);
    my ($file, $path) = (pop(@elements), join('/', @elements));
    #warn "\n\nf:$file,p:$path";
    return ($path, $file);
}

sub _get_file()
#   Get a file via FTP and save it to a temporary file for reading
{
    my $self = shift;
    my $filepath_tmp = $self->_create_temp_filepath();
    my ($lpath, $lfile) = $self->_split_path_from_file($filepath_tmp);
    my ($rpath, $rfile) = $self->_split_path_from_file($self->path()->[0]);
    
    #   NOTE: The first param is sent by reference. See Net::FTP::Common docs
    #   for a not so valid explanation.
    my $ftp = Net::FTP::Common->new($self->path()->[1], %{ $self->path()->[2] }); 
    
    $ftp->get(
        RemoteDir   => $rpath, 
        RemoteFile  => $rfile,
        LocalDir    => $lpath,
        LocalFile   => $lfile
    );
        
    undef $ftp;
    
    return $filepath_tmp;     
}

sub _put_file()
{
    my $self = shift;
    my $filepath_tmp = $self->__fp();
    my ($lpath, $lfile) = $self->_split_path_from_file($filepath_tmp);
    my ($rpath, $rfile) = $self->_split_path_from_file($self->path()->[0]);
    
   #   NOTE: The first param is sent by reference. See Net::FTP::Common docs
    #   for a not so valid explanation.
    my $ftp = Net::FTP::Common->new($self->path()->[1], %{ $self->path()->[2] }); 
    
    #   "Don't use put!" according to perldoc Net::FTP::Common
    $ftp->send(
        RemoteDir   => $rpath, 
        RemoteFile  => $rfile,
        LocalDir    => $lpath,
        LocalFile   => $lfile
    );
        
    undef $ftp;
}


1;