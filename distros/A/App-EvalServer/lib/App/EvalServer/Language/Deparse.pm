package App::EvalServer::Language::Deparse;
BEGIN {
  $App::EvalServer::Language::Deparse::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $App::EvalServer::Language::Deparse::VERSION = '0.08';
}

use strict;
use warnings;
use B::Deparse;

sub evaluate {
    my ($package, $code) = @_;

    my $sub = eval "no strict; no warnings; sub{ $code\n }";

    print STDERR $@ if length($@);
    my $dp = B::Deparse->new(qw<-p -q -x7>);
    my $ret = $dp->coderef2text($sub);

    $ret =~ s/\{//;
    $ret =~ s/package (?:\w+(?:::)?)+;//;
    $ret =~ s/ no warnings;//;
    $ret =~ s/\s+/ /g;
    $ret =~ s/\s*\}\s*$//;
    $ret =~ s/^\s*//;

    return $ret;
}

1;

=encoding utf8

=head1 NAME

App::EvalServer::Language::Deparse - Deparse Perl code with B::Deparse

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
