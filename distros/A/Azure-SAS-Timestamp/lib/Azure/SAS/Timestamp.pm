package Azure::SAS::Timestamp;
use Moo;
use Types::Standard qw(Int Str InstanceOf);
use Time::Piece;
use Regexp::Common 'time';

our $VERSION = '0.0.4';

has time_piece => (
    is  => 'rw',
    isa => InstanceOf['Time::Piece']
);

sub sas_time {
    ## Azure SAS requires time in UTC, but the timestamp must be "Z", not "UTC"
    my $self = shift;
    return $self->time_piece->strftime( '%Y-%m-%dT%TZ' );
}

sub epoch {
    my $self = shift;
    return $self->time_piece->epoch;
}

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;

    my $arg = $args[0];

    my $time_piece;
    my $int_check = Int;
    my $str_check = Str;
    my $tp_check  = InstanceOf['Time::Piece'];
    my $dt_check  = InstanceOf['DateTime'];

    ## If the argument is an integer, assume it's an epoch stamp.
    if ( $int_check->check( $arg ) ) {
        $time_piece = Time::Piece->strptime( $arg, '%s');     
    }
    elsif ( $str_check->check( $arg ) ) {
        $time_piece = parse_timestamp_str( $arg );
    }
    elsif ( $tp_check->check( $arg ) ) {  ## If $arg is a Time::Piece object
        $time_piece = $arg;
    }
    elsif ( $dt_check->check( $arg ) ) {
        $time_piece = Time::Piece->strptime( $arg->epoch, '%s' );
    }
    else {
        die "Couldn't parse argument to Time::Piece";
    }
    
    return { time_piece => $time_piece }

};



sub parse_timestamp_str {
    my $str = shift;
   
    ## NOTE:  It looks like Time::Piece strptime will not support timezone by
    ## name, so we can't support arguments where the zone is expressed this 
    ## way (for example 2020-05-10T10:00:00CST).  It (maybe?) can parse an
    ## offset.  Also, DateTime could (of course) handle this. Of course, 
    ## DateTime will not handle parsing the string as well.  For now, we won't
    ## support alternate time zones.
    if ( $str =~ /^
            (?<timestamp>   # Start capture $1
                \d{4} - \d{2} - \d{2} T \d{2}:\d{2} # Matches YYYY-MM-DDTHH:mm
                (:\d{2})?                           # Optionally matches :SS
            )
            (?<timezone> Z|\w{3})? ## Could have timezone or literal "Z"
            $/x
      ) { 
        return Time::Piece->strptime( $1, '%Y-%m-%dT%T' );
    }

    if ( $str =~ /^\d{4} - \d{2} - \d{2}$/) {  ## Matches YYYY-MM-DD
        return Time::Piece->strptime( $str, '%Y-%m-%d' );
        
    }

    else { 
        die("$str does not look like an iso8601 datetime");
    }

}


1;

__END__

=head1 NAME

Azure::SAS::Timestamp - Creating timestamps for Azure Shared Access Signatures.


=head1 SYNOPSIS

 use Azure::SAS::Timestamp;
 
 my $ast;

 # Using an epoch time stamp
 $ast = Azure::SAS::Timestamp->new( 1589119719 );
 print $ast->sas_time;  # 2020-05-10T14:08:39Z
 
 
 # Using a DateTime object:
 use DateTime;
 $dt  = DateTime->new(
     year   => 2020,
     month  => 5,
     day    => 10,
     hour   => 13,
     minute => 12,
     second => 0
 );
 $ast = Azure::SAS::Timestamp->new( $dt ); 
 print $ast->sas_time;  # 2020-05-10T13:12:00Z
 
 # Using Time::Piece
 use Time::Piece;
 my $tp = Time::Piece->strptime( '2020-05-10T13:12:00', '%FT%T');
 $ast   = Azure::SAS::Timestamp->new( $tp );
 print $ast->sas_time;  # 2020-05-10T13:12:00Z


=head1 DESCRIPTION

Azure::SAS::Timestamp can be used to generate validly formated timestamps to
be used when creating an Azure SAS (Shared Access Signature).
Azure::SAS::Timestamp supports input as seconds from epoch, L<DateTime> objects
and L<Time::Piece> objects.

There is only one method, `sas_time`, which is an ISO 8601 format with a 'Z'
at the end.

The general idea is simply to allow a bit of sugar to avoid having to look up
the format to use and the object methods of conversion.

=head1 SEE ALSO

L<Documentation for Shared Access Signatures
|https://docs.microsoft.com/en-us/rest/api/storageservices/create-service-sas>

=head1 LICENSE

Copyright (C) Ben Kaufman.

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=head1 AUTHOR

Ben Kaufman (WHOSGONNA) ben.whosgonna.com@gmail.com



