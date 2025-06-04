use Object::Pad;

package BS::Ext::pacsift;
role BS::Ext::pacsift : does(BS::Package::Meta);

use utf8;
use v5.40;

method $parse_line : common ($line, %opts) {};

method $out : common ($line, %opts) {};

method provides : common ($pkgstr, %opts) {
    my $out = $opts{out} //= [];
    my $res = BS::Common->bsx(
        [ qw(pacsift), $opts{args}->@*, '--provides', '<&-' ],
        in   => undef,
        dest => $out,
        out  => sub { $class->$out(@_) }
    );
}
