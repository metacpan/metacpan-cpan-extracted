package Bio::InterProScanWrapper::Exceptions;
# ABSTRACT: Exceptions for input data 



use Exception::Class (
    Bio::InterProScanWrapper::Exceptions::FileNotFound   => { description => 'Couldnt open the file' },
    Bio::InterProScanWrapper::Exceptions::CouldntWriteToFile   => { description => 'Couldnt open the file for writing' },
    Bio::InterProScanWrapper::Exceptions::LSFJobFailed   => { description => 'Jobs failed' },
);  

1;

__END__

=pod

=head1 NAME

Bio::InterProScanWrapper::Exceptions - Exceptions for input data 

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Exceptions for input data 

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
