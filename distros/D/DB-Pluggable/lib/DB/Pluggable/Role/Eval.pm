package DB::Pluggable::Role::Eval;
use strict;
use warnings;
use 5.010;
use Role::Basic;
with qw(Brickyard::Role::Plugin);
requires qw(eval);
our $VERSION = '1.112001';
1;

=pod

=head1 NAME

DB::Pluggable::Role::Eval - Do something in the debugger's eval() function

=head1 IMPLEMENTING

The C<Eval> role indicates that a plugin wants to do something during
the debugger's C<eval()> function. The plugin must provide the
C<eval()> method.
