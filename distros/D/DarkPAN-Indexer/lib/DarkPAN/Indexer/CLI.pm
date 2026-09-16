#!/usr/bin/env perl

package DarkPAN::Indexer::CLI;

use strict;
use warnings;

use Carp;
use CLI::Simple::Constants qw(:booleans);
use Data::Dumper;
use English qw(-no_match_vars);

use parent qw(CLI::Simple);

caller or exit __PACKAGE__->main();

our $VERSION = '1.0.2';

########################################################################
sub cmd_index_darkpan {  # 'index' / default
########################################################################
  my ($self) = @_;

  my $indexer = $self->get_indexer;  # builds DarkPAN::Indexer from --config/--darkpan

  my $stats = $indexer->create_index;

  printf {*STDOUT} "indexed %d distributions (%d modules)\n", $stats->{distributions_indexed}, $stats->{modules_written};  # adjust to real stat keys

  return $SUCCESS;
}

########################################################################
sub cmd_update {  # 'update <dist-key>'
########################################################################
  my ($self) = @_;

  my ($key) = $self->get_args;  # positional

  die "usage: update <distribution-key>\n"
    if !$key;

  $self->get_indexer->update_index( distribution => $key );

  print {*STDOUT} "updated $key\n";

  return $SUCCESS;
}

########################################################################
sub cmd_delete {  # 'delete <dist-key>'
########################################################################
  my ($self) = @_;
  my ($key)  = $self->get_args;
  croak "usage: delete <distribution-key>\n" if !$key;
  $self->get_indexer->delete_from_index( distribution => $key );
  print "deleted $key\n";
  return $SUCCESS;
}

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  $self->set_indexer( $self->_indexer );

  return $self;
}

########################################################################
sub _indexer {  # shared: build orchestrator from CLI options
########################################################################
  my ($self) = @_;

  return DarkPAN::Indexer->new(
    config_file => $self->get_config,  # --config
  );
}

########################################################################
sub main {
########################################################################
  my $cli = __PACKAGE__->new(
    option_specs => [
      qw(
        help|h
        config|c=s
      )
    ],

    default_options => {},

    commands => {
      default               => \&cmd_index_darkpan,
      'index-darkpan'       => \&cmd_index_darkpan,
      'delete-distribution' => \&cmd_delete,
      'update-darkpan'      => \&cmd_update,
    },
    extra_options => [qw(indexer)],
    abbreviations => $TRUE,
  );

  return $cli->run();
}

1;

## no critic

__END__

=pod

=encoding utf8

=head1 NAME

DarkPAN::Indexer::CLI - command-line driver for DarkPAN::Indexer

=head1 SYNOPSIS

  # build the whole index from the repository
  darkpan-indexer --config darkpan.json index-darkpan

  # (re)index a single distribution
  darkpan-indexer --config darkpan.json update-darkpan authors/id/A/AB/AUTHOR/Foo-1.0.tar.gz

  # remove a distribution from the index-darkpan
  darkpan-indexer --config darkpan.json delete-distribution authors/id/A/AB/AUTHOR/Foo-1.0.tar.gz

I<Note: all commands can be abbreviated - index, update, delete>

=head1 DESCRIPTION

C<DarkPAN::Indexer::CLI> is a thin command-line front end over
L<DarkPAN::Indexer>. It exists so a DarkPAN can be built and maintained
B<without> an external pipeline (e.g. a Lambda handler): point it at a config
file and run a command. Each command parses its arguments and delegates to the
orchestrator, which does the real work (locking, fetching, indexing,
publishing).

This is a L<CLI::Simple> modulino; it is normally invoked through the
C<darkpan-indexer> wrapper script.

=head1 OPTIONS

=over 4

=item C<--config>, C<-c> I<FILE>

Path to the DarkPAN config file (JSON). See L<DarkPAN::Indexer/CONFIGURATION>.

=item C<--help>, C<-h>

Show usage.

=back

=head1 COMMANDS

=head2 index-darkpan

  darkpan-indexer --config darkpan.json index

Full rebuild: index every distribution in the repository and publish the index.
Delegates to C<< DarkPAN::Indexer->create_index >>. This is the default command.

=head2 update-darkpan I<DISTRIBUTION-KEY>

  darkpan-indexer --config darkpan.json update authors/id/A/AB/AUTHOR/Foo-1.0.tar.gz

Incrementally (re)index a single distribution, given its storage key. Delegates
to C<< DarkPAN::Indexer->update_index( distribution => $key ) >>.

=head2 delete-distribution I<DISTRIBUTION-KEY>

  darkpan-indexer --config darkpan.json delete authors/id/A/AB/AUTHOR/Foo-1.0.tar.gz

Remove a single distribution's packages from the index, given its storage key.
Delegates to C<< DarkPAN::Indexer->delete_from_index( distribution => $key ) >>.

=head1 EXIT STATUS

Returns C<$SUCCESS> (0) on success. Errors from the orchestrator (missing
config, storage failures, lock contention) propagate as exceptions.

=head1 SEE ALSO

L<DarkPAN::Indexer>

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=cut
