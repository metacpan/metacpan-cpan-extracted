package # hide from PAUSE
App::YTDL::Helper;

use warnings;
use strict;
use 5.010000;

use Exporter qw( import );
our @EXPORT_OK = qw( sec_to_time get_filename timestamp_to_upload_date encode_fs check_mapping_stdout format_bytes_per_sec
                    write_json read_json sanitize_for_path uni_capture uni_system HIDE_CURSOR SHOW_CURSOR );

use Encode             qw( encode FB_CROAK LEAVE_SRC );
use Fcntl              qw( LOCK_EX LOCK_SH SEEK_END );
use Time::Local        qw( timelocal );
use Unicode::Normalize qw( NFC );

use Encode::Locale         qw();
use File::Touch            qw();
use IPC::System::Simple    qw( capture system );
use JSON                   qw();
use Term::Choose::LineFold qw( print_columns cut_to_printwidth);
#use Text::Unidecode       qw( unidecode ); # require-d

use if $^O eq 'MSWin32', 'Win32::ShellQuote';

use constant {
    HIDE_CURSOR => "\e[?25l",
    SHOW_CURSOR => "\e[?25h",
};



sub get_filename {
    my ( $opt, $title, $ext, $fmt ) = @_;
    $ext //= 'unknown';
    $fmt //= '';
    $fmt = '_' . $fmt if length $fmt;
    my $len_ext = print_columns( $ext );
    my $len_fmt = print_columns( $fmt );
    my $max_len_title = $opt->{max_len_f_name} - ( $len_fmt + 1 + $len_ext );
    $title = cut_to_printwidth( sanitize_for_path( $opt, $title ), $max_len_title );
    my $file_name = $title . $fmt . '.' . $ext;
    return $file_name;
}


sub sanitize_for_path {
    my ( $opt, $str ) = @_;
    $str =~ s/^\s+|\s+\z//g;
    $str =~ s/\s/_/g             if $opt->{replace_spaces};
    $str =~ s/^\.+//             if $opt->{sanitize_filename};
    $str =~ s{["/\\:*?<>&|]}{-}g if $opt->{sanitize_filename} == 1; # \0
    $str =~ s{/}{-}g             if $opt->{sanitize_filename} == 2; # \0
    # NTFS unsupported characters:  / \ : " * ? < > |
    return $str;
}


sub timestamp_to_upload_date {
    my ( $opt, $info, $ex, $video_id, $file ) = @_;
    return if $info->{$ex}{$video_id}{upload_datetime} eq $opt->{no_upload_datetime};
    if ( $info->{$ex}{$video_id}{upload_datetime} =~ /^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)\z/ ) {
        eval {
            my $time = timelocal( $6, $5, $4, $3, $2 - 1, $1 );
            my $ref = File::Touch->new( time => $time );
            my $count = $ref->touch( encode_fs( $opt, $file ) );
        } or warn $@;
    }
}


sub encode_fs {
    my ( $opt, $filename ) = @_;
    my $encoded_filename;
    if ( eval { $encoded_filename = encode( 'locale_fs', NFC $filename, FB_CROAK | LEAVE_SRC ) } ) {
        return $encoded_filename;
    }
    elsif ( $opt->{unmappable_filename} ) {
        require Text::Unidecode;
        return Text::Unidecode::unidecode( $filename );
    }
    else {
        return $filename;
    }
}


sub check_mapping_stdout {
    my ( $opt, $string ) = @_;
    return $string if $Encode::Locale::ENCODING_CONSOLE_OUT =~ /^UTF-/i;
    return $string if eval { encode( 'console_out', $string, FB_CROAK | LEAVE_SRC ) };
    if ( $opt->{text_unidecode} ) {
        require Text::Unidecode;
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


sub format_bytes_per_sec {
    my ( $val ) = @_;
    return '--k/s' if ! $val;
    $val /= 1024;
    return '--k/s' if $val < 1;
    for my $unit ( 'k', 'M', 'G' ) {
        if ( length int $val > 3 ) {
            $val /= 1024;
            next;
        }
        elsif ( $val < 10 && $unit ne 'k' ) {
            return sprintf "%0.1f%s/s", $val, $unit;
        }
        else {
            return sprintf "%d%s/s", $val, $unit;
        }
    }
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
    open my $fh, '>', encode_fs( $opt, $file ) or die encode_fs( $opt, $file ) . " $!";
    flock $fh, LOCK_EX     or die $!;
    seek  $fh, 0, SEEK_END or die $!;
    print $fh $json;
    close $fh;
}


sub read_json {
    my ( $opt, $file ) = @_;
    return if ! -f encode_fs( $opt, $file );
    open my $fh, '<', encode_fs( $opt, $file ) or die encode_fs( $opt, $file ) . " $!";
    flock $fh, LOCK_SH or die $!;
    my $json = do { local $/; <$fh> };
    close $fh;
    my $ref;
    $ref = JSON->new->utf8->decode( $json ) if $json;
    return $ref;
}





1;


__END__
