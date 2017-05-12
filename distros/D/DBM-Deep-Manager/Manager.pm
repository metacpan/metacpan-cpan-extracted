package DBM::Deep::Manager;
$DBM::Deep::Manager::VERSION = 0.03;


use DBM::Deep 2.0;
use Data::Interactive::Inspect;
use YAML;



use vars qw(@ISA @EXPORT @EXPORT_OK $db);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(getshell opendb _export _import);
@EXPORT_OK = qw();

sub getshell {
  my ($db, $dbfile) = @_;
  my $shell = Data::Interactive::Inspect->new(
					    begin => sub {
					      my ($self) = @_;
					      my $maindb = tied(%{$self->{struct}});
					      if (!$self->{session}) {
						eval { $maindb->begin_work; };
						if ($@) {
						  print STDERR "transactions not supported by $dbfile," .
						               " re-create with 'num_txns' > 1\n";
						}
						else {
						  $self->{session} = 1;
						  print "ok\n";
						}
					      }
					    },
					    commit => sub {
					      my ($self) = @_;
					      my $maindb = tied(%{$self->{struct}});
					      if ($self->{session}) {
						$maindb->commit();
						$self->{session} = 0;
						print "ok\n";
					      }
					    },
					    rollback => sub {
					      my ($self) = @_;
					      my $maindb = tied(%{$self->{struct}});
					      if ($self->{session}) {
						$maindb->rollback();
						$self->{session} = 0;
						print "ok\n";
					      }
					    },
					    name => $dbfile,
					    struct => $db,
					    export => sub {
					      my ($db) = @_;
					      return tied(%{$db})->export();
					    }
					     );
  return $shell;
}

sub opendb {
  my ($dbfile, %dbparams) = @_;
  my $db;
  if (tie my %db, 'DBM::Deep', %dbparams) {
    $db = \%db;
  }
  else {
    die "Could not open dbfile $dbfile: $!\n";
  }
  return $db;
}

sub _export {
  my ($file, $dbfile, %dbparams) = @_;
  my $db = &opendb($dbfile, %dbparams);
  my $fd;
  if ($file eq '-') {
    $fd = *STDOUT;
  }
  else {
    open $fd, ">$file" or die "Could not open export file $file for writing: $!\n";
  }
  print $fd YAML::Dump(tied(%{$db})->export());
  close $fd;
}

sub _import {
  my ($file, $dbfile, %dbparams) = @_;
  my $db = &opendb($dbfile, %dbparams);
  my $fd;
  if ($file eq '-') {
    $fd = *STDIN;
  }
  else {
    open $fd, "<$file" or die "Could not open import file $file for reading: $!\n";
  }
  my $yaml = join '', <$fd>;
  my $perl = YAML::Load($yaml);
  tied(%{$db})->import($perl);
  close $fd;
}


1;

=head1 NAME

DBM::Deep::Manager - A container for functions for the dbmdeep program

=head1 SYNOPSIS

If you want to know about the L<dbmdeep> program, see the L<dbmdeep> file itself.
No user-serviceable parts inside. ack is all that should use this.

=head1 AUTHOR

T.v.Dein <tlinden@cpan.org>

=head1 BUGS

Report bugs to
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBM::Deep::Manager

=head1 SEE ALSO

L<dbmtree>

L<DBM::Deep>

L<Data::Interactive::Inspect>

=head1 COPYRIGHT

Copyright (c) 2015 by T.v.Dein <tlinden@cpan.org>.
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 VERSION

This is the manual page for B<DBM::Deep::Manager> Version 0.03.

=cut
