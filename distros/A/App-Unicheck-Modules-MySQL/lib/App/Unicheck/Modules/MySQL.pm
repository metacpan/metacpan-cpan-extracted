package App::Unicheck::Modules::MySQL;

use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Moo;
use Getopt::Long qw(GetOptionsFromArray);
use Try::Tiny;
use DBI;
use JSON;

=head1 NAME

App::Unicheck::Modules::MySQL - App::Unicheck module to check mysql connections and servers.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

App::Unicheck::Modules::MySQL can be used to check server availability, version, database sizes and more.

	# for additional information run
	unicheck --info MySQL

=cut

sub run {
	my ($self, $action, @params) = @_;

	$self->$action(@params);
}

=head1 ACTIONS

=head2 reachable

Check if the server is reachable.

	# check default localhost:3306
	unicheck MySQL reachable

	# check specific host:port
	unicheck MySQL reachable --host example.com --port 1234

=cut

sub reachable {
	my ($self, @params) = @_;

	my $host = 'localhost';
	my $port = 3306;
	my $format = 'num';
	my $user = '';
	my $pass = '';
	my $database = '';

	GetOptionsFromArray([@params],
        'port=i' => \$port,
        'host=s' => \$host,
        'format=s' => \$format,
        'user=s' => \$user,
        'pass=s' => \$pass,
        'database=s' => \$database,
    );

    my $retval;
    my $conn_string = "dbi:mysql:database=$database;host=$host;port=$port";
    try {
    	my $dbh = DBI->connect($conn_string, $user, $pass, { RaiseError => 1 });
    	$retval = $self->_return(1, "Connection to $host:$port successful", $format);
    } catch {
    	$retval = $self->_return(0, $_, $format);
    };

    $retval;
}

sub _return {
    my ($self, $status, $value, $format) = @_;

    return JSON->new->encode(
        {
            message => $value,
            status  => $status,
        }
    ) if $format eq 'json';
    # default last in case some non supported format was given
    return $status; # if $format eq 'num'
}

sub help {
    {
        description => 'Check MySQL status',
        actions => {
            reachable => {
                description => 'Check if MySQL server is reachable',
                params => {
                    '--host'   => 'Default: localhost',
                    '--port'   => 'Default: 27017',
                    '--format' => 'Default: num',
                    '--user'   => 'Default: none',
                    '--pass'   => 'Default: none',
                },
                formats => {
                    'num'  => 'Returns the status code',
                    'json' => 'Returns a JSON structure',
                },
            },
        },
    }
}

=head1 AUTHOR

Matthias Krull, C<< <m.krull at uninets.eu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-unicheck-modules-mysql at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Unicheck-Modules-MySQL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Unicheck::Modules::MySQL


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Unicheck-Modules-MySQL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Unicheck-Modules-MySQL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Unicheck-Modules-MySQL>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Unicheck-Modules-MySQL/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Matthias Krull.

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

1; # End of App::Unicheck::Modules::MySQL
