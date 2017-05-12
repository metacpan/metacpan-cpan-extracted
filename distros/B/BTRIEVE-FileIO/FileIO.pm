package BTRIEVE::FileIO;

$VERSION = '0.05';

use BTRIEVE::Native();

sub StepFirst    { $_[0]->_Step( 33 ) }
sub StepLast     { $_[0]->_Step( 34 ) }
sub StepNext     { $_[0]->_Step( 24 ) }
sub StepPrevious { $_[0]->_Step( 35 ) }

sub GetFirst     { $_[0]->_Get ( 12 ) }
sub GetLast      { $_[0]->_Get ( 13 ) }
sub GetEqual     { $_[0]->_Get (  5 ) }
sub GetGreater   { $_[0]->_Get (  8 ) }
sub GetNext      { $_[0]->_Get (  6 ) }
sub GetPrevious  { $_[0]->_Get (  7 ) }

sub IsOk         { $_[0]->{Status} ? 0 : 1 }

# -----------------------------------------------------------------------------
sub Create
# -----------------------------------------------------------------------------
{
  my $class = shift;
  my $File  = shift;
  my $FSpec = shift || {};
  my $KSpec = shift || [];
  my $self  = {};

  my $DefFSpec =
  {
    LogicalRecordLength                => 128
  , PageSize                           => 512
  , NumberOfIndexes                    => scalar @$KSpec
  , FileFlags                          => 0
  , NumberOfDuplicatePointersToReserve => 0
  , Allocation                         => 0
  };
  %$FSpec = ( %$DefFSpec, %$FSpec );
  my @FSpec = @$FSpec
  {
   'LogicalRecordLength'
  ,'PageSize'
  ,'NumberOfIndexes'
  ,'FileFlags'
  ,'NumberOfDuplicatePointersToReserve'
  ,'Allocation'
  };
  my $DefKSpec =
  {
    KeyPosition               => 1
  , KeyLength                 => 1
  , KeyFlags                  => 0
  , ExtendedDataType          => 0
  , NullValue                 => 0
  , ManuallyAssignedKeyNumber => 0
  , ACSNumber                 => 0
  };
  $self->{Pos}  = "\0" x 128;
  $self->{Size} = 16 + @$KSpec * 16;
  $self->{Data} = pack 'SSSx4SCxS', @FSpec;

  for ( @$KSpec )
  {
    my %KSpec = ( %$DefKSpec, %$_ );
    my @KSpec = @KSpec
    {
     'KeyPosition'
    ,'KeyLength'
    ,'KeyFlags'
    ,'ExtendedDataType'
    ,'NullValue'
    ,'ManuallyAssignedKeyNumber'
    ,'ACSNumber'
    };
    $self->{Data} .= pack 'SSSx4CCx2CC', @KSpec;
  }
  $self->{Key} = $File;

  $self->{Status} = BTRIEVE::Native::Call
  (
    14
  , $self->{Pos}
  , $self->{Data}
  , $self->{Size}
  , $self->{Key}
  , 0
  );
  return bless $self, $class if $self->{Status};

  $class->Open( $File );
}
# -----------------------------------------------------------------------------
sub Open
# -----------------------------------------------------------------------------
{
  my $class = shift;
  my $File  = shift;
  my $self  = {};

  $self->{Pos}    = "\0" x 128;
  $self->{Size}   = 255;
  $self->{Data}   = "\0" x $self->{Size};
  $self->{Key }   = "\0" x 255;
  $self->{KeyNum} = 0;
  $self->{Status} = 0;

  $self->{Status} = BTRIEVE::Native::Call
  (
    0
  , $self->{Pos}
  , $self->{Data}
  , $self->{Size}
  , $File
  , 0
  );
  bless $self, $class;
}
# -----------------------------------------------------------------------------
sub Close
# -----------------------------------------------------------------------------
{
  my $self = shift;

  $self->{Status} = BTRIEVE::Native::Call
  (
    1
  , $self->{Pos}
  , $self->{Data}
  , $self->{Size}
  , $self->{Key}
  , 0
  );
  $self->IsOk;
}
# -----------------------------------------------------------------------------
sub Insert
# -----------------------------------------------------------------------------
{
  my $self = shift;

  $self->{Data} = shift if @_;

  $self->{Status} = BTRIEVE::Native::Call
  (
    2
  , $self->{Pos}
  , $self->{Data}
  , $self->{Size}
  , $self->{Key}
  , -1
  );
  $self->IsOk;
}
# -----------------------------------------------------------------------------
sub _Step
# -----------------------------------------------------------------------------
{
  my $self = shift;
  my $Op   = shift;

  $self->{Data} = "\0" x $self->{Size};

  $self->{Status} = BTRIEVE::Native::Call
  (
    $Op
  , $self->{Pos}
  , $self->{Data}
  , $self->{Size}
  , $self->{Key}
  , 0
  );
  $self->IsOk;
}
# -----------------------------------------------------------------------------
sub _Get
# -----------------------------------------------------------------------------
{
  my $self = shift;
  my $Op   = shift;

  $self->{Data} = "\0" x $self->{Size};

  $self->{Status} = BTRIEVE::Native::Call
  (
    $Op
  , $self->{Pos}
  , $self->{Data}
  , $self->{Size}
  , $self->{Key}
  , $self->{KeyNum}
  );
  $self->IsOk;
}
# -----------------------------------------------------------------------------
sub DESTROY
# -----------------------------------------------------------------------------
{
  my $self = shift;

  $self->Close;
}
# -----------------------------------------------------------------------------
1;

