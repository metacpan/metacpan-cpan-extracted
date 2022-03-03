package Cassandra::Client::Policy::Queue::Default;
our $AUTHORITY = 'cpan:TVDW';
$Cassandra::Client::Policy::Queue::Default::VERSION = '0.19';
use 5.010;
use strict;
use warnings;

sub new {
    my ($class, %args)= @_;

    my $max_entries= $args{max_entries} || 0; # Default: never overflow

    return bless {
        max_entries => 0+ $max_entries,
        has_any     => 0, # We're using this as a count.
        queue       => [],
    }, $class;
}

sub enqueue {
    my ($self, $item)= @_;

    if ($self->{max_entries} && $self->{has_any} >= $self->{max_entries}) {
        return "command queue full: $self->{has_any} entries";
    }

    push @{$self->{queue}}, $item;
    $self->{has_any}++;
    return;
}

sub dequeue {
    my ($self)= @_;
    my $item= shift @{$self->{queue}};
    $self->{has_any}= 0+@{$self->{queue}};
    return $item;
}

1;

__END__

=pod

=head1 NAME

Cassandra::Client::Policy::Queue::Default

=head1 VERSION

version 0.19

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
