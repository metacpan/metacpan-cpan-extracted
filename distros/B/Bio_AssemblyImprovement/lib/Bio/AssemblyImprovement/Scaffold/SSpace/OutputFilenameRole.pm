package Bio::AssemblyImprovement::Scaffold::SSpace::OutputFilenameRole;
# ABSTRACT: Role for handling output filenames




use Moose::Role;
use File::Basename;
use Cwd;

has 'input_assembly'      => ( is => 'ro', isa => 'Str', required => 1 );
has 'output_filename'     => ( is => 'rw', isa => 'Str', lazy     => 1, builder => '_build_output_filename' );

has '_output_prefix' => ( is => 'ro', isa => 'Str', default => "scaffolded" );

sub _build_output_filename {
    my ($self) = @_;
    my ( $filename, $directories, $suffix ) = fileparse( $self->input_assembly, qr/\.[^.]*/ );
    $directories . $filename . "." . $self->_output_prefix . $suffix;
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::AssemblyImprovement::Scaffold::SSpace::OutputFilenameRole - Role for handling output filenames

=head1 VERSION

version 1.160490

=head1 SYNOPSIS

Role for handling output filenames.

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
