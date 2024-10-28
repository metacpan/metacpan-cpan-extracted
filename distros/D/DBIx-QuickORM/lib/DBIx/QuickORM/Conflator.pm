package DBIx::QuickORM::Conflator;
use strict;
use warnings;

our $VERSION = '0.000004';

use Scalar::Util qw/blessed/;
use Carp qw/confess/;

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Conflator';

use DBIx::QuickORM::Util::HashBase qw{
    <name
    +inflate
    +deflate
};

sub init {
    my $self = shift;

    $self->{+NAME} //= do { my @caller = caller(1); "$caller[1] line $caller[2]" };

    my $inflate = $self->{+INFLATE} or confess "The 'inflate' attribute is required";
    my $deflate = $self->{+DEFLATE} or confess "The 'deflate' attribute is required";

    confess "The 'inflate' attribute must be a coderef, got '$inflate'" unless ref($inflate) eq 'CODE';
    confess "The 'deflate' attribute must be a coderef, got '$deflate'" unless ref($deflate) ne 'CODE';
}

sub qorm_inflate { shift->{+INFLATE}->(@_) }
sub qorm_deflate { shift->{+DEFLATE}->(@_) }

1;
