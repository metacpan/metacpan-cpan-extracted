package Bio::AssemblyImprovement::Util::ZipFileRole;
# ABSTRACT: Zip file


use Moose::Role;
use IO::Compress::Gzip qw(gzip $GzipError) ;
use Cwd qw(abs_path);
use Cwd;
use File::Basename;

sub _zip_file {
  
    my ( $self, $input_filename, $output_directory ) = @_;
    
	return undef unless(defined($input_filename));
	
    $output_directory ||= abs_path (getcwd()); 
    
    my ( $filename, $directories, $suffix ) = fileparse( $input_filename );
    my $output_filename = join( '/', ( $output_directory, $filename.'.gz' ) );
    gzip $input_filename => $output_filename or die "gzip failed: $GzipError\n";
    return $output_filename;

}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::AssemblyImprovement::Util::ZipFileRole - Zip file

=head1 VERSION

version 1.160490

=head1 SYNOPSIS

Role for zipping files (not tested yet)

	with 'Bio::AssemblyImprovement::Util::ZipFileRole';

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
