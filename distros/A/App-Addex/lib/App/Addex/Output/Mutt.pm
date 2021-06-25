use strict;
use warnings;

package App::Addex::Output::Mutt 0.027;
# ABSTRACT: generate mutt configuration from an address book

use parent qw(App::Addex::Output::ToFile);

use Text::Unidecode ();

#pod =head1 DESCRIPTION
#pod
#pod This plugin produces a file that contains a list of alias lines.  The first
#pod email address for each entry will be aliased to the entry's aliasified nickname
#pod and name.  Every other address will be aliased to one of those with an
#pod appended, incrementing counter.  The entry's name is added as the alias's "real
#pod name."
#pod
#pod If the entry has a "folder" value (given as a line in the card's "notes" that
#pod looks like "folder: value") a save-hook is created to save mail from the entry
#pod to that folder and a mailboxes line is created for the folder.  If the entry
#pod has a "sig" value, a send-hook is created to use that signature when composing
#pod a message to the entry.
#pod
#pod =head1 CONFIGURATION
#pod
#pod The valid configuration parameters for this plugin are:
#pod
#pod   filename  - the filename to which to write the Mutt configuration
#pod
#pod   unidecode - if set (to 1) this will transliterate all aliases to ascii before
#pod               adding them to the file
#pod
#pod =cut

sub new {
  my ($class, $arg) = @_;
  $arg ||= {};

  my $self = $class->SUPER::new($arg);

  $self->{unidecode} = $arg->{unidecode};

  return $self;
}

#pod =method process_entry
#pod
#pod   $mutt_outputter->process_entry($addex, $entry);
#pod
#pod This method does the actual writing of configuration to the file.
#pod
#pod =cut

sub _aliasify {
  my ($self, $text) = @_;

  return unless defined $text;
  $text =~ tr/ .'//d;
  Text::Unidecode::unidecode($text) if $self->{unidecode};
  return lc $text;
}

sub _is_group {
  return($_[0] =~ /;$/ && $_[0] =~ /:/ ? 1 : 0);
}

sub process_entry {
  my ($self, $addex, $entry) = @_;

  my $name   = $entry->name;
  my @emails = $entry->emails;

  my $folder = $entry->field('folder');
  my $sig    = $entry->field('sig');

  if ($folder) {
    $folder =~ tr{/}{.};
    $self->output("save-hook ~f$_ =$folder") for grep { $_->sends } @emails;
    $self->output("mailboxes =$folder")
      unless $self->{_saw_folder}{$folder}++;
  }

  if ($sig) {
    $self->output(qq{send-hook ~t$_ set signature="~/.sig/$sig"})
      for grep { $_->receives } @emails;
  }

  my @aliases =
    map { $self->_aliasify($_) } grep { defined } $entry->nick, $name;

  my @name_strs = (qq{"$name" }, q{});

  my ($rcpt_email) = grep { $_->receives } @emails;
  $self->output("alias $_ $name_strs[_is_group($rcpt_email)]<$rcpt_email>")
    for @aliases;

  # It's not that you're expected to -use- these aliases, but they allow
  # mutt's reverse_alias to do its thing.
  if (@emails > 1) {
    my %label_count;

    if (defined(my $label = $rcpt_email->label)) {
      $self->output("alias $_-$label $name_strs[_is_group($rcpt_email)]<$rcpt_email>")
        for @aliases;

      $label_count{$label} = 1;
    }

    my @rcpt_emails = grep { $_->receives } @emails;
    for my $i (1 .. $#rcpt_emails) {
      my $label = $rcpt_emails[$i]->label;
      $label = '' unless defined $label;
      $label_count{$label}++;

      for my $id (@aliases) {
        my $alias = length $label ? "$id-$label" : $id;
        $alias .= "-" . ($label_count{$label} - 1) if $label_count{$label} > 1;

        $self->output("alias $alias $name_strs[_is_group($rcpt_emails[$i])]<$rcpt_emails[$i]>");
      }
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Addex::Output::Mutt - generate mutt configuration from an address book

=head1 VERSION

version 0.027

=head1 DESCRIPTION

This plugin produces a file that contains a list of alias lines.  The first
email address for each entry will be aliased to the entry's aliasified nickname
and name.  Every other address will be aliased to one of those with an
appended, incrementing counter.  The entry's name is added as the alias's "real
name."

If the entry has a "folder" value (given as a line in the card's "notes" that
looks like "folder: value") a save-hook is created to save mail from the entry
to that folder and a mailboxes line is created for the folder.  If the entry
has a "sig" value, a send-hook is created to use that signature when composing
a message to the entry.

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

  $mutt_outputter->process_entry($addex, $entry);

This method does the actual writing of configuration to the file.

=head1 CONFIGURATION

The valid configuration parameters for this plugin are:

  filename  - the filename to which to write the Mutt configuration

  unidecode - if set (to 1) this will transliterate all aliases to ascii before
              adding them to the file

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
