package App::Table2YAML::Loader;

use common::sense;
use charnames q(:full);
use Carp;
use English qw[-no_match_vars];
use List::Util qw[first];
use Moo;
with qw[
    App::Table2YAML::Loader::AsciiTable
    App::Table2YAML::Loader::DSV
    App::Table2YAML::Loader::FixedWidth
    App::Table2YAML::Loader::HTML
    App::Table2YAML::Loader::LaTeX
    App::Table2YAML::Loader::Texinfo
];

our $VERSION = '0.003'; # VERSION

has input => (
    is  => q(rw),
    isa => sub { -e $_[0] && -r $_[0] && -f $_[0] && -s $_[0] },
);
has input_type => ( is => q(rw), default => q(), );
has field_separator => (
    is  => q(rw),
    isa => sub { @_ == 1 && length $_[0] == 1 },
);
has record_separator => (
    is  => q(rw),
    isa => sub {
        @_ == 1 && first { $_[0] eq $_ } (
            qq(\N{CARRIAGE RETURN}),
            qq(\N{LINE FEED}),
            qq(\N{CARRIAGE RETURN}\N{LINE FEED}),
        );
    },
    default => qq{\N{LINE FEED}},
);
has field_offset => (
    is      => q(rw),
    isa     => sub { ref $_[0] eq q(ARRAY); },
    default => sub { []; },
);

sub BUILD {
    my $self = shift;
    my $args = shift;

    foreach my $arg ( keys %{$args} ) {
        if ( $self->can($arg) ) {
            $self->$arg( delete $args->{$arg} );
        }
    }

    return 1;
}

sub load {
    my $self = shift;

    if ( !( defined $self->input_type() ) || $self->input_type() eq q() ) {
        croak(
            sprintf q(invalid input_type: '%s'),
            $self->input_type() // q(undef),
        );
    }

    my $loader = q(load_) . lc $self->input_type();
    my @table  = $self->$loader();

    return @table;
} ## end sub load

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Table2YAML::Loader - Load and parse files.

=head1 VERSION

version 0.003

=head1 METHODS

=head2 input_type

=head2 load

=head1 SEE ALSO

=for Pod::Coverage BUILD

=head1 AUTHOR

Ronaldo Ferreira de Lima aka jimmy <jimmy at gmail>.

=cut
