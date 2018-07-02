package Data::Format::Validate::URN;
our $VERSION = q/0.2/;

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

    $_ = shift;
    /^
        urn:
        [A-Z0-9][A-Z0-9-]{0,31}:
        [-A-Z0-9()+,\\.:=@;\$_!*'%\/?#]+
    $/ix
}
1;

=pod

=encoding utf8

=head1 NAME

Data::Format::Validate - A URN validating module.

=head1 SYNOPSIS

Module that validate URN addressess.

=head1 Utilities

=over 4

=item URN

    use Data::Format::Validate::URN 'looks_like_urn';

    looks_like_urn 'urn:oid:2.16.840';                                  # 1
    looks_like_urn 'urn:ietf:rfc:2648';                                 # 1
    looks_like_urn 'urn:issn:0167-6423';                                # 1
    looks_like_urn 'urn:isbn:0451450523';                               # 1
    looks_like_urn 'urn:mpeg:mpeg7:schema:2001';                        # 1
    looks_like_urn 'urn:uci:I001+SBSi-B10000083052';                    # 1
    looks_like_urn 'urn:lex:br:federal:lei:2008-06-19;11705';           # 1
    looks_like_urn 'urn:isan:0000-0000-9E59-0000-O-0000-0000-2';        # 1
    looks_like_urn 'urn:uuid:6e8bc430-9c3a-11d9-9669-0800200c9a66';     # 1

    looks_like_urn 'oid:2.16.840';                                      # 0
    looks_like_urn 'This is not a valid URN';                           # 0
    looks_like_urn 'urn:-768hgf-0000-0000-0000';                        # 0
    looks_like_urn 'urn:this-is-a-realy-big-URN-maybe-the-bigest';      # 0
    
=back

=head1 CONTRIBUITION

This source is on Github:

	https://github.com/rozcovo/Data-Format-Validate/blob/master/lib/Data/Format/Validate/URN.pm

=head1 AUTHOR

Created by Israel Batista <<israel.batista@univem.edu.br>>

=cut
