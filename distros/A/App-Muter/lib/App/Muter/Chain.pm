package App::Muter::Chain;
# ABSTRACT: main programmatic interface to muter
$App::Muter::Chain::VERSION = '0.003000';
use strict;
use warnings;

use List::Util ();


sub new {
    my ($class, $chain, $reverse) = @_;
    $class = ref($class) || $class;
    my $self = bless {}, $class;
    $self->{chain} =
        [$self->_instantiate($self->_parse_chain($chain, $reverse))];
    return $self;
}


sub process {
    my ($self, $data) = @_;

    return List::Util::reduce { $b->process($a) } $data, @{$self->{chain}};
}


sub final {
    my ($self, $data) = @_;

    return List::Util::reduce { $b->final($a) } $data, @{$self->{chain}};
}

sub _chain_entry {
    my ($item, $reverse) = @_;
    if ($item =~ /^(-?)(\w+)(?:\(([^)]+)\))?$/) {
        return {
            name   => $2,
            method => (($1 xor $reverse) ? 'decode' : 'encode'),
            args   => ($3 ? [split /,/, $3] : []),
        };
    }
    elsif ($item =~ /^(-?)(\w+),([^)]+)$/) {
        return {
            name   => $2,
            method => (($1 xor $reverse) ? 'decode' : 'encode'),
            args   => ($3 ? [split /,/, $3] : []),
        };
    }
    else {
        die "Chain entry $item is invalid";
    }
}

sub _parse_chain {
    my (undef, $chain, $reverse) = @_;
    my @items = split /:/, $chain;
    my @chain = map { _chain_entry($_, $reverse) } @items;
    return $reverse ? reverse @chain : @chain;
}

sub _instantiate {
    my (undef, @entries) = @_;
    my $registry = App::Muter::Registry->instance;
    return map {
        my $class = $registry->info($_->{name})->{class};
        $class->new($_->{args}, transform => $_->{method});
    } @entries;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Muter::Chain - main programmatic interface to muter

=head1 VERSION

version 0.003000

=head1 SYNOPSIS

    App::Muter::Registry->instance->load_backends();
    my $chain = App::Muter::Chain->new($chain);
    while (<$fh>) {
        print $chain->process($_);
    }
    print $chain->final('');

=head1 DESCRIPTION

This is the main programmatic (Perl) interface to muter.  It takes an arbitrary
chain and processes data incrementally, in whatever size chunks it's given.

=head1 METHODS

=head2 $class->new($chain, [$reverse])

Create a new chain object using the specified chain, which is identical to the
argument to muter's B<-c> option.  If C<$reverse> is passed, reverse the chain,
as with muter's <-r> option.

=head2 $self->process($data)

Process a chunk of data.  Chunks need not be all the same size.  Returns the
transformed data, which may be longer or shorter than the input data.

=head2 $self->final($data)

Process the final chunk of data.  If all the data has already been sent via the
I<process> method, simply pass an empty string.

=head1 AUTHOR

brian m. carlson <sandals@crustytoothpaste.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016–2017 by brian m. carlson.

This is free software, licensed under:

  The MIT (X11) License

=cut
