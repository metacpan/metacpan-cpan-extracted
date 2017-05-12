package Data::Collector;
{
  $Data::Collector::VERSION = '0.15';
}
# ABSTRACT: Collect information from multiple sources

use Carp;
use Moose;
use MooseX::Types::Set::Object;
use Module::Pluggable::Object;
use Class::Load 'try_load_class';
use namespace::autoclean;

has 'format'        => ( is => 'ro', isa => 'Str',     default => 'JSON'     );
has 'format_args'   => ( is => 'ro', isa => 'HashRef', default => sub { {} } );
has 'engine'        => ( is => 'ro', isa => 'Str',     default => 'OpenSSH'  );
has 'engine_args'   => ( is => 'ro', isa => 'HashRef', default => sub { {} } );
has 'info_args'     => ( is => 'ro', isa => 'HashRef', default => sub { {} } );
has 'engine_object' => (
    is         => 'ro',
    isa        => 'Object',
    lazy_build => 1,
);

has 'data' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { {} },
);

has 'infos' => (
    is       => 'ro',
    isa      => 'Set::Object',
    coerce   => 1,
    default  => sub { Set::Object->new },
);

has 'exclude_infos' => (
    is       => 'ro',
    isa      => 'Set::Object',
    coerce   => 1,
    default  => sub { Set::Object->new },
);

has 'os' => (
    is        => 'rw',
    isa       => 'Str',
    trigger   => sub { shift->load_os(@_) },
    predicate => 'has_os',
);

sub _build_engine_object {
    my $self  = shift;
    my $type  = $self->engine;
    my $class = "Data::Collector::Engine::$type";

    my ( $res, $reason ) = try_load_class($class);
    $res or die "Can't load engine: $reason\n";

    return $class->new( %{ $self->engine_args } );
}

sub BUILD {
    my $self = shift;

    if ( ! $self->has_os ) {
        # default if not run by App.pm
        $self->os('CentOS');
    }
}

sub load_os {
    my ( $self, $new_os, $old_os ) = @_;
}

sub collect {
    my $self   = shift;
    my $engine = $self->engine_object;

    # lazy calling the connect
    if ( ! $engine->connected ) {
        $engine->connect;
        $engine->connected(1);
    }

    my $object = Module::Pluggable::Object->new(
        search_path => 'Data::Collector::Info',
        require     => 1,
    );

    foreach my $class ( $object->plugins ) {
        $self->load_info($class);
    }

    if ( $engine->connected ) {
        $engine->disconnect;
        $engine->connected(0);
    }

    return $self->serialize;
}

sub load_info {
    my ( $self, $class ) = @_;

    my @levels = split /\:\:/, $class;
    my $level  = $levels[-1];

    if ( $self->infos->members ) {
        # we got specific infos requested
        if ( ! $self->infos->has($level) ) {
            # this info is not on the infos list
            return;
        }
    }

    if ( $self->exclude_infos->has($level) ) {
        # this info is on the exclusion list
        return;
    }

    my $info = $class->new(
        engine => $self->engine_object,
        %{ $self->info_args->{ lc $level } },
    );

    my %data = %{ $info->all() };

    %data and $self->data( {
        %{ $self->data },
        %data,
    } );
}

sub serialize {
    my $self   = shift;
    my $format = $self->format;
    my $class  = "Data::Collector::Serializer::$format";

    eval "use $class";
    $@ && die "Can't load serializer '$class': $@";

    my $serializer = $class->new( %{ $self->format_args } );

    return $serializer->serialize( $self->data );
}

sub clear_registry { Data::Collector::Info->clear_registry }

__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

Data::Collector - Collect information from multiple sources

=head1 VERSION

version 0.15

=head1 SYNOPSIS

Data::Collector collects various information from multiple sources and makes it
available in different formats, similar to Puppet's Facter.

    use Data::Collector;

    my $collector = Data::Collector->new(
        engine      => 'OpenSSH', # default
        engine_args => { password => read_password('Pass: ') },
        format      => 'JSON', # default
    );

    my %data = $collector->collect;
    ...

Data::Collector uses I<Info>s to determine what information is collected. It
then uses I<Serialize>rs to serialize that information.

An important concept in Data::Collector is that it does not use any modules to
fetch the information, only shell commands. This might seem like a pain at first
but it allows it to be run on remote machines without any RPC server/client
set up. It might be changed in the future, but (at least now) it seems unlikely.

The main purpose of Data::Collector is to facilitate an information gatherning
subsystem, much like Puppet's Facter, to be used in system monitoring and
administration.

However, Data::Collector is much more dynamic. It supports any number of engines
and formats. Thus, it can be used for push or pull situations, can work with
monitoring systems, integrate with testing suites and otherwise a pretty wide
variety of situations.

=head1 ATTRIBUTES

=head2 engine(Str)

The engine that will be used to collect the information. This is the underlying
layer that will gather the information. The default is OpenSSH, you can use
any other one you want and even create your own.

By implementing your own, you can have fetching done via database queries,
online searching, local system commands or even telnet, if that's what you're
using.

=head2 engine_args(HashRef)

Any arguments that the engine might need. These are passed to the engine's
I<new> method. Other than making sure it's a hash reference, the value is not
checked and is left for the engine's discression.

L<Data::Collector::Engine::OpenSSH> requires a I<host>, and allows a I<user>
and I<passwd>.

=head2 format(Str)

This is the format in which you want the information. This will most likely
refer to the serializer you want, but it doesn't have to be. For example,
you could implement your own I<Serializer> which will actually be a module
to push all the changes you want in a database you have.

The default is JSON.

=head2 format_args(HashRef)

Much like I<engine_args>, you can supply any additional arguments that will
reach the serializer's I<new> method.

=head2 info_args(HashRef)

Much like I<engine_args> and I<info_args>, you can supply any additional
arguments that should go to specific Info module's I<new> method.

    info_args => {
        IFaces => {
            ignore_ip    => ['127.0.0.1'],
            ignore_iface => ['lo'],
        },
    },

=head2 data(HashRef)

While (and post) collecting, this attribute contains all the information
[being] gathered. It is this data that is sent to the serializer in order
to do whatever it wants with it.

=head2 engine_object(Object)

This attributes holds the engine object. This should probably be left for
either testing or advanced usage. Please refrain from playing with it if
you're unsure how it works.

=head1 SUBROUTINES/METHODS

=head2 collect

The main function of Data::Collector. It runs all the information collecting
modules. When it is done, it runs the I<serialize> method in order to serialize
the information fetched.

=head2 serialize

Loads the serializer (according to the I<format> selected) and asks it to
serialize the data it collected.

This method can be run manually as well, but it is automatically run when
you run I<collect>.

=head2 clear_registry

Clears the information registry. The registry keeps all the keys of different
information modules. The registry makes sure information modules don't step on
each other.

This is merely a helper method. It simply runs:

    Data::Collector::Info->clear_registry;

This is actually only a mere helper method.

=head2 BUILD

Internal initialize subroutine that sets the default OS to CentOS.

=head2 load_info

Loads all the infos available.

=head2 load_os

Currently not being used.

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-collector at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Collector>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Collector

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Collector>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Collector>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Collector>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Collector/>

=back

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

