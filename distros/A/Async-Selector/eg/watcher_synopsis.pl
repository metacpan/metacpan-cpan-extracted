use strict;
use warnings;

sub setup_resources_with {
    my $s = shift;
    $s->register(
        a => sub {
            my $in = shift;
            return $in ? 'a' : undef;
        },
        b => sub {
            my $in = shift;
            return $in ? 'b' : undef;
        }
    );
}

sub handle_a {
    ;
}

sub handle_b {
    ;
}



use Async::Selector;

my $s = Async::Selector->new();

setup_resources_with($s);

## Obtain a watcher from Selector.
my $watcher = $s->watch(a => 1, b => 2, sub {
    my ($w, %res) = @_;
    handle_a($res{a}) if exists $res{a};
    handle_b($res{b}) if exists $res{b};
});

## Is the watcher active?
$watcher->active;                          ## => true

## Get the list of watched resources
my @resources = sort $watcher->resources;  ## => ('a', 'b')

## Get the watcher conditions
my %conditions = $watcher->conditions;     ## => (a => 1, b => 2)

## Cancel the watcher
$watcher->cancel;



{
    local $, = ", ";
    local $\ = "\n";
    print @resources;
    print %conditions;
}

