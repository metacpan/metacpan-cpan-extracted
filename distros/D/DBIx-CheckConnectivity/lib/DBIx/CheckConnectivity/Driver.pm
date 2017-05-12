package DBIx::CheckConnectivity::Driver;

use warnings;
use strict;
use Carp;

use DBI;
use Params::Validate qw/:all/;

sub check_connectivity {
    my $class = shift;
    validate(
        @_,
        {
            dsn       => { type => SCALAR,  regex    => qr/^dbi:/ },
            user      => 0,
            password  => 0,
            attribute => { type => HASHREF, optional => 1 },
        }
    );
    my %args     = @_;
    my $dsn      = $args{dsn};
    my $user     = $args{user} || '';
    my $password = $args{password} || '';

    my $attribute = $args{attribute} || { RaiseError => 0, PrintError => 0 };
    my ($database) = $dsn =~ m/dbi:(?:\w+):(?:(?:database|dbname)=)?(\w+)/;

    my $dbh = DBI->connect( $dsn, $user, $password, $attribute );

    return 1 if $dbh;
    # so we have an err
    return wantarray ? ( undef, DBI::errstr ) : undef;
}

1;

__END__

=head1 NAME

DBIx::CheckConnectivity::DBI - util to check database's connectivity


=head1 DESCRIPTION

=head1 INTERFACE

=over 4

=item check_connectivity ( dsn => $dsn, user => $user, password => $password, attribute => $attribute )

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2009 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

