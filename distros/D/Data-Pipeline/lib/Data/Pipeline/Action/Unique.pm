package Data::Pipeline::Action::Unique;

use Moose;
with 'Data::Pipeline::Action';

has key_generator => (
    isa => 'CodeRef',
    is => 'ro',
    lazy => 1,
    predicate => 'has_key_generator',
    default => sub { 
        sub { $_[0] } 
    }
);

has fields => (
    isa => 'ArrayRef',
    is => 'ro',
    lazy => 1,
    predicate => 'has_fields',
    default => sub { [ ] }
);

sub transform {
    my($self, $iterator) = @_;

    $iterator = $self -> make_iterator($iterator);

    my %seen;
    my $next = $iterator -> next;

    if($self -> has_fields && !$self -> has_key_generator) {
        $self -> key_generator(sub {
            join("\0\0", @{$_[0]}{@{$self -> fields}})
        });
    }

    $seen{$self -> key_generator -> ($next)}++;

    return Data::Pipeline::Iterator -> new(
        source => Data::Pipeline::Source::Iterator -> new(
            has_next => sub {
                !$iterator -> finished;
            },
            get_next => sub {
                my $ret = $next;
                while( !$iterator -> finished ) {
                    $next = $iterator -> next;
                    last unless $seen{ $self -> key_generator -> ($next) }++;
                }
                $next = undef if $iterator -> finished;
                return $ret;
            },
        )
    );
}

1;

__END__
