package Bot::Backbone::SendPolicy::Aggregate;
$Bot::Backbone::SendPolicy::Aggregate::VERSION = '0.161950';
use v5.10;
use Moose;

with 'Bot::Backbone::SendPolicy';

# ABSTRACT: Pull several send policies together


has config => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    traits      => [ 'Array' ],
    handles     => {
        'config_pairs' => 'elements',
    },
);


has policies => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    lazy_build  => 1,
    traits      => [ 'Array' ],
    handles     => {
        'all_policies' => 'elements',
    },
);

sub _build_policies {
    my $self = shift;

    my @policies;
    for my $config_pair ($self->config_pairs) {
        my ($class_name, $policy_config) = @$config_pair;
        push @policies, $class_name->new(%$policy_config, bot => $self->bot);
    }

    return \@policies;
}


sub allow_send {
    my ($self, $options) = @_;

    my $final_result = { allow => 1, after => 0 };
    POLICY: for my $policy ($self->all_policies) {
        my $result = $policy->allow_send($options);

        $final_result->{allow} &&= $result->{allow};
        $final_result->{after}   = $result->{after}
            if ($result->{after} // 0) > $final_result->{after};

        last POLICY unless $final_result->{allow};
    }

    # Don't need after if there's no delay or if allow is false
    delete $final_result->{after} if $final_result->{after} <= 0
                                  or not $final_result->{allow};

    return $final_result;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::SendPolicy::Aggregate - Pull several send policies together

=head1 VERSION

version 0.161950

=head1 DESCRIPTION

You probably don't need to worry about this policy directly. Simply by defining a policy using the C<send_policy> helper loaded by L<Bot::Backbone>, you will end up using this to mix them together.

Basically, this just provides tools for configuring multiple policies and makes sure that the most restrictive policies win.

=head1 ATTRIBUTES

=head2 config

This is the send policy configuration to use.

=head2 policies

This is the list of L<Bot::Backbone::SendPolicy> objects to apply. These are built automatically based upon L</config>.

=head1 METHODS

=head2 allow_send

Applies all the L</policies> to the message and returns the most restrictive send policy results.

This does perform short circuiting

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
