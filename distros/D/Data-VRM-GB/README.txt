=head1 NAME

Data::VRM::GB - Extract data about British vehicle registration marks

=head1 DESCRIPTION

This module allows you to get age information based on a vehicle registration
mark.

=head1 SYNOPSIS

    use Data::VRM::GB qw/decode_vrm/;

    my $vd = decode_vrm('AB56 RST');
    $vd->{start_date};
    $vd->{end_date};

=head1 LIMITATIONS

The API is unstable - we haven't fully decided on the API and return data types yet.

=head1 EXPORTS

=head2 decode_vrm

A function which takes a VRM as its first and only argument, and returns a
HASHREF with the keys C<start_date> and C<end_date>.
Each of those keys has as its value a DateTime object, truncated to the 'day'.

If the registration mark couldn't be decoded to a date, either
because it's of an unrecognised format or is using a letter prefix that is
not understood, then it will return undef.

Before comparing these dates with another DateTime, you must ensure you
truncate your DateTime to the day.  If you have a time portion, you will
get errors creeping in.

    DateTime->compare(
       decode_vrm('AB56 RST')->{end_date},
       $your_dt->truncate(to => 'day')
    );


=head1 COPYRIGHT & LICENSE

Copyright (C) 2015 Opus Vision Limited

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

Telephone: C< +44 (0)1788 298 410 >

Email: C< community@opusvl.com >

