package App::EvalServer::Language::PHP;
BEGIN {
  $App::EvalServer::Language::PHP::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $App::EvalServer::Language::PHP::VERSION = '0.08';
}

use strict;
use warnings;
use PHP::Interpreter;

sub evaluate {
    my ($package, $code) = @_;
    return php_code($code);
}

1;

=encoding utf8

=head1 NAME

App::EvalServer::Language::PHP - Evaluate PHP code

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
