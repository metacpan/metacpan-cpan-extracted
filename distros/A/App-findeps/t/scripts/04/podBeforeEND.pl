use strict;
use warnings;

=encoding utf-8

=head1 NAME

it's a dummy POD for testing

=head1 SYNOPSIS

Via the command-line program L<findeps>;

    require Module::Exists::In::POD;
    use Module::Exists::In::POD::Else;
    use parent qw( Module::Exists::In::POD );

=head1 DESCRIPTION

Nothing to explain.

=head1 LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida(L<worthmine|https://github.com/worthmine>)

=cut

require Acme::BadExample;    # does not exist anywhere

