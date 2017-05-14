package Bio::VertRes::Config::Exceptions;
# ABSTRACT: Exceptions for input data 



use Exception::Class (
    Bio::VertRes::Config::Exceptions::FileDoesntExist   => { description => 'Couldnt open the file' },
    Bio::VertRes::Config::Exceptions::FileCantBeModified => { description => 'Couldnt open the file for modification' },
    Bio::VertRes::Config::Exceptions::InvalidType => { description => 'Invalid type passed in, can only be one of study/file/lane/library/sample' },
);  

1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Exceptions - Exceptions for input data 

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
