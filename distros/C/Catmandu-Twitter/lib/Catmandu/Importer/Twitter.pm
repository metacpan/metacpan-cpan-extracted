package Catmandu::Importer::Twitter;

use Catmandu::Sane;
use Moo;
use Net::Twitter;

with 'Catmandu::Importer';

our $VERSION = '0.03';

has query                       => ( is => 'ro', required => 1 );
has twitter                     => ( is => 'ro' );
has twitter_consumer_key        => ( is => 'ro', required => 1 );
has twitter_consumer_secret     => ( is => 'ro', required => 1 );
has twitter_access_token        => ( is => 'ro', required => 1 );
has twitter_access_token_secret => ( is => 'ro', required => 1 );

before generator => sub {
    my $self = shift;
    $self->{twitter} = Net::Twitter->new(
        traits              => [qw/API::RESTv1_1/],
        consumer_key        => $self->twitter_consumer_key,
        consumer_secret     => $self->twitter_consumer_secret,
        access_token        => $self->twitter_access_token,
        access_token_secret => $self->twitter_access_token_secret,
    ) or die "$!";

};

sub generator {
    my ($self) = @_;

    sub {
        state $res = $self->{twitter}->search( $self->query );

        return unless @{ $res->{statuses} };
        return shift @{ $res->{statuses} };
    };
}

=head1 NAME

Catmandu::Importer::Twitter - Package that imports Twitter feeds

=head1 SYNOPSIS

    use Catmandu::Importer::Twitter;

    my $importer = Catmandu::Importer::Twitter->new(
                        consumer_key => '<your key>' ,
                        consumer_secret => '<your secret>' ,
                        access_token => '<your token>' ,
                        access_token_secret => '<your token secret>' ,    
                        query => '#elag2013' 
                    );

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 METHODS

=head2 new(query => '...')

Create a new Twitter importer using a query as input.

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::Twitter methods are not idempotent: Twitter feeds can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
