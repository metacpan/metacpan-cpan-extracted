package Data::Pipeline::Adapter::UrlBuilder;

use Moose;
extends 'Data::Pipeline::Adapter';

use Data::Pipeline::Iterator::Options;
use URI;

has base => (
    isa => 'Str',
    is => 'rw',
    required => 1,
);

has path_elements => (
    isa => 'ArrayRef',
    is => 'rw',
    lazy => 1,
    default => sub { [ ] }
);

has query => (
    isa => 'HashRef',
    is => 'rw',
    lazy => 1,
    default => sub { +{ } }
);

use Data::Dumper;

has '+source' => (
    default => sub {
        my $self = shift;
        my $query = Data::Pipeline::Iterator::Options -> new(
            params => $self -> query
        );

        return Data::Pipeline::Iterator::Source -> new(
            has_next => sub { !$query -> finished },
            get_next => sub {
                my $o = $query -> next;
                my $uri = URI->new(join('/', $self -> base, @{$o -> {path_elements}||[]}));
                $uri -> query_form( $o  );
                my $u = $uri -> canonical -> as_string;
#                print STDERR "UrlBuilder: $u\n";
                return $u;
            }
        );
    }
);

1;

__END__
