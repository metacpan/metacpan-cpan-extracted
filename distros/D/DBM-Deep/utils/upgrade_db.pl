#!perl

use 5.6.0;

use strict;
use warnings FATAL => 'all';

use FindBin;
use File::Spec ();
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );

# This is for the latest version.
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );

use Getopt::Long qw( GetOptions );
use Pod::Usage 1.3;

my %headerver_to_module = (
  '0' => 'DBM::Deep::09830',
  '2' => 'DBM::Deep::10002', 
  '3' => 'DBM::Deep',
  '4' => 'DBM::Deep',
);

my %is_dev = (
  '1' => 1,
);

my %opts = (
  man => 0,
  help => 0,
  version => '2',
  autobless => 1,
);
GetOptions( \%opts,
  'input=s', 'output=s', 'version:s', 'autobless:i',
  'help|?', 'man',
) || pod2man(2);
pod2usage(1) if $opts{help};
pod2usage(-exitstatus => 0, -verbose => 2) if $opts{man};

pod2usage(-msg => "Missing required parameters.", verbose => 1)
  unless $opts{input} && $opts{output};

if ( $opts{input} eq $opts{output} ) {
  _exit( "Cannot use the same filename for both input and output." );
}

unless ( -f $opts{input} ) {
  _exit( "'$opts{input}' is not a file." );
}

my %db;
{
  my $ver = _read_file_header( $opts{input} );
  if ( $is_dev{ $ver } ) {
    _exit( "'$opts{input}' is a dev release and not supported." );
  }

  my $mod = $headerver_to_module{ $ver };
  eval "use $mod;";
  if ( $@ ) {
      _exit( "Cannot load '$mod' to read header version '$ver':\n\t$@" );
  }
  $db{input} = $mod->new({
    file      => $opts{input},
    locking   => 1,
    autobless => $opts{autobless},
  });
  $db{input}->lock;
}

{
  my $ver = $opts{version};
  if ( $ver =~ /^2(?:\.|\z)/ ) {
    $ver = 4;
  }
  elsif ( $ver =~ /^1\.001[0-4]/ ) {
    $ver = 3;
  }
  elsif ( $ver =~ /^1\.000[3-9]/ ) {
    $ver = 3;
  }
  elsif ( $ver eq '1.00' || $ver eq '1.000' || $ver =~ /^1\.000[0-2]/ ) {
    $ver = 2;
  }
  elsif ( $ver =~ /^0\.99/ ) { 
    $ver = 1;
  }
  elsif ( $ver =~ /^0\.9[1-8]/ ) {
    $ver = 0;
  }
  else {
    _exit( "'$ver' is an unrecognized version." );
  }

  if ( $is_dev{ $ver } ) {
    _exit( "-version '$opts{version}' is a dev release and not supported." );
  }

  # First thing is to destroy the file, in case it's an incompatible version.
  unlink $opts{output};

  my $mod = $headerver_to_module{ $ver };
  eval "use $mod;";
  if ( $@ ) {
      _exit( "Cannot load '$mod' to read header version '$ver':\n\t$@" );
  }
  $db{output} = $mod->new({
    file      => $opts{output},
    locking   => 1,
    autobless => $opts{autobless},
  });
  $db{output}->lock;

  # Hack to write a version 3 file:
  if($ver == 3) {
    my $engine = $db{output}->_engine;
    $engine->{v} = 3;
    $engine->storage->print_at( 5, pack('N',3) );
  }
}

# Do the actual conversion. This is the code that compress uses.
$db{input}->_copy_node( $db{output} );
undef $db{output};

################################################################################

sub _read_file_header {
  my ($file) = @_;

  open my $fh, '<', $file
    or _exit( "Cannot open '$file' for reading: $!" );

  my $buffer = _read_buffer( $fh, 9 );
  _exit( "'$file' is not a DBM::Deep file." )
    unless length $buffer == 9;

  my ($file_sig, $header_sig, $header_ver) = unpack( 'A4 A N', $buffer );

  # SIG_FILE == 'DPDB'
  _exit( "'$file' is not a DBM::Deep file." )
    unless $file_sig eq 'DPDB';

  # SIG_HEADER == 'h' - this means that this is a pre-1.0 file
  return 0 unless ($header_sig eq 'h');

  return $header_ver;
}

sub _read_buffer {
  my ($fh, $len) = @_;
  my $buffer;
  read( $fh, $buffer, $len );
  return $buffer;
}

sub _exit {
  my ($msg) = @_;
  pod2usage( -verbose => 0, -msg => $msg );
}

__END__

=head1 NAME

upgrade_db.pl

=head1 SYNOPSIS

  upgrade_db.pl -input <oldfile> -output <newfile>

=head1 DESCRIPTION

This will attempt to upgrade DB files from one version of DBM::Deep to
another. The version of the input file is detected from the file header. The
version of the output file defaults to the version of the distro in this file,
but can be set, if desired.

=head1 OPTIONS

=over 4

=item B<-input> (required)

This is the name of original DB file.

=item B<-output> (required)

This is the name of target output DB file.

=item B<-version>

Optionally, you can specify the version of L<DBM::Deep> for the output file.
This can either be an upgrade or a downgrade. The minimum version supported is
0.91.

If the version is the same as the input file, this acts like a compressed copy
of the database.

=item B<-autobless>

In pre-1.0000 versions, autoblessing was an optional setting defaulting to
false. Autobless in upgrade_db.pl defaults to true.

=item B<-help>

Prints a brief help message, then exits.

=item B<-man>

Prints a much longer message, then exits;

=back

=head1 CAVEATS

The following are known issues with this converter.

=over 4

=item * Diskspace requirements

This will require about twice the diskspace of the input file.

=item * Feature support

Not all versions support the same features. In particular, internal references
were supported in 0.983, removed in 1.000, and re-added in 1.0003. There is no
detection of this by upgrade_db.pl.

=back

=head1 MAINTAINER(S)

Rob Kinyon, L<rkinyon@cpan.org>

Originally written by Rob Kinyon, L<rkinyon@cpan.org>

=head1 LICENSE

Copyright (c) 2007 Rob Kinyon. All Rights Reserved.
This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut
