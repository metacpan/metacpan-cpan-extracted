package Cikl::Util::TimeHelpers;
use strict;
use warnings;
use DateTime::Format::DateParse;
use DateTime::Format::Strptime;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
    normalize_timestamp
    create_strptime_parser
    create_default_timestamp_parser
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw//;

=head1 NAME

Cikl::Util::TimeHelpers - Time helpers for Cikl

=head1 SYNOPSIS

  use Cikl::Util::TimeHelpers qw/normalize_timestamp/;

  my $dt = DateTime->now()
  $dt = normalize_timestamp($dt);
  warn $dt;

=over

=item normalize_timestamp($ts)

  Take in a timestamp (see DateTime::Format::DateParse), does a little extra normalizing and returns a DateTime object

=cut

sub normalize_timestamp {
    my $dt  = shift;
    my $now = shift || time(); # better perf in loops if we can pass the default now value

    if (!defined($dt)) {
      # Default to now.
      return $now;
    }

    if(ref($dt) eq 'DateTime'){
      return $dt->epoch();
    }
    
    # already epoch
    if($dt =~ /^\d{10}$/) {
      return $dt ;
    }

    if($dt =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/) {
      my $ret = DateTime::Format::DateParse->parse_datetime($dt, "UTC");
      if ($ret) { 
        return $ret->epoch();
      }
      return undef;
    }
    
    # something else
    if($dt =~ /^\d+$/){
      if($dt =~ /^\d{8}$/){
        $dt.= 'T00:00:00Z';
        $dt = eval { DateTime::Format::DateParse->parse_datetime($dt, "UTC") };
        unless($dt){
          return $now;
        }
        return $dt->epoch();
      } else {
        return $now;
      }
    } elsif($dt =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\S+)?$/) {
      my ($year,$month,$day,$hour,$min,$sec,$tz) = ($1,$2,$3,$4,$5,$6,$7);
      $dt = DateTime::Format::DateParse->parse_datetime($year.'-'.$month.'-'.$day.' '.$hour.':'.$min.':'.$sec,$tz || "UTC");
      return $dt->epoch();
    } 

    $dt =~ s/_/ /g;
    $dt = DateTime::Format::DateParse->parse_datetime($dt, "UTC");
    return undef unless($dt);
    return $dt->epoch();
}

=back
=cut

sub create_default_timestamp_parser {
  return \&normalize_timestamp;
}

sub create_strptime_parser {
  my $pattern = shift;
  my $zone = shift || "UTC";
  my $parser = DateTime::Format::Strptime->new(
      pattern => $pattern,
      time_zone => $zone
    ) or die("Invalid datetime format: '$pattern', zone: '$zone'");

  return sub { 
    my $str = shift;
    my $now = shift || time();
    my $t = $parser->parse_datetime($str) or die($!);
    return $t->epoch();
  };
}

1;
