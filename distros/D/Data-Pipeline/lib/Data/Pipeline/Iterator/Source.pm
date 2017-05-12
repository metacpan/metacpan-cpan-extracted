package Data::Pipeline::Iterator::Source;

use Moose;
use Carp ();

has has_next => (
    isa => 'CodeRef',
    is => 'rw',
    required => 1
);

has get_next => (
    isa => 'CodeRef',
    is => 'rw',
    required => 1
);

has _iterators => (
    isa => 'HashRef',
    is => 'rw',
    default => sub{ +{ } },
    lazy => 1
);

has _data => (
    isa => 'ArrayRef',
    is => 'rw',
    default => sub{ [ ] },
    lazy => 1
);

has _can_register => (
    isa => 'Bool',
    is => 'rw',
    default => 1
);

sub register {
    my($self, $observer) = @_;

    if($self -> _can_register) {
        $self -> _iterators -> {"".$observer} = undef;
    }
    else {
        Carp::croak "Unable to register an iterator for a data source that has forgotten its beginning";
    }
}

sub unregister {
    my($self, $observer) = @_;

    delete $self -> _iterators -> {"".$observer};
}

sub _push_data {
    my($self) = @_;

    if($self -> has_next -> ()) {
        push @{$self -> _data}, $self -> get_next -> ();
    }
}

sub _prime { $_[0] -> _push_data; }

sub _pop_data {
    my($self) = @_;

    my $min = scalar(@{$self -> _data});
    for my $ob (keys %{$self -> _iterators}) {
        return unless defined $self -> _iterators -> {$ob};
        $min = $self -> _iterators -> {$ob} if $min > $self -> _iterators -> {$ob};
    }

    return if $min == 0;

    for my $ob (keys %{$self -> _iterators}) {
        $self -> _iterators -> {$ob} -= $min;
    }

    splice @{$self -> _data}, 0, $min;

    $self -> _can_register(0);
}

sub finished {
    my($self, $ob) = @_;

    return 1 unless exists $self -> _iterators -> {"".$ob};

    $self -> _iterators->{"".$ob} ||= 0;

    # if $ob is at the end of the _data and data is finished
    if($self -> _iterators->{"".$ob} == scalar(@{$self -> _data})
       && !$self -> has_next -> ()) 
    {
        delete $self -> _iterators->{"".$ob};
        return 1;
    }
}

sub next { 
    my($self, $ob) = @_;

    return if $self -> finished($ob);

    if($self -> _iterators->{"".$ob} == scalar(@{$self -> _data})) {
        $self -> _push_data;
    }

    $self -> _pop_data if rand() > 0.7; # tunable

    return $self -> _data -> [ $self -> _iterators->{"".$ob} ++ ];
}

# duplicate when you want to run through an iterator again but don't want
# to keep it in memory (e.g., reading from a file again)
sub duplicate {
    my($self) = @_;

    # we want to build a new iterator source that should start over
    # we avoid private attributes and {get|has}_next
    # if those are required, we can't duplicate

    my $attrs;

    $attrs = $self -> can_duplicate or return ;
#        Carp::croak "Unable to duplicate a source iterator (".($self -> meta -> name).")";

    my %options;
    $options{$_} = $self -> $_
        foreach grep { !/^_/ && !/^(get|has)_next$/ } (keys %$attrs);

    return $self -> new(%options);
}

sub can_duplicate {
    my($self) = @_;

    my $attrs = $self -> meta -> get_attribute_map;

    # we return $attrs as an optimization
    return $attrs unless
        $attrs -> {'get_next'} -> is_required 
        || $attrs -> {'has_next'} -> is_required;
    return;
}

1;

__END__

we need a way to have observers of an iterator -- basically, anyone using the
iterator is an observer.  This allows multiple pipelines to share a common
pipeline (one splits into multiple) while only running the common pipeline once
