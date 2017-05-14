package Bio::VertRes::Config::Validate::Prefix;

# ABSTRACT: Validates a prefix for use in filenames within the pipeline


use Moose;

sub is_valid {
    my ( $self, $prefix ) = @_;
    return 0 unless ( defined($prefix) );
    return 0 if ( length($prefix) > 12 );
    return 0 if ( $prefix =~ /[\W]/ );
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Validate::Prefix - Validates a prefix for use in filenames within the pipeline

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Validates a prefix for use in filenames within the pipeline

   use Bio::VertRes::Config::Validate::Prefix;
   Bio::VertRes::Config::Validate::Prefix
      ->new()
      ->is_valid('abc');

=head1 METHODS

=head2 is_valid

Check to see if the prefix is valid

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
