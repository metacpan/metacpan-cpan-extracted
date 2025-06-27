package Bio::MUST::Apps::OmpaPa::Parameters;
# ABSTRACT: Selected parameters
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
$Bio::MUST::Apps::OmpaPa::Parameters::VERSION = '0.251770';
use Moose;

use autodie;
use feature qw(say);
use Path::Class qw(file);
use File::Temp;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix);

use Smart::Comments '###';

use MooseX::SemiAffordanceAccessor;
use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');

has bb_file => (
    traits   => ['DoNotSerialize'],
    is      => 'ro',
    isa      => 'File::Temp',
    builder => '_build_bb_file',
);

has 'min_' . $_ => (
    is       => 'rw',
    isa      => 'Num',
    builder  => '_build_min_' . $_,
) for qw(len eval cov copy);

has 'max_' . $_ => (
    is       => 'rw',
    isa      => 'Num',
    builder  => '_build_max_' . $_,
) for qw(len eval cov copy);


## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_bb_file {
    return File::Temp->new( UNLINK => 0, SUFFIX => '.bb' );
}

sub _build_min_copy {
    return 1;
}

sub _build_max_copy {
    return 3;
}

sub _build_min_cov {
    return 0.7;
}

sub _build_max_cov {
    return 1;
}

sub _build_min_eval {
    return 0;
}

sub _build_max_eval {
    return 308;         # TODO: improve this
}

sub _build_min_len {
    return 0;
}

sub _build_max_len {
    return 10000000;    # TODO: improve this
}

## use critic


sub store_bounds {
    my $self = shift;

    my $bb_file = $self->bb_file;

    return << "EOT";
set print "$bb_file"
print "min_eval=" . int(GPVAL_X_MIN)
print "max_eval=" . int(GPVAL_X_MAX)
print "min_len=" . int(GPVAL_Y_MIN)
print "max_len=" . int(GPVAL_Y_MAX)
EOT
}

sub load_bounds {
    my $self = shift;

    # horrible hack to wait for the bb_file to be complete
    # TODO: improve robustness and portability!
    my $shell_cmd = 'wc -l ' . $self->bb_file;
    do {
        sleep(0.2)
    } until (-e $self->bb_file && qx{$shell_cmd} =~ m/^\s*4\b/xms);

    open my $in, '<', $self->bb_file;

    while (my $line = <$in>) {
        chomp $line;
        my ($var, $val) = $line =~ m/^ (\w+) = (\-?\d+) $/xmsg;
        my $method = "set_$var";
        $self->$method($val);
    }

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::OmpaPa::Parameters - Selected parameters

=head1 VERSION

version 0.251770

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Amandine BERTRAND

Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
