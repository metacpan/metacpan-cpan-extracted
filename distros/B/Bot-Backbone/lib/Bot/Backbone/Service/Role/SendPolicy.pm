package Bot::Backbone::Service::Role::SendPolicy;
$Bot::Backbone::Service::Role::SendPolicy::VERSION = '0.161950';
use v5.10;
use Moose::Role;

with 'Bot::Backbone::Service::Role::Sender';

# ABSTRACT: Provides send policy framework to a service


has send_policy_name => (
    is          => 'ro',
    isa         => 'Str',
    init_arg    => 'send_policy',
    predicate   => 'has_send_policy',
);


has send_policy => (
    is          => 'ro',
    does        => 'Bot::Backbone::SendPolicy',
    init_arg    => undef,
    lazy_build  => 1,

    # lazy_build implies (predicate => has_send_policy)
    predicate   => 'has_setup_the_send_policy',
);

sub _build_send_policy {
    my $self = shift;
    my $send_policy = $self->bot->meta->send_policies->{ $self->send_policy_name };

    die "no such send policy as ", $self->send_policy_name, "\n"
        unless defined $send_policy;

    Bot::Backbone::SendPolicy::Aggregate->new(
        bot    => $self->bot,
        config => $send_policy,
    );
}


requires qw( send_message );

around send_message => sub {
    my ($next, $self, $params) = @_;

    my $send_policy_result = $params->{send_policy_result} // { allow => 1 };
    my $send_policy        = $params->{send_policy};

    $send_policy_result->{after} //= 0;

    _apply_send_policy($send_policy, $send_policy_result, $params)
        if defined $send_policy;

    _apply_send_policy($self->send_policy, $send_policy_result, $params)
        if $self->has_send_policy;

    return unless $send_policy_result->{allow};

    # If this is a bare metal chat... then apply any required delay
    if (($send_policy_result->{after} // 0) > 0
            and $self->does('Bot::Backbone::Service::Role::BareMetalChat')) {

        # Setting Timer
        my $w = AnyEvent->timer(
            after => $send_policy_result->{after},
            cb    => sub { $self->$next($params) },
        );

        $self->_enqueue_message($w);

        return;
    }

    # Allowed and no delays... so GO!
    $self->$next($params);
};

sub _apply_send_policy {
    my ($send_policy, $send_policy_result, $options) = @_;

    my $new_result = $send_policy->allow_send($options);

    $send_policy_result->{allow} &&= $new_result->{allow};

    $send_policy_result->{after} = $new_result->{after}
        if ($new_result->{after} // 0) > $send_policy_result->{after};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::Role::SendPolicy - Provides send policy framework to a service

=head1 VERSION

version 0.161950

=head1 SYNOPSIS

  package Bot::Backbone::Service::RandomGibberish;
  use v5.14;
  use Bot::Backbone::Service;

  with qw(
      Bot::Backbone::Service::Role::Service
      Bot::Backbone::Service::Role::SendPolicy
  );

  use List::Util qw( shuffle );

  # Post to a random chat
  sub send_message {
      my ($self, $params) = @_;

      my @chats = grep { $_->does('Bot::Backbone::Service::Role::Chat') }
                         $self->bot->list_services;

      my ($chat) = shuffle @chats;
      $chat->send_message($params);
  }

  # ... whatever else this insane service does ...

=head1 DESCRIPTION

This role is used to apply send policies to
L<Bot::Backbone::Service::Role::Chat>,
L<Bot::Backbone::Service::Role::ChatConsumer>, and
L<Bot::Backbone::Service::Role::Dispatch> services. If you have a service that
is none of those, but would like to have a send policy applied to anything it
may send to a chat, you may define a C<send_message> method and then apply this
role.

=head1 ATTRIBUTES

=head2 send_policy_name

This is the name of the send policy to apply to this service. It is set using
the C<send_policy> setting in the service configuration. It will be used to set
L</send_policy>, if any policy is set.

=head2 send_policy

This is the L<Bot::Backbone::SendPolicy> that has been selected for this
service.

=head1 REQUIRED METHODS

=head2 send_message

This role requires a C<send_mesage> method be present that works just the same
as the one required in L<Bot::Backbone::Service::Role::Chat>. This role will
modify that method to apply the L</send_policy> to calls to that method.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
