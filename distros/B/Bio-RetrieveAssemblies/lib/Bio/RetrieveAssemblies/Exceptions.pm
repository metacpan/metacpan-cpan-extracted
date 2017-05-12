package Bio::RetrieveAssemblies::Exceptions;
$Bio::RetrieveAssemblies::Exceptions::VERSION = '1.1.5';
# ABSTRACT: Exceptions for input data


use Exception::Class (
    Bio::RetrieveAssemblies::Exceptions::CouldntDownload => { description => 'Couldnt download RefWeak' },
    Bio::RetrieveAssemblies::Exceptions::CSVParser       => { description => 'TSV parser error' },
    Bio::RetrieveAssemblies::Exceptions::GenBankToGFFConverter => { description => 'Couldnt convert GenBank file to GFF file' },
    Bio::RetrieveAssemblies::Exceptions::FileCopyFailed => { description => 'Couldnt copy the file' },

);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::RetrieveAssemblies::Exceptions - Exceptions for input data

=head1 VERSION

version 1.1.5

=head1 SYNOPSIS

Exceptions for input data 

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
