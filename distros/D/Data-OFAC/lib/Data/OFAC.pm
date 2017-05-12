package Data::OFAC;

use 5.006;
use strict;
use warnings;
use Data::OFAC::SDN;

=head1 NAME

Data::OFAC - A Perl interface to the United States Office of Foreign Assets
Control (OFAC) Specially Designated Nationals List (SDN)

=head1 VERSION

Version 0.80

=cut

our $VERSION = '0.80';

=head1 DESCRIPTION

    From OFAC's Website:
        As part of its enforcement efforts, OFAC publishes a list of
        individuals and companies owned or controlled by, or acting for or on
        behalf of, targeted countries. It also lists individuals, groups, and
        entities, such as terrorists and narcotics traffickers designated under
        programs that are not country-specific. Collectively, such individuals
        and companies are called "Specially Designated Nationals" or "SDNs."
        Their assets are blocked and U.S. persons are generally prohibited from
        dealing with them.

    This interface is helpful for insitutions that use Perl, and may have a
    need to screen individuals as potential customers.

    Note that this module will require occasional internet access if
    auto_update is enabled. Auto update contacts OFAC's website to download
    the latest SDN list in "CSV" format. These files are used to build a SQLite
    database. In order to remain "compliant" reasonably frequent updates are
    recommended. For financial institutions, not complying with this carries
    heavy penalties. I am not a lawyer, and I cannot recommend your update
    frequency. I've set 12 hours as I believe this to be a reasonable update
    interval. Again, this module carries no waranty, and cannot be a full
    replacement for full compliance with the regulations. YMMV.

=head1 SYNOPSIS

    A simple example.

    use Data::OFAC;

    my $ofac = Data::OFAC->new(
        auto_update => 1,
        auto_update_frequency => 12,
        database_file => '/path/to/sdn.sqlite'
    );

    my $result = $ofac->checkString($string);

    if ( defined $result ) {
        print "Hit found:" .
            Dumper $result; # varries by hit, but is just a hash.
    }
    ...

=head1 SUBROUTINES/METHODS

=head2 new

    Instantiates the base object. Note that the following parameters are
    currently supported:

=head3 auto_update [0,1] (Optional)

    Tells Data::OFAC whether you desire to update the database. It will check a
    table in SQLite to determine the last update date/time and decide if
    checking for a new update is warranted. Note that the download is not
    particularly large, but the download and subsequent rebuild of the database
    could introduce a startup penalty that may be undesirable. (30 seconds on my
    quad core MBP) For long running processes, there is no present method for
    updating on the fly. Since I run this as part of a larger web service, my
    processes cycle frequently enough that I never have this problem. YMMV

    0 - disable
    1 - enable *default

=head3 auto_update_frequency [int] (Optional)

    Sets the desired delay between rechecks. Data::OFAC will recheck at each
    start if the auto_update property is set to 1.

    Default: 12 (hours)

=head3 database_file [string] (Optional)

    Sets the desired location to keep the database file. The default is your
    home directory in the ".ofac" directory.

    Default: $ENV{HOME}/.ofac/sdn.sqlite or $ENV{USERPROFILE}\.ofac\sdn.sqlite

=cut

sub new {
    my $class = shift;
    my %vars  = @_;
    my $self  = bless {}, $class;

    map { $self->{$_} = $vars{$_} } keys %vars;

    unless ( defined $self->{auto_update} ) {
        $self->{auto_update} = 1;
    }

    unless ( defined $self->{auto_update_frequency} ) {
        $self->{auto_update_frequency} = 12;
    }

    unless ( defined $self->{use_only_exact} ) {
        $self->{use_only_exact} = 0;
    }

    unless ( defined $self->{database_file} ) {
        unless ( -d ( $ENV{HOME} || $ENV{USERPROFILE} ) . "/.ofac" ) {
            mkdir( ( $ENV{HOME} || $ENV{USERPROFILE} ) . "/.ofac" );
        }
        $self->{database_file}
            = ( $ENV{HOME} || $ENV{USERPROFILE} ) . "/.ofac/sdn.sqlite";
    }

    $self->{sdn} = Data::OFAC::SDN->new( p => $self );

    $self->{_status} = $self->{sdn}->{_status};

    return $self;

}

=head2 checkString

Checks the specified string against all fields.

my $result = $ofac->checkString("String");

=cut

sub checkString {
    my $self   = shift;
    my $string = shift;
    my $opts   = shift;

    my $resultset;

    my @columns = qw{sdn_name title};

    for (qw {Sdn SdnComment}) {

        $resultset->{$_} = $self->{sdn}->search( $_, $string, @columns );

    }

    @columns = qw{alt_name};

    $resultset->{Alt} = $self->{sdn}->search( 'Alt', $string, @columns );

    @columns = qw{citystateprovincepostalcode country};

    $resultset->{Address}
        = $self->{sdn}->search( 'Address', $string, @columns );

    return $resultset;
}

=head2 checkAddress

Checks the specified array against the address table. Note the Country must be
spelled out I.E. Nigeria

my $result =
   $ofac->checkAddress("City, State, Province, Postal Code", "Country");

=cut

sub checkAddress {
    my $self    = shift;
    my $address = shift;
    my $country = shift;

    return $self->{sdn}->searchAddress( $address, $country );
}

=head2 checkName

Checks the specified name against the SDN and ALT tables. Note that for the
best match, supply an individual's name in "Lastname, Firstname" format. For
corporations, supply in regular format.

=cut

sub checkName {
    my $self = shift;
    my $name = shift;

    my $resultset;

    my @columns = qw{sdn_name title};

    for (qw {Sdn SdnComment}) {

        $resultset->{$_} = $self->{sdn}->search( $_, $name, @columns );

    }

    @columns = qw{alt_name};

    $resultset->{Alt} = $self->{sdn}->search( 'Alt', $name, @columns );

    return $resultset;
}

=head2 checkStatus

Checks for the database status after startup. Returns "dirty" or "clean". Handy
for determining the validity of the data being returned. Dirty just indicates
that the database hasn't been updated recently.

=cut

sub checkStatus {
    return $_->{_status};
}

=head2 willUpdate

Checks if the next search call will force a database update. If yes, the call
will return "defined" or 1. Helpful if your application is timing sensitive to
prespin the update before your next search. Note that at this time, updating is
a blocking call.

=cut

sub willUpdate {

    ( time() - $_->{sdn}->{_lastupdate} )
        >= ( $_->{auto_update_frequency} * 60 * 60 )
        && return 1;

    return undef;
}

=head2 forceUpdate

Force the update of the database. Will cause a database update to occur. Note
that this call still blocks, but is handy if you want an out-of-band process
to handle the updating.

=cut

sub forceUpdate {
    my $self = shift;
    return $self->{sdn}->updateDatabase();
}

=head1 AUTHOR

tyler hardison, C<< <tyler at seraph-net.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-ofac at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-OFAC>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::OFAC


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-OFAC>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-OFAC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-OFAC>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-OFAC/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Tyler Hardison.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of Data::OFAC
