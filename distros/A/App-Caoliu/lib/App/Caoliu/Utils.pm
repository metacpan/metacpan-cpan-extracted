package App::Caoliu::Utils;

# ABSTACT: utility function for app caoliu
use Mojo::Base 'Exporter';
use YAML 'Dump';
use Cwd qw(abs_path);
use File::Basename;

our @EXPORT_OK = ( qw(abs_file trim get_video_size dumper) );
sub trim{
    my ($string) = @_;
    $string =~ s/^\s+//g;
    $string =~s /\s+$//g;
    
    return $string;
}
sub get_video_size{
    my ($video_format) = @_;
    my $size;

    if($video_format=~ m/([\d\.]+)\s*G|GB/ ){
        $size = ($1*1024).'M';
    }else{
        $size = trim($video_format);
    }
    return $size;
}

sub dumper{
    my $ref = shift;
    return $ref unless ref $ref;
    return Dump($ref);
}

sub abs_file{
    return abs_path(shift);
}

1;


