package Data::Collector::Engine;
{
  $Data::Collector::Engine::VERSION = '0.15';
}
# ABSTRACT: A base class for collecting engines

use Moose;
use namespace::autoclean;

with 'Data::Collector::Commands';

has 'name'      => ( is => 'ro', isa => 'Str' );
has 'connected' => (
    is        => 'rw',
    isa       => 'Bool',
    default   => 0,
);

# basic overridable methods
sub run         { die 'No default run method' }
sub connect     {1}
sub disconnect  {1}

sub file_exists {
    my ( $self, $file ) = @_;
    my $test   = $self->get_command('test');
    my $echo   = $self->get_command('echo');
    my $cmd    = "$test -f $file ; $echo \$?";
    my $result = $self->run($cmd);
    $result == 0 and return 1;

    return 0;
}

sub run_if_exists {
    my ( $self, $cmd, $opts ) = @_;
    if ( $self->file_exists($cmd) ) {
        $self->run("$cmd $opts");
    }
}

__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

Data::Collector::Engine - A base class for collecting engines

=head1 VERSION

version 0.15

=head1 SYNOPSIS

This synopsis shows how to write an (almost) full-fledged Telnet engine for
L<Data::Collector>.

    package Data::Collector::Engine::Telnet;

    use Moose;
    use Net::Telnet;
    use namespace::autoclean; # general recommendation
    extends 'Data::Collector::Engine';

    has 'host'   => ( is => 'ro', isa => 'Str',         required   => 1 );
    has 'telnet' => ( is => 'ro', isa => 'Net::Telnet', lazy_build => 1 );

    has '+name'  => ( default => 'Telnet' );

    sub _build_telnet {
        my $self   = shift;
        my $telnet = Net::Telnet->new();
    }

    sub connect {
        my $self = shift;
        $self->telnet->open( $self->host );
        $self->telnet->login(...);
    }

    sub run {
        my ( $self, $command ) = @_;
        my $telnet = $self->telnet;
        my @lines  = $telnet->cmd($command);
        ...
    }

    sub disconnect { ... }

While we all hate long synopsises, this is the best way to demonstrate how
L<Data::Collector::Engine> works. You'll see we made a new engine that inherits
from this base class. We create a I<connect>, I<run> and I<disconnect>.

=head1 ATTRIBUTES

=head2 name(Str)

This has no default, but should be set. It is currently not used, but it might
in the future. It's important that every engine has its own name.

With L<Moose> goodness you can just change the value this way:

    has '+name' => ( default => 'MyEngine' );

=head2 connected(Bool)

A boolean to declare whether the engine is connected or not. This is in place
because engine are most likely to be connection-based (network, DB, etc.). The
I<connect> or I<disconnect> method calling is dependent on this boolean.

=head1 SUBROUTINES/METHODS

=head2 connect

This method gets called before the I<run> method, to allow your engine to
connect to wherever it needs.

This is also called in a lazy context, which means it will not be called on
load but as close as possible to whenever the engine is needed.

At this point you would probably want to set the I<connected> boolean attribute
on. Read more below under I<disconnect>.

=head2 disconnect

A I<disconnect> is attempted if the I<connected> boolean is set.

=head2 run

This is the main method of the engine. The arguments are populated by the info
component. It may be a command to run, it may be something else. While there
should be an API of argument types and indicating support for them, there isn't
one at the moment. This should change.

If you do not provide a run method, your engine will die, literally! :)

=head2 file_exists

Tries to run C<test -f file ; echo $?> to check if a file exists. You can
subclass it if you're doing it differently (or don't want to support it).

    $engine->check_files('file');

=head2 run_if_exists

A helper hybrid between C<file_exists> and C<run> to ease a common idiom:

    # instead of this:
    if ( $engine->file_exists($cmd) ) {
        $engine->run("$cmd $opts");
    }

    # do this:
    $engine->run_if_exists("$cmd $opts");

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

