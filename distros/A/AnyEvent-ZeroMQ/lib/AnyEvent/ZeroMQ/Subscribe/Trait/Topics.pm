package AnyEvent::ZeroMQ::Subscribe::Trait::Topics;
BEGIN {
  $AnyEvent::ZeroMQ::Subscribe::Trait::Topics::VERSION = '0.01';
}
# ABSTRACT: trait to parse messages and extract the topic
use Moose::Role;
use true;
use namespace::autoclean;

requires '_topics_changed';
requires '_call_callback'; # cb, item, rest -> cb, item, topic, rest

has 'topic_regex' => (
    reader     => 'topic_regex',
    isa        => 'RegexpRef',
    lazy_build => 1,
);

after '_topics_changed' => sub {
    my $self = shift;
    $self->clear_topic_regex;
};

sub _build_topic_regex {
    my $self = shift;
    my @prefixes = map { quotemeta } $self->topics->members;
    my $prefixes = join '|', @prefixes;
    return qr/^($prefixes)(.*)$/;
}

around '_call_callback' => sub {
    my ($orig, $self, $cb, @rest) = @_;
    $self->$orig( sub {
        my ($self, $item, @rest) = @_;
        my $tr = $self->topic_regex;
        if(my ($topic, $item) = ($item =~ /$tr/)){
            $cb->($self, $item, $topic, @rest);
        }
        else {
            # should not happen
            $cb->($self, $item, undef,  @rest);
        }
    }, @rest);

};

__END__
=pod

=head1 NAME

AnyEvent::ZeroMQ::Subscribe::Trait::Topics - trait to parse messages and extract the topic

=head1 VERSION

version 0.01

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

