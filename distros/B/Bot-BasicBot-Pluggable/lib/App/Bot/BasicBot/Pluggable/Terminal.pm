package App::Bot::BasicBot::Pluggable::Terminal;
$App::Bot::BasicBot::Pluggable::Terminal::VERSION = '1.30';
use Moose;
use Bot::BasicBot::Pluggable::Terminal;
extends 'App::Bot::BasicBot::Pluggable';

has '+bot_class' => ( default => 'Bot::BasicBot::Pluggable::Terminal' );

1;

__END__

=head1 NAME 

App::Bot::BasicBot::Pluggable::Terminal

=head1 VERSION

version 1.30

=head1 SYNOPSIS

App::Bot::BasicBot::Pluggable::Terminal->new()->run();

=head1 DESCRIPTION

This subclass of L<App::Bot::BasicBot::Pluggable> just alters the
default bot class to L<Bot::BasicBot::Pluggable::Terminal>. Nothing
fance here.

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
