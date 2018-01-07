package Bio::FastParsers::Hmmer::Model;
# ABSTRACT: internal class for HMMER parser
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::FastParsers::Hmmer::Model::VERSION = '0.173640';
use Moose;
use namespace::autoclean;

use autodie;

use Carp;
use Path::Class;

use Smart::Comments;
use List::AllUtils qw(firstidx);

extends 'Bio::FastParsers::Base';

use Bio::FastParsers::Types;


has $_ => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
) for qw(cksum effn nseq leng);

has maxl => (
    is      => 'ro',
    isa     => 'Num',
);

has $_ => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    required => 1,
) for qw(alph cons cs map mm name rf);


around BUILDARGS => sub {
    my %args = @_;

    # parse file and automatically create args
    my $profile_file = file( $args{'file'} );
    my @profile_content = $profile_file->slurp( chomp => 1 );

    my $hmmstart_index = firstidx {
        substr($_, 0, 4) eq q{HMM }
    } @profile_content;

    for my $idx ( 1..$hmmstart_index-1 ) {
        my ($key, $value) = split /\s+/xms, $profile_content[$idx];
        $args{ lc $key } = $value;
    }

    return \%args;
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Hmmer::Model - internal class for HMMER parser

=head1 VERSION

version 0.173640

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Arnaud DI FRANCO

Arnaud DI FRANCO <arnaud.difranco@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
