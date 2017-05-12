package DB::Pluggable::Role::AfterInit;
use strict;
use warnings;
use 5.010;
use Role::Basic;
with qw(Brickyard::Role::Plugin);
requires qw(afterinit);
our $VERSION = '1.112001';
1;

=pod

=for stopwords afterinit

=head1 NAME

DB::Pluggable::Role::AfterInit - Do something in the debugger's afterinit() function

=head1 IMPLEMENTING

The C<AfterInit> role indicates that a plugin wants to do something
during the debugger's C<afterinit()> function. The plugin must provide
the C<afterinit()> method.
