package D64::Disk::Status::Factory;

=head1 NAME

D64::Disk::Status::Factory - Factory class to create L<D64::Disk::Status> objects for all existing 1541 DOS error messages

=head1 SYNOPSIS

  use D64::Disk::Status::Factory;

  # Create a new disk status object instance:
  my $status = D64::Disk::Status::Factory->new($error_code);

=head1 DESCRIPTION

C<D64::Disk::Status::Factory> is a factory class to create C<D64::Disk::Status> objects for all existing 1541 DOS error messages.

=head1 METHODS

=cut

use bytes;
use strict;
use utf8;
use warnings;

our $VERSION = '0.03';

use D64::Disk::Status;
use Data::Dumper;
use Readonly;

our %errors = (
    0 => {
        error       => 'OK',
        message     => 'OK',
        description => '',
    },
    1 => {
        error       => 'FILES SCRATCHED',
        message     => 'files scratched',
        description => '',
    },
    20 => {
        error       => 'READ ERROR',
        message     => 'block header not found',
        description => 'The disk controller is unable to locate the header of the requested data block. Caused by an illegal block number, or the header has been destroyed.',
    },
    21 => {
        error       => 'READ ERROR',
        message     => 'sync character not found',
        description => 'The disk controller is unable to detect a sync mark on the desired track. Caused by misalignment of the read/writer head, no diskette is present, or unformatted or improperly seated diskette.',
    },
    22 => {
        error       => 'READ ERROR',
        message     => 'data block not present',
        description => 'The disk controller has been requested to read or verify a data block that was not properly written. This error message occurs in conjunction with the BLOCK commands and indicates an illegal track and/or block request.',
    },
    23 => {
        error       => 'READ ERROR',
        message     => 'checksum error in data block',
        description => 'This error message indicates that there is an error in one or more of the data bytes. The data has been read into the DOS memory, but the checksum over the data is in error.',
    },
    24 => {
        error       => 'READ ERROR',
        message     => 'byte decoding error',
        description => 'The data or header has been read into the DOS memory, but a hardware error has been created due to an invalid bit pattern in the data byte.',
    },
    25 => {
        error       => 'WRITE ERROR',
        message     => 'write-verify error',
        description => 'This message is generated if the controller detects a mismatch between the written data and the data in the DOS memory.',
    },
    26 => {
        error       => 'WRITE PROTECT ON',
        message     => 'attempt to write with write protect on',
        description => 'This message is generated when the controller has been requested to write a data block while the write protect switch is depressed.',
    },
    27 => {
        error       => 'READ ERROR',
        message     => 'checksum error in header',
        description => 'The controller has detected an error in the header of the requested data block. The block has not been read into the DOS memory.',
    },
    28 => {
        error       => 'WRITE ERROR',
        message     => 'data extends into next block',
        description => 'The controller attempts to detect the sync mark of the next header after writing a data block. If the sync mark does not appear within a predetermined time, the error message is generated. The error is caused by a bad diskette format (the data extends into the next block), or by hardware failure.',
    },
    29 => {
        error       => 'DISK ID MISMATCH',
        message     => 'disk id mismatch',
        description => 'This message is generated when the controller has been requested to access a diskette which has not been initialized. The message can also occur if a diskette has a bad header.',
    },
    30 => {
        error       => 'SYNTAX ERROR',
        message     => 'general syntax error',
        description => 'The DOS cannot interpret the command sent to the command channel. Typically, this is caused by an illegal number of file names, or patterns are illegally used. For example, two file names may appear on the left side of the COPY command.',
    },
    31 => {
        error       => 'SYNTAX ERROR',
        message     => 'invalid command',
        description => 'The DOS does not recognize the command. The command must start in the first position.',
    },
    32 => {
        error       => 'SYNTAX ERROR',
        message     => 'long line',
        description => 'The command sent is longer than 58 characters.',
    },
    33 => {
        error       => 'SYNTAX ERROR',
        message     => 'invalid filename',
        description => 'Pattern matching is invalidly used in the OPEN or SAVE command.',
    },
    34 => {
        error       => 'SYNTAX ERROR',
        message     => 'no file given',
        description => 'The file name was left out of a command or the DOS does not recognize it as such. Typically, a colon (:) has been left out of the command.',
    },
    39 => {
        error       => 'FILE NOT FOUND',
        message     => 'command file not found',
        description => 'This error may result if the command sent to command channel (secondary address 15) is unrecognized by the DOS.',
    },
    50 => {
        error       => 'RECORD NOT PRESENT',
        message     => 'record not present',
        description => 'Result of disk reading past the last record through INPUT#, or GET# commands. This message will also occur after positioning to a record beyond end of file in a relative file. If the intent is to expand the file by adding the new record (with a PRINT# command), the error message may be ignored. INPUT or GET should not be attempted after this error is detected without first repositioning.',
    },
    51 => {
        error       => 'OVERFLOW IN RECORD',
        message     => 'overflow in record',
        description => 'PRINT# statement exceeds record boundary. Information is cut off. Since the carriage return is sent as a record terminator is counted in the record size. This message will occur if the total characters in the record (including the final carriage return) exceed the defined size.',
    },
    52 => {
        error       => 'FILE TOO LARGE',
        message     => 'file too large',
        description => 'Record position within a relative file indicates that disk overflow will result.',
    },
    60 => {
        error       => 'WRITE FILE OPEN',
        message     => 'file open for write',
        description => 'This message is generated when a write file that has not been closed is being opened for reading.',
    },
    61 => {
        error       => 'FILE NOT OPEN',
        message     => 'file not open',
        description => 'This message is generated when a file is being accessed that has not been opened in the DOS. Sometimes, in this case, a message is not generated, the request is simply ignored.',
    },
    62 => {
        error       => 'FILE NOT FOUND',
        message     => 'file not found',
        description => 'The requested file does not exist on the indicated drive.',
    },
    63 => {
        error       => 'FILE EXISTS',
        message     => 'file exists',
        description => 'The file name of the file being created already exists on the diskette.',
    },
    64 => {
        error       => 'FILE TYPE MISMATCH',
        message     => 'file type mismatch',
        description => 'The file type does not match the file type in the directory entry for the requested file.',
    },
    65 => {
        error       => 'NO BLOCK',
        message     => 'no block',
        description => 'This message occurs in conjunction with the B-A command. It indicates that the block to be allocated has been previously allocated. The parameters indicate the track and sector available with the next highest number. If the parameters are zero (0), then all blocks higher in number are in use.',
    },
    66 => {
        error       => 'ILLEGAL TRACK OR SECTOR',
        message     => 'illegal track or sector',
        description => 'The DOS has attempted to access a track or block which does not exist in the format being used. This may indicate a problem reading the pointer to the next block.',
    },
    67 => {
        error       => 'ILLEGAL TRACK OR SECTOR',
        message     => 'illegal system track or sector',
        description => 'This special error message indicates an illegal system track or block.',
    },
    70 => {
        error       => 'NO CHANNEL',
        message     => 'no channels available',
        description => 'The requested channel is not available, or all channels are in use. A maximum of five sequential files may be opened at one time to the DOS. Direct access channels may have six opened files.',
    },
    71 => {
        error       => 'DIR ERROR',
        message     => 'directory error',
        description => 'The BAM does not match the internal count. There is a problem in the BAM allocation or the BAM has been overwritten in DOS memory. To correct this problem, reinitialize the diskette to restore the BAM in memory. Some active files may be terminated by the corrective action.',
    },
    72 => {
        error       => 'DISK FULL',
        message     => 'disk full or directory full',
        description => 'Either the blocks on the diskette are used or the directory is at its entry limit. DISK FULL is sent when two blocks are available on the 1541 to allow the current file to be closed.',
    },
    73 => {
        error       => 'CBM DOS V2.6 1541',
        message     => 'power up message, or write attempt with dos mismatch',
        description => 'DOS 1 and 2 are read compatible but not write compatible. Disks may be interchangeably read with either DOS, but a disk formatted on one version cannot be written upon with the other version because the format is different. This error is displayed whenever an attempt is made to write upon a disk which has been formatted in a non-compatible format. This message may also appear after power up.',
    },
    74 => {
        error       => 'DRIVE NOT READY',
        message     => 'drive not ready',
        description => 'An attempt has been made to access the 1541 Single Drive Floppy Disk without any diskettes present in either drive.',
    },
);

