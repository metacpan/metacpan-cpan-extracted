use strict;
use warnings;
package C3000::RepUtils;
use constant DEBUG => 0;
use C3000;
use File::Basename;
use Config::Tiny;
use Win32;
use File::Spec::Functions;
use Win32::ExcelSimple;
use DateTime;
use DateTime::Format::Natural;
use DateTime::Format::Oracle;
use Exporter;
our @ISA       = qw( Exporter );
our @EXPORT    = qw( init read_conf make_rep_name  );


our $VERSION = 0.11;


# ABSTRACT: turns baubles into trinkets

sub init{
my $c3000_h = C3000->new();
my $config_h  = read_conf();
my @excel_hs = map { Win32::ExcelSimple->new($_) } split /\s+/, $config_h->{template_name}; 
my $dt_parser_now = DateTime::Format::Natural->new(
        lang      => 'en',
        format    => 'yyyy/mm/dd',
        time_zone => 'Asia/Taipei',
    );
my $dt_from;
my $dt_to;
my $dt_start;
if (defined $config_h->{from}){
	$dt_from = $dt_parser_now->parse_datetime($config_h->{from});
}
else{
	$dt_from = $dt_parser_now->parse_datetime();
}
if (defined $config_h->{to}){
	$dt_to = $dt_parser_now->parse_datetime($config_h->{to});
}
else{
	$dt_to = $dt_parser_now->parse_datetime();
}
if (defined $config_h->{time_start}){
	$dt_start = $dt_parser_now->parse_datetime($config_h->{time_start});
}
else{
	$dt_start = $dt_parser_now->parse_datetime();
}
my $dt_parser = DateTime::Format::Natural->new(
	    datetime  => $dt_start,
        lang      => 'en',
        format    => 'yyyy/mm/dd',
        time_zone => 'Asia/Taipei',
    );
return ($c3000_h, $config_h, $dt_parser, $dt_from, $dt_to, @excel_hs);
}

sub read_conf{

   Config::Tiny->new();
my $path = dirname($0);
my $file_name = basename($0);
   $file_name =~ s/\..+$/\.ini/;
   $file_name = 'RepAuto.ini' if $file_name !~ /\.ini$/;
   $path = Win32::GetFullPathName($path);
my $abs_ini = catfile($path, $file_name);
my $Config = Config::Tiny->read($abs_ini) or die "can't open config file! $!";
   return $Config->{_};
}



sub make_rep_name{
	my($string, $rep_path, $templ_name, $from_dt, $to_dt) = @_;
	$ENV{'NLS_DATE_FORMAT'} = 'YYYYMMDDHH24MI';
     my $create_time_str =   DateTime::Format::Oracle->format_datetime(DateTime->now());
	print $create_time_str . "is create time \n" if DEBUG == 1; 
   	 my $from_time_str =     DateTime::Format::Oracle->format_datetime($from_dt);
	print $create_time_str . "is from time \n" if DEBUG == 1; 
     my $to_time_str       = DateTime::Format::Oracle->format_datetime($to_dt);
	print $create_time_str . "is to time \n" if DEBUG == 1; 
	$string =~ s/%c/$create_time_str/g;
	$string =~ s/%templ_name/$templ_name/g;
	$string =~ s/%f/$from_time_str/g;
	$string =~ s/%t/$to_time_str/g;
	$string .= '.xls';
    return catfile($rep_path, $string);
}

sub RepAuto_callback{
       my ($cell_h, $hl, $parser_from, $parser_to, $parser_now) = @_; 
	return if !defined $_[0]->{Value};
	return if $_[0]->{Value} !~ /^~~~/;

                my @a = split /__/, substr( $_[0]->{Value}, 3 )  ;    #grab useful string
                $_[0]->{Value} =  convert_xls_date( $parser_from, $parser_to, $parser_now, $a[0]);
				if ( scalar @a == 3 ) {
                    $a[2] =
                      convert_xls_date( $parser_from, $parser_to, $parser_now,
                        $a[2] );
                    $_[0]->{Value} =
                      $hl->get_single_LP( 'ADAS_VAL_RAW', @a );
                }
                if ( scalar @a == 4 ) {
                    if ( $a[3] =~ /^\[/ ) {
                        $a[2] =
                          convert_xls_date( $parser_from, $parser_to,
                            $parser_now, $a[2] );
                        $_[0]->{Value} =
                          $hl->get_single_LP( 'ADAS_VAL_RAW', @a );
                    }
                    else {
                        $a[2] =
                          convert_xls_date( $parser_from, $parser_to,
                            $parser_now, $a[2] );
                        $a[3] =
                          convert_xls_date( $parser_from, $parser_to,
                            $parser_now, $a[3] );

                        $_[0]->{Value} =
                          $hl->accu_LP( 'ADAS_VAL_NORM', @a );
                    }
                }
                if ( scalar @a == 5 ) {
                    $a[2] =
                      convert_xls_date( $parser_from, $parser_to, $parser_now,
                        $a[2] );
                    $a[3] =
                      convert_xls_date( $parser_from, $parser_to, $parser_now,
                        $a[3] );
                    $_[0]->{Value} =
                      $hl->accu_LP( 'ADAS_VAL_NORM', @a );


}
}

sub convert_xls_date {
    my ( $parser_from, $parser_to, $parser_now, $string ) = @_;
    if ( $string =~ /^[Ff][Rr][Oo][Mm]\s+(.+)$/ ) {
        return $parser_from ($1);
    }
    elsif ( $string =~ /^[Tt][Oo]\s+(.+)$/ ) {
        return $parser_to ($1);
    }
    else {
        return $parser_now ($1);
    }
}



1;

