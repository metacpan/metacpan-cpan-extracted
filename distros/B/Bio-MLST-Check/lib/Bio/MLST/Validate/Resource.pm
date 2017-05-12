package Bio::MLST::Validate::Resource;
# ABSTRACT: Check to see if a file exists or if a uri is valid. For validation when classes have input files which may be local or on the web.
$Bio::MLST::Validate::Resource::VERSION = '2.1.1706216';

use Moose;
use Regexp::Common qw /URI/;

sub does_resource_exist
{
  my($self, $resource) = @_;
  
  return 1 if($RE{URI}{FTP}->matches($resource));
  return 1 if($RE{URI}{HTTP}->matches($resource));
  
  return 1 if(-e $resource);
  
  return 0;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::MLST::Validate::Resource - Check to see if a file exists or if a uri is valid. For validation when classes have input files which may be local or on the web.

=head1 VERSION

version 2.1.1706216

=head1 SYNOPSIS

Check to see if a file exists or if a uri is valid. For validation when classes have input files which may be local or on the web.

=head1 METHODS

=head2 does_file_exist

Check to see if a file exists or if a uri is valid. For validation when classes have input files which may be local or on the web.

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
