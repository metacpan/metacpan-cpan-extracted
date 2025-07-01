package Bio::MUST::Core::Taxonomy::ColorScheme;
# ABSTRACT: Helper class providing color scheme for taxonomic annotations
# CONTRIBUTOR: Valerian LUPO <valerian.lupo@uliege.be>
$Bio::MUST::Core::Taxonomy::ColorScheme::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use Smart::Comments '###';

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
use aliased 'Bio::MUST::Core::SeqId';
with 'Bio::MUST::Core::Roles::Commentable',
     'Bio::MUST::Core::Roles::Taxable';


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


# private hash for indexed colors (e.g., gnuplot colors)
has '_icol_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Str]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_icol_for',
    handles  => {
        icol        =>  'get',
        icol_for    =>  'get',
        all_icols   =>  'elements',
    },  # Note: should be index_for but this makes more sense
);


# private labeler
has '_labeler' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Taxonomy::Labeler',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_labeler',
    handles  => [ qw(classify) ],
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
    return Graphics::ColorNames->new('WWW');
}

sub _build_icol_for {
    my $self = shift;

    my %icol_for;
    my $index = 0;

    my @colors = uniq $self->all_colors;
    for my $color (@colors) {
        $icol_for{$color} = ++$index;
    }

    return \%icol_for;
}

sub _build_labeler {
    my $self = shift;
    return $self->tax->tax_labeler_from_list( $self->names );
}

## use critic


sub BUILD {
    my $self = shift;

    # TODO: check that is has any effect at all!
    carp '[BMC] Warning: name and color list sizes differ!'
        unless $self->count_names == $self->count_colors;
    carp '[BMC] Warning: non unique names!'
        unless $self->count_names == uniq @{ $self->names };

    return;
}


around qw(hex rgb icol) => sub {
    my $method = shift;
    my $self   = shift;
    my $seq_id = shift;

    # intercept delegated method calls and translate color names on the fly

    # consider input as a SeqId object (or NCBI lineage)
    # ... and select the lowest taxon to which a color is associated
    # if a lineage has no colored taxon then it will be black
    my $label = $self->classify($seq_id) // $NOCOLOR;

    # return color (possibly doubly translated)
    # ... e.g., taxon => color-name => color-hex-code
    my $color = $self->$method( $self->color_for($label), @_ );
    return wantarray ? ($color, $label) : $color;
};



sub attach_colors_to_entities {
    my $self = shift;
    my $tree = shift;
    my $key  = shift // 'taxonomy';

    for my $node ( @{ $tree->tree->get_entities } ) {
        my ($color, $label) = $self->hex( $node->get_generic($key), '#' );
        $node->set_generic(    '!color' => $color );
        $node->set_generic( taxon_label => $label ) unless $label eq $NOCOLOR;
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
    my $self   = shift;
    my $infile = shift;

    open my $in, '<', $infile;

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # skip empty lines and comment lines
        next LINE if $line =~ $EMPTY_LINE
                  || $self->is_comment($line);

        # extract name and color
        my ($name, $color) = split /\t/xms, $line;
        $self->add_name( $name );
        $self->add_color($color);
    }

    return $self;
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

    close $out;

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Taxonomy::ColorScheme - Helper class providing color scheme for taxonomic annotations

=head1 VERSION

version 0.251810

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

=head1 CONTRIBUTOR

=for stopwords Valerian LUPO

Valerian LUPO <valerian.lupo@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
