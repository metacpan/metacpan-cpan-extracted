use strict;
use warnings;

package App::Addex::Output::Procmail 0.027;
# ABSTRACT: generate procmail recipes from an address book

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

version 0.027

=head1 DESCRIPTION

This plugin produces a file that contains a list of procmail recipes.  For
any entry with a "folder" field, recipes are produced to deliver all mail from
its addresses to the given folder.

Forward slashes in the folder name are converted to dots, showing my bias
toward Courier IMAP.

=head1 PERL VERSION SUPPORT

This module has the same support period as perl itself:  it supports the two
most recent versions of perl.  (That is, if the most recently released version
is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 process_entry

  $procmail_outputter->process_entry($addex, $entry);

This method does the actual writing of configuration to the file.

=head1 CONFIGURATION

The valid configuration parameters for this plugin are:

  filename - the filename to which to write the procmail recipes

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
