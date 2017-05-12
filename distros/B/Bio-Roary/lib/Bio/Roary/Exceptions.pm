package Bio::Roary::Exceptions;
# ABSTRACT: Exceptions for input data 
$Bio::Roary::Exceptions::VERSION = '3.8.0';

use strict; use warnings;
use Exception::Class (
    'Bio::Roary::Exceptions::FileNotFound'   => { description => 'Couldnt open the file' },
    'Bio::Roary::Exceptions::CouldntWriteToFile'   => { description => 'Couldnt open the file for writing' },
);  

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Roary::Exceptions - Exceptions for input data 

=head1 VERSION

version 3.8.0

=head1 SYNOPSIS

Exceptions for input data 

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
