package Bio::AssemblyImprovement::Util::UnzipFileIfNeededRole;
# ABSTRACT: Role for unzipping files if needed


use Moose::Role;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Cwd;
use Cwd 'abs_path';
use File::Basename;

sub _gunzip_file_if_needed {
  
    my ( $self, $input_filename, $output_directory ) = @_;
	return undef unless(defined($input_filename));
	
    $output_directory ||= getcwd(); # If an output directory is not given, default to current working directory
    
    $input_filename = abs_path($input_filename);
    
    if ( $input_filename =~ /\.gz$/ ) {
        my $base_filename = fileparse( $input_filename, qr/\.[^.]*/ );
        my $output_filename = join( '/', ( $output_directory, $base_filename ) );
        gunzip $input_filename => $output_filename or die "gunzip failed: $GunzipError\n";
        return $output_filename;
    }
    else {
        return $input_filename;
    }
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::AssemblyImprovement::Util::UnzipFileIfNeededRole - Role for unzipping files if needed

=head1 VERSION

version 1.160490

=head1 SYNOPSIS

Role for unzipping input files if they are zipped.

	with 'Bio::AssemblyImprovement::Util::UnzipFileIfNeededRole';

   	for my $filename ( @{ $self->input_files } ) {
    	
        push( @prepared_input_files, $self->_gunzip_file_if_needed( $filename,$self->_temp_directory));
    }    

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
