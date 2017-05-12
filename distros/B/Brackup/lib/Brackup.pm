package Brackup;
use strict;
use vars qw($VERSION);
$VERSION = '1.10';

use Brackup::Config;
use Brackup::ConfigSection;
use Brackup::File;
use Brackup::Metafile;
use Brackup::PositionedChunk;
use Brackup::StoredChunk;
use Brackup::Backup;
use Brackup::Root;     # aka "source"
use Brackup::Restore;
use Brackup::Target;
use Brackup::BackupStats;

1;

__END__

=head1 NAME

Brackup - Flexible backup tool.  Slices, dices, encrypts, and sprays across the net.

=head1 FURTHER READING

L<Brackup::Manual::Overview>

L<brackup>

L<brackup-restore>

L<brackup-target>


