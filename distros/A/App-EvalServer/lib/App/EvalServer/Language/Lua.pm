package App::EvalServer::Language::Lua;
BEGIN {
  $App::EvalServer::Language::Lua::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $App::EvalServer::Language::Lua::VERSION = '0.08';
}

use strict;
use warnings;
use Inline Lua => 'function lua_eval(str) return loadstring(str) end';

sub evaluate {
    my ($package, $code) = @_;
    my $ret = lua_eval($code);
    return ref $ret ? $ret->() : $ret;
}

1;

=encoding utf8

=head1 NAME

App::EvalServer::Language::Lua - Evaluate Lua code

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
