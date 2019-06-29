package App::TeleGramma::BotAction;
$App::TeleGramma::BotAction::VERSION = '0.14';
# ABSTRACT: A base class for bot actions

use Mojo::Base -base;

sub can_listen { 0 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TeleGramma::BotAction - A base class for bot actions

=head1 VERSION

version 0.14

=head1 AUTHOR

Justin Hawkins <justin@hawkins.id.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins <justin@eatmorecode.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
