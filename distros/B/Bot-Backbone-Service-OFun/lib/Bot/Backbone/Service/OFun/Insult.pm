package Bot::Backbone::Service::OFun::Insult;
$Bot::Backbone::Service::OFun::Insult::VERSION = '0.142230';
use Bot::Backbone::Service;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Responder
);

use Acme::Scurvy::Whoreson::BilgeRat;

# ABSTRACT: Ask the bot to insult your friends, enemies, and applications


service_dispatcher as {
    command '!insult' => given_parameters {
        parameter 'thing' => ( match_original => qr/.+/ );
    } respond_by_method 'insult_the_thing';
};


has language => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'pirate',
);


has insult_generator => (
    is          => 'ro',
    isa         => 'Acme::Scurvy::Whoreson::BilgeRat',
    lazy_build  => 1,
);

sub _build_insult_generator {
    my $self = shift;
    my $language = $self->language;

    return Acme::Scurvy::Whoreson::BilgeRat->new(
        language => $language,
    );
}


sub insult_the_thing {
    my ($self, $message) = @_;

    my $thing = $message->parameters->{thing};

    my $insult = ''.$self->insult_generator;
    my $a = $insult =~ /^[aeiou]/i ? 'an' : 'a';
    return "$thing is $a $insult.";
}


sub initialize { }

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::OFun::Insult - Ask the bot to insult your friends, enemies, and applications

=head1 VERSION

version 0.142230

=head1 SYNOPSIS

    # in your bot config
    service insult => (
        service  => 'OFun::Insult',
        language => 'pirate',
    );

    dispatcher chatroom => as {
        redispatch_to 'insult';
    };

    # in chat
    alice> !insult bob
    bot> bob is a scurvy potvaliant

=head1 DESCRIPTION

Sometimes it's best to relieve stress by calling your friends and coworkers names. However, doing so directly is awkward and might lead to one of those meetings with the manager where words like "disappointment" and "failed expectations" might be uttered.

So, why not have a bot that can insult them for you instead? Why that's a great idea, I'm glad you suggested it because here it is!

=head1 DISPATCHER

=head2 !insult

    !insult person, place, or thing

The bot will provide an appropriate (or inappropriate) insult to the person, place, or thing given as an argument. The insult used depends entirely on the insult language used.

=head1 ATTRIBUTES

=head2 language

This bot service doesn't actually generate its insults. Instead, it relies upon L<Acme::Scurvy::Whoreson::BilgeRat> to do that for us. That module doesn't generate its own insults directly either (seeing a pattern yet?). It depends on a backend. Those backends are called "languages" for some inexplicable reason. 

The default is "pirate" which ships with the Acme module itself, but you can install other ones or, better, write your own using your organization's own glossary of insults. See that module for directions on how to do that.

=head2 insult_generator

This is the actual reference to the L<Acme::Scurvy::Whoreson::BilgeRat> that we use to generate the insults. This is created automatically.

=head1 METHODS

=head2 insult_the_thing

This implements the the C<!insult> command.

=head2 initialize

No op.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
