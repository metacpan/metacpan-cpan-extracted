package Crypt::TSD;

use strict;
use warnings;

# This is an alias for Crypt::TimestampedData
# See https://metacpan.org/dist/Data-Printer/source/lib/DDP.pm for reference

# Import all functions from the main module
use Crypt::TimestampedData;

# Re-export everything
our @EXPORT = @Crypt::TimestampedData::EXPORT;
our @EXPORT_OK = @Crypt::TimestampedData::EXPORT_OK;
our %EXPORT_TAGS = %Crypt::TimestampedData::EXPORT_TAGS;

# Set version - will be synchronized by SyncVersionFromDist plugin
our $VERSION = '0.01';

# Make this module an alias
*Crypt::TSD:: = *Crypt::TimestampedData::;

1;

__END__

=head1 NAME

Crypt::TSD - Alias for Crypt::TimestampedData

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Crypt::TSD;
  
  # This is equivalent to:
  # use Crypt::TimestampedData;
  
  # All methods are available:
  my $tsd = Crypt::TSD->read_file('/path/file.tsd');
  Crypt::TSD->write_file('/path/out.tsd', $tsd);

=head1 DESCRIPTION

This is a convenient alias for L<Crypt::TimestampedData>. It provides
the same functionality with a shorter name for easier typing.

=head1 SEE ALSO

L<Crypt::TimestampedData> - The main module

=cut
