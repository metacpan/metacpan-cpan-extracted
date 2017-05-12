package Build::Util;
use strict;
use warnings;
use base qw( Exporter );
use Carp ();

our $VERSION   = '0.80';
our @EXPORT_OK = qw( slurp trim );

sub slurp {
    my $path = shift || Carp::croak( 'No file path specified' );
    if ( ! -e $path ) {
        Carp::croak( "The specified file path $path does not exist" );
    }
    open my $FH, '<', $path  or Carp::croak( "Can not open file($path): $!" );
    my $rv = do { local $/; <$FH> };
    close $FH or Carp::croak( "Can't close($path): $!" );
    return $rv;
}

sub trim {
    my($s, $extra) = @_;
    return $s if ! $s;
    $extra ||= q{};
    $s =~ s{\A \s+   }{$extra}xms;
    $s =~ s{   \s+ \z}{$extra}xms;
    return $s;
}

1;

__END__
