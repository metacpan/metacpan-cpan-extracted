package Data::Enumerator::File;
use strict;
use warnings;
use IO::File;
use base qw/Data::Enumerator::Base/;

sub new {
    my ( $class, $file ) = @_;
    bless {
        file => $file,
    }, $class;
}

sub iterator {
    my ($self) = @_;
    my $file   = $self->{file};
    my $fh = IO::File->new;
    $fh->open( $file, 'r' );
    return sub {
        my $line = <$fh>;
        return $line if( defined $line );
        $fh->close;
        return $self->LAST;
    }
}
1;
