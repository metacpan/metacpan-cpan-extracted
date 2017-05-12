package Catalyst::Plugin::Moostash;

use warnings;
use strict;

use MRO::Compat;
use Module::Load;

use version 0.77; our $VERSION = version->declare('v0.1.2');

# ABSTRACT: Provides Moose interface for stash

sub moostash {
    my $c = shift;

    my $config    = $c->config->{'Plugin::Moostash'};
    my $stash_key = $config->{stash_key} || 'm';
    my $class     = $config->{class} || join('::', ref($c), 'Moostash');

    if (not defined $c->stash->{$stash_key}) {
        load $class;    ## Module::Load
        $c->stash->{$stash_key} = $class->new(ctx => $c);
    }

    return $c->stash->{$stash_key};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::Moostash - Provides Moose interface for stash

=head1 VERSION

version v0.1.2

=head1 DESCRIPTION

Define your Moostash class:

 package MyApp::Moostash;

 use Moose;
 extends 'Catalyst::Plugin::Moostash::Base';

 has user_id => (
     is     => 'ro',
     isa    => 'Int',
     writer => 'set_user_id',
 );

Load plugin in MyApp class:

 use Catalyst qw/
     ConfigLoader
     Static::Simple
     ...
     Moostash
 /;

Then use it in your application:

 sub some_action : Local {
     my ($self, $c) = @_;

     $c->moostash->set_user_id($user_id);
 }

Since the Moostash object is stored in the stash, you can conveniently access it
from your View:

 [% m.user_id %]

Also, note that Moostash object receives Catalyst context object into the C<ctx>
attribute.

=head1 CONFIGURATION

 __PACKAGE__->config(
     'Plugin::Moostash' => {
         stash_key => 'm',
         class => 'MyApp::Moostash',
     },
 );

=head2 stash_key

Defines which stash key to use for storing Moostash object.

Default: C<m>

=head2 class

Defines Moostash class name.

Default: C<MyApp::Moostash>

=head1 AUTHOR

Roman F. <romanf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roman F..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
