package DB::Pluggable::Role::WatchFunction;
use strict;
use warnings;
use 5.010;
use Role::Basic;
with qw(Brickyard::Role::Plugin);
requires qw(watchfunction);
our $VERSION = '1.112001';
1;

=pod

=for stopwords watchfunction

=head1 NAME

DB::Pluggable::Role::WatchFunction - Do something during the debugger's watchfunction()

=head1 IMPLEMENTING

The C<WatchFunction> role indicates that a plugin wants to do
something during the debugger's C<watchfunction()> function. The
plugin must provide the C<watchfunction()> method.
