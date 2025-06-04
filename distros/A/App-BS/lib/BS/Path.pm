use Object::Pad ':experimental(:all)';

package BS::Path;

role BS::Path;

use utf8;
use v5.40;

class Path {
    use utf8;
    use v5.40;

    use BS::Common;
    use Path::Tiny;

    field $pathstr : param(path);
    field $_path : mutator($path);    #{ path($pathstr) };

    method BUILDARGS : common ($path, %opts) {
        ( path => $path, %opts );
    }

    ADJUSTPARAMS($params) {

        $_path = path($pathstr);
        BS::Common::dmsg(
            {
                self     => $self,
                params   => $params,
                caller_0 => [ caller 0 ]
            }
        );
    };

    method exists {
        $_path->exists;
    }

    method basename (@suffixes) {
        push @suffixes, $ENV{PKGEXT}
          unless scalar @suffixes;

        $_path->basename(@suffixes);
    }

    method if_exists {
        $self->exists ? $_path : undef;
    }
};

method path : common ($path) { Path->new($path) }

method if_exists : common ($path) {
    my $bspath = $class->path($path);
    ( $bspath->exists ? $bspath : undef );
}
