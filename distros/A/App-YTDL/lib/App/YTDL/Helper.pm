package # hide from PAUSE
App::YTDL::Helper;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( sec_to_time write_json read_json uni_capture uni_system HIDE_CURSOR SHOW_CURSOR );

use Fcntl qw( LOCK_EX LOCK_SH SEEK_END );

use IPC::System::Simple qw( capturex systemx EXIT_ANY );
use JSON                qw();

use constant {
    HIDE_CURSOR => "\e[?25l",
    SHOW_CURSOR => "\e[?25h",
};


sub uni_capture {
    my ( @cmd ) = @_;
    if ( wantarray ) {
        my @capture = capturex( @cmd );
        return @capture;
    }
    else {
        my $capture = capturex( @cmd );
        return $capture;
    }
}


sub uni_system {
    my ( @cmd ) = @_;
    my $exit_value = systemx( EXIT_ANY, @cmd );
    return $exit_value;
}


sub sec_to_time {
    my ( $seconds, $long ) = @_;
    die 'seconds: not defined'                         if ! defined $seconds;
    die 'seconds: "' . $seconds . '" invalid datatype' if $seconds !~ /^[0-9]+\z/;
    my ( $minutes, $hours );
    if ( $seconds ) {
        $minutes = int( $seconds / 60 );
        $seconds = $seconds % 60;
    }
    if ( $minutes ) {
        $hours   = int( $minutes / 60 );
        $minutes = $minutes % 60;
    }
    return sprintf "%d:%02d:%02d", $hours // 0, $minutes // 0, $seconds if $long;
    return sprintf "%d:%02d:%02d", $hours,      $minutes,      $seconds if $hours;
    return sprintf "%d:%02d",                   $minutes,      $seconds if $minutes;
    return sprintf "0:%02d",                                   $seconds;
}


sub write_json {
    my ( $file, $ref ) = @_;
    my $json = JSON->new->pretty->canonical->utf8->encode( $ref );
    open my $fh, '>', $file or die $file . " $!";
    flock $fh, LOCK_EX     or die $!;
    seek  $fh, 0, SEEK_END or die $!;
    print $fh $json;
    close $fh;
}


sub read_json {
    my ( $file ) = @_;
    return if ! -f $file;
    open my $fh, '<', $file or die $file . " $!";
    flock $fh, LOCK_SH or die $!;
    my $json = do { local $/; <$fh> };
    close $fh;
    my $ref;
    $ref = JSON->new->utf8->decode( $json ) if $json;
    return $ref;
}





1;


__END__
