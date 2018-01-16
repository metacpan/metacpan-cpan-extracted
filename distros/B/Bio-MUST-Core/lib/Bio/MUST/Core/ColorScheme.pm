package Bio::MUST::Core::ColorScheme;
# ABSTRACT: Color scheme for taxonomic annotations
$Bio::MUST::Core::ColorScheme::VERSION = '0.180140';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Carp;
# use Color::Spectrum::Multi;
use Const::Fast;
use Graphics::ColorNames;
use Graphics::ColorNames::WWW;
use List::AllUtils qw(mesh uniq each_array);

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:files);
with 'Bio::MUST::Core::Roles::Commentable';


# names and colors public arrays
has $_ . 's' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    default  => sub { [] },
    handles  => {
        'count_' . $_ . 's' => 'count',
          'all_' . $_ . 's' => 'elements',
          'add_' . $_       => 'push',
    },
) for qw(name color);


# _color_for private hash for faster mapping
has '_color_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Str]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_color_for',
    handles  => {
        is_a_name => 'defined',
        color_for => 'get',
    },
);


# private Graphics::ColorNames object for named colors
has '_gcn' => (
    is       => 'ro',
    isa      => 'Graphics::ColorNames',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_gcn',
    handles  => qr{hex|rgb}xms,
);

## no critic (ProhibitUnusedPrivateSubroutines)

# "magic" name used when a lineage has no colored taxon
const my $NOCOLOR => '_NOCOLOR_';

sub _build_color_for {
    my $self = shift;
    return {
        $NOCOLOR => 'black',                            # default color
        mesh @{ $self->names }, @{ $self->colors }      # scheme colors
    };
}


sub _build_gcn {
    return Graphics::ColorNames->new( 'Graphics::ColorNames::WWW' );
}

## use critic


sub BUILD {
    my $self = shift;

    # TODO: check that is has any effect at all!
    carp 'Warning: name and color list sizes differ!'
        unless $self->count_names == $self->count_colors;
    carp 'Warning: non unique names!'
        unless $self->count_names == uniq @{ $self->names };

    return;
}


around qw(hex rgb) => sub {
    my $method = shift;
    my $self   = shift;
    my $name   = shift;

    # intercept delegated method calls and translate color names on the fly

    # if name is an ArrayRef then consider it as a NCBI lineage
    # ... and select the lowest taxon to which a color is associated
    # if a lineage has no colored taxon then it will be black
    if (ref $name eq 'ARRAY') {
        my @lineage = @{$name};
        $name = $NOCOLOR;           # default color
        while (my $taxon = pop @lineage) {
            if ( $self->is_a_name($taxon) ) {
                $name = $taxon;
                last;
            }
        }
    }

    # return color (possibly doubly translated)
    # ... e.g., taxon => color-name => color-hex-code
    return $self->$method( $self->color_for($name), @_ );
};

# TODO: consider inversing responsibilities between CS and Tree?


sub attach_colors_to_entities {
    my $self = shift;
    my $tree = shift;
    my $key  = shift // 'taxonomy';

    for my $node ( @{ $tree->tree->get_entities } ) {
        my $color = $self->hex( $node->get_generic($key), '#' );
        $node->set_generic('!color' => $color);
    }

    return;
}


# class methods


# TODO: implement auto spectrum methods (based on name list?)

# sub spectrum {
#     my $class = shift;
#     my $steps = shift;
#
#     my $spectrum = Color::Spectrum::Multi->new();
#     my @colors = $spectrum->generate($steps, '#FF0000', '#00FF00', '#0000FF');
#
# }


# I/O methods


sub load {
    my $class  = shift;
    my $infile = shift;

    open my $in, '<', $infile;

    my $color_scheme = $class->new();

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # skip empty lines and comment lines
        next LINE if $line =~ $EMPTY_LINE
                  || $color_scheme->is_comment($line);

        # extract name and color
        my ($name, $color) = split /\t/xms, $line;
        $color_scheme->add_name( $name );
        $color_scheme->add_color($color);
    }

    return $color_scheme;
}



sub store {
    my $self = shift;
    my $outfile = shift;

    open my $out, '>', $outfile;

    # note the use of a twin array iterator
    print {$out} $self->header;
    my $ea = each_array @{ $self->names }, @{ $self->colors };
    while (my ($name, $color) = $ea->() ) {
        say {$out} join "\t", $name, $color;
    }

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::ColorScheme - Color scheme for taxonomic annotations

=head1 VERSION

version 0.180140

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 attach_color_to_entities

=head2 spectrum

=head2 load

=head2 store

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
