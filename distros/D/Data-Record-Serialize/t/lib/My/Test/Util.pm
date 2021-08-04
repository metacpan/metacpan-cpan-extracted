package My::Test::Util;

use Exporter::Shiny qw( is_string is_number $have_Convert_Scalar);

our $have_Convert_Scalar = eval { require Convert::Scalar; };

sub is_string {
    Convert::Scalar::pok( $_[0] );
}

sub is_number {
    Convert::Scalar::niok( $_[0] );
}

1;
