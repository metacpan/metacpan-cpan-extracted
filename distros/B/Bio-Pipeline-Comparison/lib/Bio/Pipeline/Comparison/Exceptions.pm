package Bio::Pipeline::Comparison::Exceptions;

# ABSTRACT: Custom exceptions



use Exception::Class (
    Bio::Pipeline::Comparison::Exceptions::InvalidTabixFile         => { description => 'The VCF file needs to be compressed with bgzip and indexed with tabix.' },
    Bio::Pipeline::Comparison::Exceptions::FileDontExist            => { description => 'The file doesnt exist.'},
    Bio::Pipeline::Comparison::Exceptions::VCFCompare               => { description => 'Something when wrong when running vcf-compare'},
);  

1;

__END__

=pod

=head1 NAME

Bio::Pipeline::Comparison::Exceptions - Custom exceptions

=head1 VERSION

version 1.123050

=head1 SYNOPSIS

Custom exceptions

=head1 SEE ALSO

=over 4

=item *

L<Bio::Pipeline::Comparison>

=back

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
