package Data::Format::Validate::URN;
our $VERSION = q/0.3/;

use Carp;
use base 'Exporter';

our @EXPORT_OK = qw/
    looks_like_urn
/;

our %EXPORT_TAGS = (
    q/all/ => [qw/
        looks_like_urn
    /]
);

sub looks_like_urn ($) {

    my $urn = shift;
    $urn =~ /^
        urn:                                # URN indicator
        [A-Z0-9]                            # First caracter (must be alphanumeric)
        [A-Z0-9-]{0,31}:                    # First word in URN (max of 32 caracters)
        [-A-Z0-9()+,\\.:=@;\$_!*'%\/?#]+    # Rest of URN (almost any caracters)
    $/ix
}
1;

=pod

=encoding utf8

=head1 NAME

Data::Format::Validate - A URN validating module.

=head1 SYNOPSIS

Function-oriented module capable of validating the format of any URN.

=head1 UTILITIES

=over 4

=item URN

    use Data::Format::Validate::URN 'looks_like_urn';

    looks_like_urn 'urn:oid:2.16.840';          # returns 1
    looks_like_urn 'This is not a valid URN';   # returns 0

=back

=head1 CONTRIBUITION

This source is on Github:

	https://github.com/rozcovo/Data-Format-Validate/blob/master/lib/Data/Format/Validate/URN.pm

=head1 AUTHOR

Created by Israel Batista <rozcovo@cpan.org>

=cut
