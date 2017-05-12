package Bio::Tradis::Exception;
# ABSTRACT: Exceptions for input data 
$Bio::Tradis::Exception::VERSION = '1.3.3';


use Exception::Class (
    Bio::Tradis::Exception::RefNotFound    => { description => 'Cannot find the reference file' },
    Bio::Tradis::Exception::TagFilterError => { description => 'Problem filtering the Fastq by tag' }
);  

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Tradis::Exception - Exceptions for input data 

=head1 VERSION

version 1.3.3

=head1 SYNOPSIS

Exceptions for input data 

=head1 AUTHOR

Carla Cummins <path-help@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
