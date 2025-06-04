use Object::Pad ':experimental(:all)';

package BS::Package::Meta;
role BS::Package::Meta : does(BS::Common) : does(BS::alpm);

use utf8;
use v5.40;

use Carp;
use Const::Fast;
use Const::Fast::Exporter;
use List::Util qw(any);
use Data::Printer;
use Struct::Dumb;
use Syntax::Keyword::MultiSub;

const our $VALID_PKG_RE_CCLASS_START => "a-zA-Z0-9\@_\+";
const our $VALID_PKG_RE_NB => (
    qr/[$VALID_PKG_RE_CCLASS_START]{1}[$VALID_PKG_RE_CCLASS_START\.\-]+(\.so)
    |[$VALID_PKG_RE_CCLASS_START]{1}[$VALID_PKG_RE_CCLASS_START\.\-]+/
);

struct PkgDepends   => [qw(make optional check depends)];
struct PkgChecksums => [qw(ck md5 sha1 sha256 sha512 b2)];

#field $pkgname : param(name);

#field $name = [ ref $pkgname eq 'ARRAY' ? $pkgname->@* : $pkgname ];
#field $name{ ref $pkgname eq 'ARRAY' ? $pkgname : [$pkgname] };
#field $base : param { $pkgname unless defined ref $pkgname };

field $depends : param   = undef;
field $pkgver : param    = undef;
field $pkgrel : param    = undef;
field $pkgdesc : param   = undef;
field $url : param       = undef;
field $changelog : param = undef;

field @license;
field @source;
field @validpgpkeys;
field @noextract;
field @groups;
field @arch;
field @backup;
field @conflicts;
field @replaces;
field @provides;
field $options;
field $checksums;

#field $srcinfo : param;
field $srcinfo_path;

ADJUSTPARAMS($params) {

    #$self->_srcinfo_unpack_into
}

method resolve_base : common ($line, %args) {
    const my $PACINFO_SO_PREFIX => qr/(?:lib\:)?/;
    const my $DEP_SO_RE         => qr/\.so/;
    const my $VALID_DEPIDEN_RE =>
      qr/$PACINFO_SO_PREFIX($VALID_PKG_RE_NB)(?:$DEP_SO_RE)?/;
    const my $DEP_ATTRSEP_RE => qr/(?:\=)|(?:[\<\>]\=?)|(?:(?:\:))|(?:\.)/;
    const my $DEP_ATTR_RE =>
      qr/^$VALID_DEPIDEN_RE(?:\s*($DEP_ATTRSEP_RE)\s*(.+))?\n?$/;

    my ( $depname, $soext, $sep, $attr ) = $line =~ $DEP_ATTR_RE;
    my %dep_pkgargs = ();

    $dep_pkgargs{name} = $depname;

    if ($sep) {
        if ( $sep ne ':' ) {
            $dep_pkgargs{version} = $attr;
            $dep_pkgargs{cmp_op}  = $sep;
            $dep_pkgargs{file}    = $depname if $soext;
        }
        elsif ( $sep eq ':' ) {    # Optional dependency most likely
                                   # Will have parsed that out elsewhere
            $dep_pkgargs{description} = $attr;
            $dep_pkgargs{name}        = $depname;
        }
    }

    if ($soext) {
        $dep_pkgargs{file} //= $depname;

        my $res   = BS::Ext::pacman->file_query($depname);
        my $match = $res->out->[-1];
        chomp $match;

        ( $dep_pkgargs{repo}, $dep_pkgargs{name} ) = ( split /\//, $match );
    }

    if ( $args{resolve_base} // $ENV{RESOLVE_BASE} // 1 ) {
        try {
            $dep_pkgargs{base} //= BS::Ext::pacinfo->pkgbase(
                $dep_pkgargs{name},
                resolve_deps => 0,
                no_dupes     => 1
            );

            $dep_pkgargs{base} = $dep_pkgargs{base}->out if $dep_pkgargs{base};

            croak %dep_pkgargs unless $dep_pkgargs{base}
        }
        catch ($e) {
            my $res = BS::Ext::pacman->pkg_query( $dep_pkgargs{name} );

            BS::Common::dmsg $res;
            chomp $res->out->[-1];

            try {
                $dep_pkgargs{base} //= BS::Ext::pacinfo->pkgbase(
                    $res->out->[-1],
                    resolve_deps => 0,
                    no_dupes     => 1
                );

                $dep_pkgargs{base} = $dep_pkgargs{base}->out
                  if $dep_pkgargs{base};
            }
            catch ($e) {
                croak np $e
            }
        }
    }

    if ( $args{fetch} ) {
        $class->fetch( $dep_pkgargs{base}, %args );
    }

    \%dep_pkgargs;
}

method parse_dep : common ($line, %args) {
    $class->resolve_base( $line, %args );
}

method from_srcinfo : common ($in, %args) {
    my $href =
      $class->parse_srcinfo( BS::Common->tie_file( $in, delete $args{out} ),
        %args );

    BS::Package->new( srcinfo => $href );
}

method parse_srcinfo : common ($in, %args) {
    my ( $as_aref, $as_path );
    BS::Common->open_as_href(
        $in, %args,
        parse_line => sub ( $line, %args ) {
            __PACKAGE__->parse_srcinfo_line( $line, %args );
        }
    );
}

method parse_srcinfo_line : common ($line, %args) {

    # Not sure if this bit is thread-safe, but there shouldn't be any
    # issues with usage in non-blocking event-loop or forking code
    state $_res_buff = $args{dest};
    $_res_buff = $args{dest}
      if keys $args{dest}->%* && $args{dest} ne $_res_buff;

    const my $SRCINFO_LINE_RE => qr/^([a-z0-9_]+)\s*=\s*(.+)\n?$/i;

    my ( $key, $val ) = ( $line =~ $SRCINFO_LINE_RE );
    return undef unless $key && $val;

    const my $DEPKEY_ANY_RE => qr/depends/i;

    if ( $key =~ $DEPKEY_ANY_RE ) {
        $val = $class->parse_dep( $val, %args );
    }

    return $key, $val;
}
