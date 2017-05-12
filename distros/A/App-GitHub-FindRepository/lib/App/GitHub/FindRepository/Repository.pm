package App::GitHub::FindRepository::Repository;

use warnings;
use strict;

use Scalar::Util qw/blessed/;

use constant PUBLIC_PREFIX => 'git://github.com/';
use constant PRIVATE_PREFIX => 'git@github.com:';

use overload
    '""' => \&url,
    fallack => 1,
;

{
    no strict 'refs';
    for my $attribute (qw/prefix origina base/) {
        *$attribute = sub {
            my $self = shift;
            return $self->{$attribute} unless @_;
            return $self->{$attribute} = shift;
        };
    }
}

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub parse {
    my $class = shift;
    my $repository = shift;

    return $repository if blessed $repository && $repository->isa( __PACKAGE__ );

    return unless $repository;

    my $base = $repository;
    $base =~ s/ //g;
    $base =~ s/,/\//g;
    $base =~ s!^\s*((?:\w+[:/@]+)?github\.com(?:[:/]))!!;
    my $prefix = $1;
    $base =~ s/\.git$//;

    return unless $base;

    return $class->new( prefix => $prefix, base => $base, original => $repository );
}

sub name {
    my $self = shift;
    my $name = $self->base;
    $name =~ s!^.*/+!!;
    return $name
}

sub url {
    my $self = shift;
    return join '', ($self->prefix || PUBLIC_PREFIX), $self->base, '.git'
}

sub test {
    my $self = shift;
    return $self->public;
}

sub public {
    my $self = shift;
    return join '', PUBLIC_PREFIX, $self->base, '.git';
}

sub private {
    my $self = shift;
    return join '', PRIVATE_PREFIX, $self->base, '.git';
}

sub home {
    my $self = shift;
    return join '', 'http://github.com/', $self->base;
}

1;
