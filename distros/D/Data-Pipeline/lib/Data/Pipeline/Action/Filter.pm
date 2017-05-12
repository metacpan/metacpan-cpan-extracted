package Data::Pipeline::Action::Filter;

use Moose;
with 'Data::Pipeline::Action';

use MooseX::Types::Moose qw(RegexpRef CodeRef);

use Data::Pipeline::Types qw( Iterator );

has filter => (
    isa => 'CodeRef',
    is => 'rw',
    lazy => 1,
    predicate => 'has_filter',
    default => sub { sub { $_[0] } }
);

#   filters => { title => qr/^\[(video|audiobook|game)\]/ }
#   reject_matching => 1
has filters => (
    isa => 'HashRef',
    is => 'ro',
    lazy => 1,
    predicate => 'has_filters',
    default => sub { +{ } }
);

has reject_matching => (
    isa => 'Bool',
    is => 'ro',
    default => 0
);

has require_all => (
    isa => 'Bool',
    is => 'ro',
    default => 1
);

sub BUILD {
    my($self) = @_;

    if(! $self -> has_filter && $self -> has_filters ) {
#        print "BUilding a filter\n";
        my %filters = %{$self -> filters};
        $self -> filter(sub {
            my $item = $_[0];
            my $match = 0;
            foreach my $f ( keys %filters ) {
                if( is_RegexpRef( $filters{$f} ) ) {
                    no warnings;
                    $match = !!($item->{$f} =~ $filters{$f});
#                    print "$f: $filters{$f} == $match\n";
                }
                elsif( is_CodeRef( $filters{$f} ) ) {
                    $match = !!($filters{$f} -> ($item->{$f}));
                }
                else {
                    $match = $item->{$f} eq $filters{$f};
                }

                return 0 if  $self -> require_all && ($match == $self -> reject_matching);
                return 1 if !$self -> require_all && ($match != $self -> reject_matching);
            }

            return $self -> require_all;
        });
    }
}

sub transform {
    my($self, $iterator) = @_;

    $iterator = to_Iterator($iterator);

    my($next, $has_next);

    while( !$iterator -> finished ) {
        $next = $iterator -> next;
        $has_next = 1;
        last if $self -> filter -> ($next);
        $next = undef;
        $has_next = 0;
    }

    return Data::Pipeline::Iterator -> new(
        source => Data::Pipeline::Iterator::Source -> new(
            has_next => sub {
                $has_next;
            },
            get_next => sub {
                my $ret = $next;
                while( !$iterator -> finished ) {
                    $next = $iterator -> next;
                    $has_next = 1;
                    last if $self -> filter -> ($next);
                    $next = undef;
                    $has_next = 0;
                }
                $has_next = 0 if $iterator -> finished;
                $iterator = undef unless $has_next;
                return $ret;
            },
        )
    );
}

1;

__END__
