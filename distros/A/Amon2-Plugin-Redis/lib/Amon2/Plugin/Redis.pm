package Amon2::Plugin::Redis;
use 5.008001;
use strict;
use warnings;
use Redis;

our $VERSION = "0.04";

sub init {
    my ($class, $context) = @_;
    no strict 'refs';
    *{"$context\::redis"} = \&_redis;
}

sub _redis {
    my ($self,) = @_;

    if (!exists $self->{redis}) {
        $self->{redis} = Redis->new(%{ $self->config->{Redis} || +{} });
    }
    $self->{redis};
}


1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Plugin::Redis - for enabling it to treat simply


=head1 SYNOPSIS

    # MyApp.pm
    __PACKAGE__->load_plugin('Redis');

    $c->redis->set(test => 'hoge');

=head1 DESCRIPTION

Amon2::Plugin::Redis is  for enabling it to treat simply

=head1 LICENSE

Copyright (C) meru_akimbo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

meru_akimbo E<lt>merukatoruayu0@gmail.comE<gt>

=cut

