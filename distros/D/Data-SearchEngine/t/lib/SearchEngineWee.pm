package # Hide from CPAN
    SearchEngineWee;
use Moose;

with (
    'Data::SearchEngine', 'Data::SearchEngine::Modifiable'
);

use Data::SearchEngine::Item;
use Data::SearchEngine::Paginator;
use SEWeeResults;
use Time::HiRes qw(time);

has index => (
    traits => [ 'Hash' ],
    is        => 'rw',
    isa       => 'HashRef[HashRef]',
    default   => sub { {} },
    handles  => {
        delete  => 'delete',
        exists  => 'exists',
        get     => 'get',
        keys    => 'keys',
        set     => 'set',
    },
);

sub add {
    my ($self, $prod) = @_;

    $self->set($prod->{name}, $prod);
}

sub present {
    my ($self, $prod) = @_;

    return $self->exists($prod->{name});
}

sub search {
    my ($self, $oquery) = @_;

    my $query = lc($oquery->query);

    my $start = time;
    my %items;
    my @parts = split(/ /, $query);

    foreach my $part (@parts) {
        foreach my $key ($self->keys) {

            my $prod = $self->get($key);

            my $score = 0;
            my $item = undef;
            if($items{$prod->{id}}) {
                $item = $items{$prod->{id}};
                $score = $item->score;
            }

            if(lc($prod->{name}) =~ /$part/) {
                $score++;
            }

            if(lc($prod->{description}) =~ /$part/) {
                $score++;
            }

            next unless $score > 0;

            if(defined($item)) {
                $item->score($score);
            } else {
                my $item = Data::SearchEngine::Item->new(
                    id          => $prod->{id},
                    score       => $score
                );
                $item->set_value('description', $prod->{description});
                $item->set_value('name', $prod->{name});
                $items{$prod->{id}} = $item;
            }
        }
    }

    my @sorted_keys = sort { $items{$b}->score <=> $items{$a}->score } keys %items;

    my @sorted = ();
    foreach my $s (@sorted_keys) {
        push(@sorted, $items{$s});
    }

    return SEWeeResults->new(
        query => $oquery,
        pager => Data::SearchEngine::Paginator->new(
            entries_per_page => 1,
            total_entries => scalar(@sorted)
        ),
        items => \@sorted,
        elapsed => time - $start
    );
}

sub find_by_id {}

sub remove {
    my ($self, $prod) = @_;

    $self->delete($prod->{name});
}

sub remove_by_id {
	my ($self, $id) = @_;

    foreach my $key ($self->keys) {

        my $prod = $self->get($key);
		if($prod->{id} eq $id) {
			$self->delete($key);
			return 1;
		}
	}
	return 0;
}

sub update {
    my ($self, $prod) = @_;

    $self->set($prod->{name}, $prod);
}

1;