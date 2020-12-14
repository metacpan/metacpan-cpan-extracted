package Helpers;

use Exporter 'import';
our @EXPORT = qw{get_db_file_pair};

use File::Temp;

sub get_db_file_pair {
    my $auto_close_del = shift;

    my $file = File::Temp->new( UNLINK => 1 );
    my $tmp  = File::Temp->new( UNLINK => 1 );

    if ($auto_close_del) {
        close $file;
        close $tmp;
        unlink $file->filename;
        unlink $file->filename;
    }

    return ( $file, $tmp );
}

1;
