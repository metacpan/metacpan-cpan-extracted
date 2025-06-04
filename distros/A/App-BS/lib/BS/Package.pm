use Object::Pad qw(:experimental(:all));

package BS::Package;

class BS::Package : does(BS::Package::Meta);

use utf8;
use v5.40;

use Carp;
use List::Util 'any';
use File::chdir;
use Path::Tiny;
use File::Temp;

method updchecksums : common {
    $class->bsx( ['updchecksums'] );
}

method writesrcinfo : common ($out, @makepkg_args) {
    $class->printsrcinfo( $out, @makepkg_args )->out;
}

method printsrcinfo : common ($out, @makepkg_args) {
    $class->bsx(
        [ 'makepkg', '--printsrcinfo', @makepkg_args ],
        out => ( ref $out eq 'ARRAY' ? $out : \$out )
    );
}

method fetch : common ($pkgstr, %args) {
    my $pkgres   = BS::Package::Meta->resolve_base($pkgstr);
    my $srccache = path( $args{srccache} // $args{dest} );
    my $workdir  = Path::Tiny->tempdir;
    my $res;

    if ( lc( $args{repo} ) eq 'aur' ) {
        $res = $class->bsx( [qw(git clone --bare $)] );
    }
    elsif (
        any { $args{repo}->{name} eq $_ && $args{repo}->{base_uri} }
        keys $args{repo_enabled}->%*
      )
    {
        $res = $class->bsx( [qw(git clone --bare $)] );
    }
    else {
        $res = $class->bsx(
            [ qw(pkgctl repo clone --protocol=https), $$pkgres{base} ] );
    }

    carp $res->out;

    $class->bsx(
        [
            qw(git clone), "$srccache/$$pkgres{base}",
            "$workdir/$$pkgres{base}"
        ]
    );

    carp $res->out;
}
