package Data::Pipeline::Aggregator::Machine;

use Moose;
extends 'Data::Pipeline::Aggregator';

use Data::Pipeline::Machine ();

use MooseX::Types::Moose qw( ArrayRef CodeRef );

use Data::Pipeline::Types qw( Iterator IteratorSource Aggregator );

has pipelines => (
    isa => 'HashRef',
    is => 'rw',
    default => sub { +{ } },
    lazy => 1
);

has sources => (
    isa => 'HashRef',
    is => 'rw',
    default => sub { +{ } },
    lazy => 1
);

has connections => (
    isa => 'HashRef',
    is => 'rw',
    default => sub { +{ } },
    lazy => 1
);

has options => (
    isa => 'HashRef',
    is => 'rw',
    default => sub { +{ } },
    lazy => 1
);

sub add_pipeline {
    my($self, $name, $pipeline) = @_;

    if( exists($self -> pipelines -> {$name} ) ) {
        Carp::carp "Replacing previous pipeline ($name)";
    }

    if( is_CodeRef( $pipeline ) ) {
        $self -> pipelines -> {$name} = $pipeline;
    }
    else {
        $pipeline = [ $pipeline ] unless is_ArrayRef( $pipeline );
        $self -> pipelines -> {$name} = Data::Pipeline::Aggregator::Pipeline -> new( actions => $pipeline );
    }
}

sub add_option {
    my($self, $name, %options) = @_;

    $self -> options -> {$name} = \%options;
}

sub add_source {
    my($self, $name, $source) = @_;

    if( exists( $self -> sources -> {$name} ) ) {
        Carp::carp "Replacing previous source ($name)";
    }

    $self -> sources -> {$name} = to_IteratorSource($source);
}

sub add_connection {
    my($self, $to, @from) = @_;

    if( exists( $self -> connections -> {$to} ) ) {
        Carp::carp "Replacing connections to ($to)";
    }

    $self -> connections -> {$to} = \@from;
}

sub _get_head {
    my($self) = @_;

    my @p_names = grep { defined $self -> pipelines -> {$_} } keys %{$self -> pipelines};
    if( @p_names == 0 ) {
        Carp::croak "No pipelines are defined for " . ($self -> meta -> name);
    }
    elsif( @p_names == 1 ) {
        return $p_names[0];
    }
    elsif(exists( $self -> pipelines -> {'finally'} ) && defined( $self -> pipelines -> {'finally'})) {
        return 'finally';
    }
    else {
        Carp::croak "Unable to determine final pipeline for " . ($self -> meta -> name);
    }
}

sub from {
    my $self = shift;

    my $head;

    $head = shift if @_ % 2 == 1;

    my(%options) = @_; # %options are like sources

    # we have to figure out what's the head/final pipeline

    my $it;
    my $t;

    $head = $self -> _get_head unless defined( $head );;

    #print STDERR "from( $head ) with options for ", join(", ", keys %options), "\n";

    for my $k ( keys %options ) {
        #print STDERR "option $k => $options{$k}\n";
        $options{$k} = $options{$k} -> () if is_CodeRef( $options{$k} );
    }

    return Data::Pipeline::Machine::with_options(sub {
        to_Aggregator($self -> pipelines -> {$head}) -> from( %options );
    }, +{%{$self -> options}, %options});
}

sub transform {
    my($self, $iterator) = @_;

    return Data::Pipeline::Machine::with_options sub {
        $self -> pipelines -> {$self -> _get_head} -> transform($iterator);
    }, $self -> options;
}

sub _dup_iterator {
    my($self, $it) = @_;

    return $it -> duplicate if is_Iterator( $it );
    return to_Iterator( $it );
}


1;

__END__

=head1 NAME

Data::Machines - Manage a set of data pipelines

=head1 SYNOPSIS

 use Data::Machines qw( Pipeline );

 my $m = Data::Machine -> new;

 $m -> add_pipeline( foo => $pipeline );

 $m -> add_source( bar => $source );

 $m -> add_connection( bar => foo );

 my $iterator = $m -> transform( 'foo' => { additional sources } );

# $iterator is now a Data::Pipeline::Iterator that can be fed into
# another machine or pipeline

 # for pipelines that map
 my $output = $m -> transform( $input );

 # for pipelines that  reduce
 $m -> start;
 $m -> add( $input );
 my $output = $m -> finish;

=head1 DESCRIPTION
