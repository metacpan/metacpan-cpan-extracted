package t::Test;

use strict;
use warnings;

use t::Test;
use File::Temp qw/ tempfile /;
use DBIx::NoSQL;
use Path::Class;
use JSON; our $json = JSON->new->pretty;
use Scalar::Util qw/ blessed /;

sub tmp_sqlite {
    return file( File::Temp->new->filename );
}

sub test_sqlite {
    shift;
    my %options = @_;
    my $file = file 'test.sqlite';
    $file->remove if $options{ remove };
    return $file;
}

sub log {
    my $self = shift;
    warn ( join ' ', map { blessed $_ || ! ref $_ ? $_ : $json->encode( $_ ) } @_ ) . "\n";
}

sub now {
    return DateTime->now;
}

1;
