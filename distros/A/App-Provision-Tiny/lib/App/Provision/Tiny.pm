package App::Provision::Tiny;
BEGIN {
  $App::Provision::Tiny::AUTHORITY = 'cpan:GENE';
}

# ABSTRACT: Provision computers

use strict;
use warnings;

use File::Which;

our $VERSION = '0.0402';



sub new
{
    my $class = shift;
    my %args = @_;
    my $self = {};
    bless $self, $class;
    $self->_init(%args, class => $class);
    return $self;
}

sub _init
{
    my $self = shift;
    my %args = @_;

    # Turn arguments into object attributes.
    $self->{$_} = $args{$_} || undef for keys %args;

    # Set the system to provision.
    $self->{system} ||= 'osx';

    # Set the program to provision on the system.
    unless ($self->{program})
    {
        $self->{class} =~ s/App::Provision::(\w+)$/$1/;
        $self->{program} = lc $self->{class};
    }
}


sub condition
{
    my $self = shift;
    my $callback = shift || sub { which($self->{program}) };
    my $condition = $callback->();
    warn "$self->{program} ", ($condition ? 'is' : "isn't"), " installed\n";
    return $condition ? 1 : 0;
}


sub recipe
{
    my $self = shift;
    my @steps = @_;
    $self->system_install(@steps) if $self->{force} || !$self->condition;
}


sub system_install
{
    my $self = shift;
    my @commands = @_;
    for my $cmd (@commands)
    {
        #warn "CMD: @$cmd\n";
        system(@$cmd) == 0 or warn "system @$cmd failed: $?";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Provision::Tiny - Provision computers

=head1 VERSION

version 0.0402

=head1 SYNOPSIS

  # With the module:
  use App::Provision::Foo;
  $foo = App::Provision::Foo->new;
  print join(', ', $foo->deps), "\n"; # Just for info, currently
  $foo->meet;

  # Command line examples:
  > provis wget
  > provis ssh --keytype dsa --keyname github
  > provis foundation --release x.y.z --site /the/www/site/root

=head1 DESCRIPTION

An C<App::Provision::Tiny> together with a sub-classed recipe module (like
C<Foo>), contain the methods to provision a workstation or server.

* Currently, the included recipes are for B<homebrew> or B<apt> based machines.

=head1 METHODS

=head2 new()

  $app = App::Provision::Tiny->new(%arguments);

Create a new C<App::Provision::Tiny> object.

Argument: default

 system:  osx
 program: undef
 release: undef
 repo:    undef
 site:    undef
 keytype: undef
 keyname: undef

=head2 condition()

This is the condition to check for the presence of a program, and should be
redefined in your subclass, if anything beyond a simple C<`which program`>
is needed.

=head2 recipe()

This is the actual set of steps to take to check for and install a program, and
should be used, or redefined, in your subclass, in the C<meet()> method.

The steps can be simple system (i.e. "shell") commands or complex perl.
By default, this base recipe uses the C<system_install()> method.

=head2 system_install()

Use a simple C<system(@command)> function to install the program.

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
