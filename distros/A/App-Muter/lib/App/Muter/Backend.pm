package App::Muter::Backend;
# ABSTRACT: App::Muter::Backend - a backend for muter
$App::Muter::Backend::VERSION = '0.002000';
use strict;
use warnings;


sub new {
    my ($class, $args, %opts) = @_;
    $class = ref($class) || $class;
    my $self = {args => $args, options => \%opts, method => $opts{transform}};
    bless $self, $class;
    $self->{m_process} = $self->can($opts{transform});
    $self->{m_final}   = $self->can("$opts{transform}_final");
    return $self;
}


sub metadata {
    my ($class) = @_;
    my $name = lc(ref $class || $class);
    $name =~ s/^.*:://;
    return {name => $name};
}


sub process {
    my ($self, $data) = @_;
    my $func = $self->{m_process};
    return $self->$func($data);
}


sub final {
    my ($self, $data) = @_;
    my $func = $self->{m_final};
    return $self->$func($data);
}

sub decode {
    my $self = shift;
    my $name = $self->metadata->{name};
    die "The $name technique doesn't have an inverse transformation.\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Muter::Backend - App::Muter::Backend - a backend for muter

=head1 VERSION

version 0.002000

=head1 METHODS

=head2 $class->new($args, %opts)

Create a new backend.

$args is an arrayref of arguments provided to the chain.  Currently only the
first argument is considered, and it will typically be a variant of the main
algorithm (e.g. I<lower> for lowercase).

%opts is a set of additional parameters.  The I<transform> value is set to
either I<encode> for encoding or I<decode> for decoding.

Returns the new object.

=head2 $class->metadata

Get metadata about this class.

Returns a hashref containing the metadata about this backend.  The following
keys are defined:

=over 4

=item name

The name of this backend.  This should be a lowercase string and is the
identifier used in the chain.

=item args

A hashref mapping possible arguments to the transform to a human-readable
description.

=back

=head2 $self->process($data)

Process a chunk of data.  Returns the processed chunk.  Note that for buffering
reasons, the data returned may be larger or smaller than the original data
passed in.

=head2 $self->final($data)

Process the final chunk of data.  Returns the processed chunk.  Note that for
buffering reasons, the data returned may be larger or smaller than the original
data passed in.

Calling this function is obligatory.  If all actual data has been passed to the
process function, this function can simply be called with the empty string.

=head1 AUTHOR

brian m. carlson <sandals@crustytoothpaste.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016–2017 by brian m. carlson.

This is free software, licensed under:

  The MIT (X11) License

=cut
