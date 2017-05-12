package BIE::Data::HDF5;

use strict;
use warnings;
use v5.10;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use BIE::Data::HDF5 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 
		    'file' => [ qw(
				    H5Fcreate
				    H5Fopen
				    H5Fclose
				 ) ],
		    'group' => [ qw(
				     H5Gcreate
				     H5Gopen
				     H5Gclose
				  ) ],
		    'data' => [ qw(
				    H5Dcreate
				    H5Dopen
				    H5Dclose
				    H5Dget_type
				    H5Dget_space
				    H5Dread
				    H5Tget_size
				    H5Tclose
				    H5Sclose
				    getH5DCode			    
				 ) ],
		    'utils' => [ qw(
				     h5name
				     h5ls
				  )],
		   );

$EXPORT_TAGS{all} = [map { @{$EXPORT_TAGS{$_}} } qw(file group data utils)];

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('BIE::Data::HDF5', $VERSION);

1;
__END__

=head1 NAME

BIE::Data::HDF5 - Perl extension for blah with HDF5.

=head1 SYNOPSIS

use BIE::Data::HDF5;
  
=head1 DESCRIPTION

BIE::Data::HDF5 is an interface to operate Hierarchical Data Format 5. 
Now it only reads h5 files. Writing capability is coming soon.

=head2 EXPORT

None by default.
For developers, please check out the library file.

=head1 SEE ALSO

See L<HDF5 website|http://www.hdfgroup.org> to learn more about HDF5.

See L<PDL::IO::HDF5> if user would like to rely on PDL more.

=head1 AUTHOR

Xin Zheng, E<lt>zhengxin@mail.nih.govE<gt>

This work is being inspired by problems in daily work at 
Laboratory of Bioinformatics and Immunopathogenesis at Frederick National 
Lab for Cancer Research. 
Many thanks for our team. Be proud of our excellent work in HIV/AIDS study. 
And of course, FNL doesn't take any responsiblity caused by using this module.
The only one to be blamed is listed above.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Xin Zheng

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
