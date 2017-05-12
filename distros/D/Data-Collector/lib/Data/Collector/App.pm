package Data::Collector::App;
{
  $Data::Collector::App::VERSION = '0.15';
}
# ABSTRACT: An application implementation for Data::Collector

use Moose;
use File::Spec;
use File::HomeDir;
use List::MoreUtils 'none';
use Module::Pluggable::Object;
use MooseX::Types::Path::Class 'File';
use namespace::autoclean;

use Data::Collector;

with qw/ MooseX::SimpleConfig MooseX::Getopt::Dashes /;

has '+configfile' => (
    isa     => 'Maybe[MooseX::Types::Path::Class::File]',
    default => sub {
        my @files = (
            File::Spec->catfile( File::HomeDir->my_home, '.data_collector.yaml' ),
            '/etc/data_collector.yaml',
        );

        foreach my $file (@files) {
            -e $file && -r $file and return file($file);
        }

        return;
    },
);

has 'engine' => ( is => 'ro', isa => 'Str', default => 'OpenSSH' );
has 'format' => ( is => 'ro', isa => 'Str', default => 'JSON'    );
has 'os'     => ( is => 'ro', isa => 'Str', default => 'CentOS'  );

has 'output' => (
    is        => 'ro',
    isa       => File,
    predicate => 'has_output',
);

has [ qw/ engine_args format_args info_args / ] => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

my @classes = Module::Pluggable::Object->new(
    search_path => 'Data::Collector::Info',
    require     => 1, # can use Class::MOP::load_class instead
)->plugins;

my @ignore_classes = qw/
    Data::Collector::Commands
    Data::Collector::Info
/;

foreach my $class (@classes) {
    foreach my $attribute ( $class->meta->get_all_attributes ) {
        my $name    = $attribute->name;
        my $assoc   = $attribute->associated_class->name;
        my $package = $attribute->definition_context->{'package'};

        if ( none { $package eq $_ } @ignore_classes ) {
            my @levels = split /\:\:/, $class;
            my $level  = lc $levels[-1];
            my $attr   = "info_${level}_${name}";

            if ( __PACKAGE__->meta->get_attribute($attr) ) {
                die "Already have attribute by the name of $attr\n";
            }

            __PACKAGE__->meta->add_attribute(
                $attribute->clone( name => $attr )
            );
        }
    }
}

sub BUILD {
    my $self  = shift;
    my $regex = qr/^info_(.+?)_(.+)$/;

    foreach my $attr ( $self->meta->get_attribute_list ) {
        if ( $attr =~ $regex ) {
            # bad jojo magambo
            if ( exists $self->{$attr} ) {
                $self->info_args->{$1}{$2} = $self->{$attr};
            }
        }
    }
}

sub run {
    my $self      = shift;
    my $collector = Data::Collector->new(
        os          => $self->os,
        engine      => $self->engine,
        engine_args => $self->engine_args,
        format      => $self->format,
        format_args => $self->format_args,
        info_args   => $self->info_args,
    );

    my $data = $collector->collect;

    if ( $self->has_output ) {
        my $file = $self->output;
        write_file( $file, $data );
    } else {
        print "$data\n";
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

Data::Collector::App - An application implementation for Data::Collector

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use Data::Collector::App;

    my $collector = Data::Collector::App->new_with_options();
    $collector->run();

This module integrates all the checks and logics of an application.

It supports getopt command line parsing and optional configuration files.

Using this implementation, one can write an application.

=head1 ATTRIBUTES

=head2 configfile

An optional configuration file. If it exists, it is read and used for the
value of the rest of these attributes (if they are present in the file).

Default: C</etc/data_collector.yaml>.

=head2 engine

Type of engine (OpenSSH, for example).

=head2 engine_args

Any additional arguments the engine might want.

=head2 format

Type of serialization (C<JSON> or C<YAML>, for example).

=head2 format_args

Any additional arguments the serializer might want.

=head2 info_args

Any additional arguments the Info module might want.

You generally don't want to play with it, trust me.

=head2 output

A file to output to. If one is not provided, it will output the serialized
result to stdout.

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new instance of the application interface. This is the clean way of
doing it. You would probably prefer C<new_with_options> described below.

=head2 new_with_options

The same as C<new>, only it parses command line arguments and takes care of
reading a configuration file (if the correct argument for it is provided).

=head2 run

Runs the application: starts a new collector, collects the informtion and -
depending on the options - either outputs the result to the screen or to a
file.

=head2 BUILD

Subroutine run after initialization. Used to create the C<info_args> attribute
for the main C<Data::Collector>.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

