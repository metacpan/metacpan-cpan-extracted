package DBIx::CheckConnectivity;

use warnings;
use strict;
use Carp;

our $VERSION     = '0.02';

use base 'Exporter';

our @EXPORT = qw/check_connectivity/;

use DBI;
use Params::Validate qw/:all/;
use UNIVERSAL::require;

sub check_connectivity {
    validate(
        @_,
        {
            dsn             => { type => SCALAR,  regex    => qr/^dbi:/ },
            user            => 0,
            password        => 0,
            attribute       => { type => HASHREF, optional => 1 },
        }
    );
    my %args = @_;
    my $dsn = $args{dsn};

    my ( $driver ) = $dsn =~ m/dbi:(\w+):/;
    my $driver_module = __PACKAGE__ . '::Driver::' . $driver;
    $driver_module->require
          or confess "$driver is not supported yet, sorry";
    $driver_module->check_connectivity( @_ );

}

1;

__END__

=head1 NAME

DBIx::CheckConnectivity - util to check database's connectivity


=head1 SYNOPSIS

    use DBIx::CheckConnectivity;
    my ( $ret, $msg ) = check_connectivity( dsn => 'dbi:mysql:database=myjifty', user => 'jifty',
            password => 'blabla' );

    if ( $ret ) {
        print 'we can connect';
    }
    else {
        warn "can not connect: $msg";
    }

=head1 DESCRIPTION


=head1 INTERFACE

=over 4

=item check_connectivity ( dsn => $dsn, user => $user, password => $password, attribute => $attribute )

return 1 if success, undef otherwise.
in list context, if connect fails, returns a list, the 1st one is undef, 
the 2nd one is the error message.

=back

=head1 DEPENDENCIES

L<DBI>, L<Params::Validate>, L<UNIVERSAL::require>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

currently, only mysql, Pg and SQLite are supported.

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2009 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

