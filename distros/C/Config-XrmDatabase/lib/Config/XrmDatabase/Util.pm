package Config::XrmDatabase::Util;

# ABSTRACT: Constants that won't change, and other utilitarian things.

use v5.26;
use warnings;

our $VERSION = '0.04';

use Config::XrmDatabase::Failure ':all';

use namespace::clean;

use Exporter 'import';

use experimental qw( signatures postderef );

my %CONSTANTS;
our ( %META, %RMETA ); # these get exported

BEGIN {
    %CONSTANTS = (
        TIGHT       => '.',
        SINGLE      => '?',
        LOOSE       => '*',
        VALUE       => '!!VALUE',
        MATCH_COUNT => '!!MATCH_COUNT',
    );

    %META = (
        $CONSTANTS{VALUE}       => 'value',
        $CONSTANTS{MATCH_COUNT} => 'match_count'
    );
    %RMETA = reverse %META;

    $CONSTANTS{META_QR} = qr/@{[ join '|', map { quotemeta } keys %META ]}/i;
}

# so we can use the scalars here without complaints
use vars map { '$' . $_ } keys %CONSTANTS;
{
    no strict 'refs';    ## no critic(ProhibitNoStrict)
    *{$_} = \( $CONSTANTS{$_} ) for keys %CONSTANTS;
}

use constant \%CONSTANTS;

our %EXPORT_TAGS = (
    scalar    => [ map "\$$_", keys( %CONSTANTS ) ],
    constants => [ keys( %CONSTANTS ) ],
    hashes    => [ qw( %META %RMETA ) ],
    funcs     => [
        qw( parse_resource_name parse_fq_resource_name
          normalize_key name_arr_to_str is_wildcard )
    ],
);


our @EXPORT_OK = ( map { @$_ } values %EXPORT_TAGS );

$EXPORT_TAGS{all} = \@EXPORT_OK;











sub parse_resource_name ( $name ) {

    {
        my $last = substr( $name, -1 );
        key_failure->throw(
            "last component of name may not be a binding operator: $name" )
          if $last eq TIGHT || $last eq SINGLE || $last eq LOOSE;
    }

    # all consecutive '.' characters are replaced with a single one.
    $name =~ s/[$TIGHT]+/$TIGHT/g;

    # any combination of '.' and '*' is replaced with a '*'
    $name =~ s/[${TIGHT}${LOOSE}]{2,}/$LOOSE/g;

    # toss out fields:
    #   - the tight binding operator; that is the default.
    #   - empty fields correspond to two sequential binding operators
    #     or a leading binding operator

    return [
        grep { $_ ne TIGHT && $_ ne '' }
          split( /([${TIGHT}${SINGLE}${LOOSE}])/, $name ) ];
}











sub parse_fq_resource_name ( $name ) {

    key_failure->throw(
        "cannot have '$LOOSE' or '$SINGLE' binding operators in a fully qualified name: $name"
      )
      if index( $name, SINGLE ) != -1
      or index( $name, LOOSE ) != -1;

    key_failure->throw(
        "cannot have multiple sequential '$TIGHT' binding operators in a fully qualified name: $name"
    ) if $name =~ /[$TIGHT]{2,}/;

    key_failure->throw(
        "last component of a fully qualified name must not be a binding operator: $name"
    ) if substr( $name, -1 ) eq TIGHT;

    key_failure->throw(
        "first component of a fully qualified name must not be a binding operator: $name"
    ) if substr( $name, 0, 1 ) eq TIGHT;

    return [ split( /[$TIGHT]/, $name ) ];
}











sub normalize_key( $key ) {
    $key =~ s/[$TIGHT]?[$LOOSE][$TIGHT]?/$LOOSE/g;
    return $key;
}









sub name_arr_to_str ( $name_arr ) {
    return normalize_key( join( +TIGHT, @$name_arr ) );
}










sub is_wildcard( $string ) {
    return $string eq TIGHT || $string eq LOOSE;
}


1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Config::XrmDatabase::Util - Constants that won't change, and other utilitarian things.

=head1 VERSION

version 0.04

=head1 SUBROUTINES

=head2 parse_resource_name

  $internal_name = parse_resource_name( $name );

Parse a string key name which may have wildcards into an
internal representation.  Exceptions will be thrown if the input is
not valid.

=head2 parse_fq_resource_name

  $internal_name = parse_fq_resource_name( $name );

Parse a fully qualified (no wildcards) string key name into an
internal representation.  Exceptions will be thrown if the input is
not fully qualified.

=head2 normalize_key

   $key = normalize_key( $key );

Takes a string representation of a key returns one which removes
extraneous binding operators (C<.>, C<?>, C<*>).  It does B<not>
validate the input.

=head2 name_arr_to_str

  $str = name_arr_to_str( \@array );

Given a key name in internal representation, return an non-normalized string name.

=head2 is_wildcard

   $bool = is_wildcard( $char );

Returns true if the character is a wildcard character (nominally C<*>
and C<?>).

=for Pod::Coverage TIGHT
SINGLE
LOOSE
VALUE
MATCH_COUNT

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-config-xrmdatabase@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Config-XrmDatabase

=head2 Source

Source is available at

  https://gitlab.com/djerius/config-xrmdatabase

and may be cloned from

  https://gitlab.com/djerius/config-xrmdatabase.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Config::XrmDatabase|Config::XrmDatabase>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
