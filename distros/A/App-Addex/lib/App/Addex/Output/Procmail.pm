use strict;
use warnings;

package App::Addex::Output::Procmail;
# ABSTRACT: generate procmail recipes from an address book
$App::Addex::Output::Procmail::VERSION = '0.026';
use parent qw(App::Addex::Output::ToFile);

#pod =head1 DESCRIPTION
#pod
#pod This plugin produces a file that contains a list of procmail recipes.  For
#pod any entry with a "folder" field, recipes are produced to deliver all mail from
#pod its addresses to the given folder.
#pod
#pod Forward slashes in the folder name are converted to dots, showing my bias
#pod toward Courier IMAP.
#pod
#pod =head1 CONFIGURATION
#pod
#pod The valid configuration parameters for this plugin are:
#pod
#pod   filename - the filename to which to write the procmail recipes
#pod
#pod =method process_entry
#pod
#pod   $procmail_outputter->process_entry($addex, $entry);
#pod
#pod This method does the actual writing of configuration to the file.
#pod
#pod =cut

sub process_entry {
  my ($self, $addex, $entry) = @_;

  return unless my $folder = $entry->field('folder');

  $folder =~ tr{/}{.};

  my @emails = $entry->emails;

  for my $email (@emails) {
    next unless $email->sends;
    $self->output(":0");
    $self->output("* From:.*$email");
    $self->output(".$folder/");
    $self->output(q{});
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Addex::Output::Procmail - generate procmail recipes from an address book

=head1 VERSION

version 0.026

=head1 DESCRIPTION

This plugin produces a file that contains a list of procmail recipes.  For
any entry with a "folder" field, recipes are produced to deliver all mail from
its addresses to the given folder.

Forward slashes in the folder name are converted to dots, showing my bias
toward Courier IMAP.

=head1 METHODS

=head2 process_entry

  $procmail_outputter->process_entry($addex, $entry);

This method does the actual writing of configuration to the file.

=head1 CONFIGURATION

The valid configuration parameters for this plugin are:

  filename - the filename to which to write the procmail recipes

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
