#!/usr/bin/env perl
# PODNAME: leel.pl
# ABSTRACT: The Elite of the Phylogenomic Back-Translators

use Modern::Perl '2011';

use Getopt::Euclid qw(:vars);

## no critic (RequireLocalizedPunctuationVars)
BEGIN{
    $ENV{Smart_Comments} = $ARGV_verbosity
        ? join q{ }, map { '#' x (2 + $_) } 1..$ARGV_verbosity
        : q{}
    ;
}
## use critic

use Smart::Comments -ENV;
use Config::Any;

use aliased 'Bio::MUST::Apps::Leel';

# read configuration file
my $config = Config::Any->load_files( {
    files           => [ $ARGV_config ],
    flatten_to_hash => 1,
    use_ext         => 1,
} );

# build leel object
# Note: default args are propagated to all orgs
my $leel = Leel->new(
    config  => $config->{$ARGV_config},
    infiles => \@ARGV_infiles,
);

# use leel as factory for run_proc object
# Note: CLI parameters are introduced here
my %args;
$args{debug_mode} = $ARGV_verbosity > 5 ? 1 : 0;
my $rp = $leel->run_proc(\%args);

__END__

=pod

=head1 NAME

leel.pl - The Elite of the Phylogenomic Back-Translators

=head1 VERSION

version 0.202160

=head1 USAGE

    leel.pl <infiles> --config=<file> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input ALI files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=item --config=<file>

Path to the configuration file specifying the run details.

In principle, several configuration file formats are available: XML, JSON,
YAML. However, leel was designed with YAML in mind. See the C<test> directory
of the distribution for annotated examples of YAML files.

=for Euclid: file.type: readable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --verbosity=<level>

Verbosity level for logging to STDERR [default: 0]. Available levels range from
0 to 6. Level 6 corresponds to debugging mode.

=for Euclid: level.type: int, level >= 0 && level <= 6
    level.default: 0

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
