package App::EvalServer::Language::Python;
BEGIN {
  $App::EvalServer::Language::Python::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $App::EvalServer::Language::Python::VERSION = '0.08';
}

use strict;
use warnings;
use Inline::Python qw<py_eval>;

sub evaluate {
    my ($package, $code) = @_;
    return py_eval($code, 2);
}

1;

=encoding utf8

=head1 NAME

App::EvalServer::Language::Python - Evaluate Python code

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
