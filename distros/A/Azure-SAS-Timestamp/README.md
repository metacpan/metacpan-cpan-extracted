# NAME

Azure::SAS::Timestamp - Creating timestamps for Azure Shared Access Signatures.

# SYNOPSIS

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

# DESCRIPTION

Azure::SAS::Timestamp can be used to generate validly formated timestamps to
be used when creating an Azure SAS (Shared Access Signature).
Azure::SAS::Timestamp supports input as seconds from epoch, [DateTime](https://metacpan.org/pod/DateTime) objects
and [Time::Piece](https://metacpan.org/pod/Time%3A%3APiece) objects.

There is only one method, \`sas\_time\`, which is an ISO 8601 format with a 'Z'
at the end.

The general idea is simply to allow a bit of sugar to avoid having to look up
the format to use and the object methods of conversion.

# SEE ALSO

[Documentation for Shared Access Signatures
](https://docs.microsoft.com/en-us/rest/api/storageservices/create-service-sas)

# LICENSE

Copyright (C) Ben Kaufman.

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

# AUTHOR

Ben Kaufman (WHOSGONNA) ben.whosgonna.com@gmail.com
