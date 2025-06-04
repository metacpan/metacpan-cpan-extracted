use Object::Pad qw':experimental(:all)';

package BS::Ext::pacinfo;
role BS::Ext::pacinfo : does(BS::Package::Meta);

use utf8;
use v5.40;

use Carp;
use List::Util 'any';
use Const::Fast;
use Data::Dumper;

const our $DEBUG      => any { $_ } @ENV{qw(PKGBASE_DEBUG BS_DEBUG DEBUG)} || 0;
const our @VALID_KEYS => qw(Name Base Repository);
const our $VALID_KEY_RE => map { qr/^($_)$/i } join '|', (@VALID_KEYS);
const our $DEPKEY_RE    => qr/^(Requires|Optional Deps)$/i;

method info : common ($pkgstr, %args) {
    my ( @out, $err );
    my $res = BS::Common->bsx(
        [ 'pacinfo', $pkgstr ],
        out => \@out,
        in  => undef,
        err => \$err
    );

    die "$err"   if $err;
    die "$?: $!" if $res->cmdexit->[0] != 0;

    my %info = ();

    $res = $class->to_href( \@out, %args, dest => \%info );

    #warn Dumper $pkgstr, \%info, \%args, $res, $err if $DEBUG;

    \%info;
}

method pkgbase : common ($pkgstr, %args) {
    my $info = $class->info( $pkgstr, %args );

    #warn Dumper($info) if $ENV{DEBUG};
    ref $$info{base} eq 'ARRAY' ? $info->{base}[0] : $$info{base};
}

method to_href : common ($in, %args) {
    my $res = BS::Common->open_as_href(
        $in, %args,
        parse_line => sub ( $line, %args ) {
            my @parsed = $class->parse_line( $line, %args );
            warn Dumper( \@parsed ) if $DEBUG;
        }
    );

    #warn Dumper($res) if $DEBUG;

    $res;
}

method parse_line : common ($line, %args) {
    my ( $key, $value ) = map {
        $_ =~ s/$BS::Common::TRIM_RE/$1/;
        $_
    } ( split /:/, $line, 1 );

    $key = lc($key);

    $value = BS::Package::Meta->parse_dep( $value, %args )
      if ( $args{resolve_deps} // 1 ) && $key =~ $DEPKEY_RE;

    return undef unless $key && $value;

    my %debug = ( key => $key, val => $value );

    warn Dumper( \%debug ) if $DEBUG;

    $key, $value;
}
