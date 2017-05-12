package DB_File::SV18x;
$VERSION="0.06";

die "DB_File::SV18x is a dummy package without functionality.
Please try DB_File::SV185 or DB_File::SV186, whatever has been
built on your system";

__END__

=head1 NAME

DB_File::SV18x - Co-existence of berkeley db 1.85, 1.86 and 2+

=head1 SYNOPSIS

Identical to DB_File

=head1 DESCRIPTION

The DB_File::SV18x modules override the namespace used by the berkeley
db library with a namespace that allows the most prominent versions of
the library, namely 1.85 and 1.86, coexist with the current 2 or
higher in memory. Thus it offers both convenient transformations of
database files between different versions and allows a smooth upgrade
path from 1.8x to 2.0.

For usage information please consult the documentation for DB_File and
globally replace the token C<DB_File> by C<DB_File::SV185> or
C<DB_File::SV186> whatever is avilable on your system.

=head1 EXAMPLE

  use DB_File ();
  use DB_File::SV185 ();
  use Fcntl;
  $F = "str.db";
  tie(%h, 'DB_File', "$F.200",
      O_RDWR|O_CREAT, 0644, $DB_File::DB_HASH) or die; 
  tie(%i, 'DB_File::SV185', $F,
      O_RDONLY, 0644, $DB_File::SV185::DB_HASH) or die; 
  %h = %i;

This example does a conversion of a database file from 1.85 to
whatever is the current default in the DB_File module of the machine
that runs this code.

Note that berkeley db 2.0 comes with excellent conversion tools and
for mere conversion DB_File::SV18x is not necessary. Its usefulness
lies in the open coexistence.

=head1 AUTHOR

Andreas Koenig koenig@kulturbox.de

=cut

