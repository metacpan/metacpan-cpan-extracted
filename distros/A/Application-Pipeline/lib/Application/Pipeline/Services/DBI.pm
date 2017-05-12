package Application::Pipeline::Services::DBI;
$VERSION = '0.1.1';

#-- pragmas ---------------------------- 
 use strict;
 use warnings;

#-- modules ---------------------------- 
 use DBI;

=head1 Application::Pipeline::Services::DBI

This plugin for Application::Pipeline makes available a singleton database
handle. To access it from the application:

$pipeline->loadPlugin( 'DBI' ( dbi::connect parameters ) );

$dbh = $pipeline->dbh;

=cut

#===============================================================================

our $dbh = undef;

sub load {
    my( $class, $pipeline, @args ) = @_;
    $dbh ||= DBI->connect( @args );

    $pipeline->addServices( dbh => $dbh );
    $pipeline->addHandler( 'Teardown', sub{ $dbh->disconnect() }, 'LAST' );
    return $dbh;
}

#========
1;

=head2 Authors

Stephen Howard <stephen@thunkit.com>

=head2 License

This module may be distributed under the same terms as Perl itself.

=cut
