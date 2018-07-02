package # hide from PAUSE
App::YTDL::Helper;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( sec_to_time check_mapping_stdout write_json read_json uni_capture uni_system HIDE_CURSOR SHOW_CURSOR );

use Encode             qw( encode FB_CROAK LEAVE_SRC );
use Fcntl              qw( LOCK_EX LOCK_SH SEEK_END );
use Unicode::Normalize qw( NFC );

use Encode::Locale         qw();
use IPC::System::Simple    qw( capture system );
use JSON                   qw();
#use Text::Unidecode       qw( unidecode ); # require-d

use if $^O eq 'MSWin32', 'Win32::ShellQuote';

use constant {
    HIDE_CURSOR => "\e[?25l",
    SHOW_CURSOR => "\e[?25h",
};


sub check_mapping_stdout {
    my ( $opt, $string ) = @_;
    return $string if $Encode::Locale::ENCODING_CONSOLE_OUT =~ /^UTF-/i;
    return $string if eval { encode( 'console_out', $string, FB_CROAK | LEAVE_SRC ) };
    my $rc = eval {
        require Text::Unidecode;
        Text::Unidecode->import();
        1;
    };
    if ( $rc ) {
        my @words;
        for my $word ( split / /, $string ) {
            my $encoded_word;
            if ( eval { $encoded_word = encode( 'console_out', $word, FB_CROAK | LEAVE_SRC ) } ) {
                push @words, $encoded_word;
            }
            else {
                my $unidecoded_word = Text::Unidecode::unidecode( $word );
                push @words, $unidecoded_word;
            }
        }
        return join ' ', @words;
    }
    binmode STDOUT, ':pop';
    my $encoded_lax = encode( 'console_out', NFC $string, sub { '*' } );
    binmode STDOUT, ':encoding(console_out)';
    return $encoded_lax;
}


sub uni_capture {
    my ( @cmd ) = @_;
    if ( wantarray ) {
        my @capture;
        if ( $^O eq 'MSWin32' ) {
            @capture = capture( Win32::ShellQuote::quote_native( @cmd ) );
        }
        else {
            @capture = capture( @cmd );
        }
        return @capture;
    }
    else {
        my $capture;
        if ( $^O eq 'MSWin32' ) {
            $capture = capture( Win32::ShellQuote::quote_native( @cmd ) );
        }
        else {
            $capture = capture( @cmd );
        }
        return $capture;
    }
}


sub uni_system {
    my ( @cmd ) = @_;
    if ( $^O eq 'MSWin32' ) {
        system( Win32::ShellQuote::quote_native( @cmd ) );
    }
    else {
        system( @cmd );
    }
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
    my ( $opt, $file, $ref ) = @_;
    my $json = JSON->new->pretty->canonical->utf8->encode( $ref );
    open my $fh, '>', $file or die $file . " $!";
    flock $fh, LOCK_EX     or die $!;
    seek  $fh, 0, SEEK_END or die $!;
    print $fh $json;
    close $fh;
}


sub read_json {
    my ( $opt, $file ) = @_;
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
