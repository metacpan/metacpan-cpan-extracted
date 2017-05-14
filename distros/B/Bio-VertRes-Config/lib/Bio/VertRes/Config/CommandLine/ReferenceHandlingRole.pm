package Bio::VertRes::Config::CommandLine::ReferenceHandlingRole;

# ABSTRACT: A role to handle references in a command line script


use Moose::Role;
use Bio::VertRes::Config::References;

sub handle_reference_inputs_or_exit
{
  my($reference_lookup_file, $available_references, $reference) = @_;
  
  my $reference_lookup = Bio::VertRes::Config::References->new( reference_lookup_file => $reference_lookup_file );
  
  if ( defined($available_references) && $available_references ne "" ) {
      print join(
          "\n",
          @{ $reference_lookup->search_for_references($available_references)}
      );
      return 1;
  }
  elsif( ! $reference_lookup->is_reference_name_valid($reference))
  {
    print $reference_lookup->invalid_reference_message($reference);
    return 1;
  }
  
  return 0;
}

1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::CommandLine::ReferenceHandlingRole - A role to handle references in a command line script

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

A role to handle references in a command line script
   with 'Bio::VertRes::Config::CommandLine::ReferenceHandlingRole';

   $self->handle_reference_inputs_or_exit($reference_lookup_file, $available_referenes, $reference);

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