our $errors;
if ($] < 5.008) {
    eval q{ Readonly \\$errors => \\%errors; };
}
else {
   eval q{ Readonly $errors => \\%errors; };
}

=head2 new

Create a new disk status object instance:

  my $status = D64::Disk::Status::Factory->new($error_code);

C<$error_code> is one of pre-defined error codes for all existing CBM floppy error messages, and defaults to C<0> (which is no error, C<OK> status).

=cut

sub new {
    my ($class, @args) = @_;
    my $status = $class->_init(@args);
    return $status;
}

sub _init {
    my ($class, @args) = @_;

    unless (scalar (@args) <= 1) {
        die sprintf q{Unable to create status object: Invalid number of arguments (%s)}, $class->_dump(\@args);
    }

    my $code = shift (@args) || 0;

    if (ref $code) {
        die sprintf q{Unable to create status object: Invalid argument type (%s)}, ref $code;
    }

    unless ($code =~ m/^\d+$/) {
        die sprintf q{Unable to create status object: Illegal argument value (%s)}, $class->_dump($code);
    }

    unless (exists $errors->{$code}) {
        die sprintf q{Unable to create status object: Invalid error code number (%s)}, $class->_dump($code);
    }

    my %params = %{$errors->{$code}};
    $params{code} = $code;

    my $status = D64::Disk::Status->new(%params);
    return $status;
}

sub _dump {
    my ($class, $value) = @_;

    my $dump = Data::Dumper->new([$value])->Indent(0)->Terse(1)->Deepcopy(1)->Sortkeys(1)->Dump();

    return $dump;
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

None. No method is exported into the caller's namespace neither by default nor explicitly.

=head1 SEE ALSO

L<D64::Disk::Status>.

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.03 (2013-03-09)

=head1 COPYRIGHT AND LICENSE

Copyright 2013 by Pawel Krol E<lt>pawelkrol@cpan.orgE<gt>.

This library is free open source software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

PLEASE NOTE THAT IT COMES WITHOUT A WARRANTY OF ANY KIND!

=cut

1;

__END__
