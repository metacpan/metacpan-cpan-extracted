package Bio::KBase;

use 5.006;
use strict;
use warnings;

use Bio::KBase::CDMI::Client;

=head1 NAME

Bio::KBase - DOE Systems Biology Knowledgebase

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

our %DefaultURL = (central_store => 'http://bio-data-1.mcs.anl.gov/services/cdmi_api',
		   id_server => 'http://bio-data-1.mcs.anl.gov/services/idserver');

sub new
{
    my($class) = @_;
    my $self = {
    };
    return bless $self, $class;
}

sub central_store
{
    my($self) = @_;

    return Bio::KBase::CDMI::Client->new($DefaultURL{central_store});
}

sub id_server
{
    my($self) = @_;

    my $server;
    eval {
	require Bio::KBase::IDServer::Client;
	$server = Bio::KBase::IDServer::Client->new($DefaultURL{id_server});
    };
    if ($@)
    {
	die "ID server client code is not available in this installation";
    }
    return $server;
}

=head1 SYNOPSIS

    use Bio::KBase;

    my $kb = Bio::KBase->new();
    my $store = $kb->central_store();
    my $id_server = $kb->id_server();

=head1 SUBROUTINES/METHODS

=over

=item $kb = Bio::KBase->new()

Create KBase object creation object.

=item $store = $kb->central_store($url)

Create an instance of L<Bio::KBase::CentralStore> to access the Central Store. If
C<$url> is provided, use that url as the contact address for the service.

=item $idserver = $kb->id_server($url)

Create an instance of L<Bio::KBase::IDServer> to access the ID Server. If
C<$url> is provided, use that url as the contact address for the service.

=back

=head1 AUTHOR

Robert Olson, C<< <olson at mcs.anl.gov> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-kbase at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-KBase>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::KBase


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-KBase>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-KBase>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-KBase>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-KBase/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

=cut

1; # End of Bio::KBase