=head1 NAME

BTRIEVE::FileIO - Btrieve file I/O operations

=head1 SYNOPSIS

  use BTRIEVE::FileIO();

  my $B = BTRIEVE::FileIO->Open('TEST.BTR');

  $B->{Size} = 13;

  for ( $B->StepFirst; $B->IsOk; $B->StepNext )
  {
    print join(':', unpack('A3A10', $B->{Data} ) ), "\n";
  }

  $B->{Key} = 103;

  for ( $B->GetEqual; $B->IsOk; $B->GetNext )
  {
    print join(':', unpack('A3A10', $B->{Data} ) ), "\n";
  }

=head1 DESCRIPTION

This module provides methods for common Btrieve operations.

=head2 Methods

=over

=item Create( $FileName, $FileSpec, $KeySpecs )

Creates a Btrieve file. This is a constructor method and returns an
BTRIEVE::FileIO object.

$FileSpec is a hash reference with the following defaults:

  LogicalRecordLength                => 128
  PageSize                           => 512
  FileFlags                          => 0
  NumberOfDuplicatePointersToReserve => 0
  Allocation                         => 0

$KeySpecs is an array reference of hash references with the following
defaults:

  KeyPosition               => 1
  KeyLength                 => 1
  KeyFlags                  => 0
  ExtendedDataType          => 0
  NullValue                 => 0
  ManuallyAssignedKeyNumber => 0

=item Open( $FileName )

Opens a Btrieve file. This is a constructor method and returns an
BTRIEVE::FileIO object.

=item Close

Closes a Btrieve file associated with an BTRIEVE::FileIO object.
This method is called automatically from within DESTROY.

=item IsOk

Tests the Status property. It returns true if Status indicates
success and false if Status indicates an error.

=item Insert( $Data )

Inserts $Data into the Btrieve file. If $Data is omitted,
the Data property is used instead.

=item StepFirst

Retrieves the physical first record of the file.

=item StepLast

Retrieves the physical last record of the file.

=item StepNext

Retrieves the physical next record of the file.

=item StepPrevious

Retrieves the physical previous record of the file.

=item GetFirst

Retrieves the logical first record of the file,
based on the KeyNum property.

=item GetLast

Retrieves the logical last record of the file,
based on the KeyNum property.

=item GetEqual

Retrieves a record which key is equal to the one specified
by the Key/KeyNum properties.

=item GetGreater

Retrieves a record which key is greater than the one specified
by the Key/KeyNum properties.

=item GetNext

Retrieves the logical next record of the file.

=item GetPrevious

Retrieves the logical previous record of the file.

=back

=head2 Properties

=over

=item Data

The data buffer used to transfer data from and to the Btrieve file.

=item Size

The size of the data buffer. Default is 255.

=item KeyNum

The number of the key used for logical (key based) data retrieval operations.
Default is 0.

=item Key

The buffer of the key used for logical (key based) data retrieval operations.

=item Status

The status code. This is the return value of the native Btrieve call.
It contains 0 for success or a native error code.

=back

=head1 AUTHOR

Steffen Goeldner <sgoeldner@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004 Steffen Goeldner. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<BTRIEVE::Native>.

=cut
