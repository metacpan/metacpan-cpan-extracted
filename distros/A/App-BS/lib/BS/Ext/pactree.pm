use Object::Pad;

package BS::Ext::pactree;
role BS::Ext::pactree
  : does(BS::Package::Meta)
  : does(BS::Common)
  : does(BS::Ext);

use utf8;
use v5.40;

use Carp;
use List::Util 'uniq';
use Data::Printer;

method list_deps : common ($pkgstr, %args) {
    BS::Common::dmsg { pkgstr => $pkgstr, args => \%args };

    use constant DEFORDER_RE => qr/^asc.*/i;

    state $altorder =
      ( $args{default_order} // 'asc' ) =~ DEFORDER_RE ? 'desc' : 'asc';

    state $altorder_re = qr/^($altorder|r).*/i;

    my @deps;

    my @out = $class->tree(
        $pkgstr,
        linear   => 1,
        unique   => 1,
        sync     => 1,
        optional => 1,
        sync     => delete $args{sync},
        %args
    )->@*;

    foreach my $line (@out) {
        my $depargs = BS::Package::Meta->parse_dep( $line, %args );
        my $depid   = $$depargs{base} // $$depargs{name};

        push @deps, $depid
          unless $depid eq $pkgstr;
    }

    carp np @deps if $ENV{DEBUG};

    @deps = $args{unique} ? reverse uniq reverse @deps : @deps;

    @deps =
      ( $args{order} !~ $altorder_re )
      ? @deps
      : reverse @deps;

    join $args{sep} // ' ', @deps;
}

method tree : common ($pkgstr, %args) {
    carp "${class}::tree('$pkgstr', ...) args:"
      if $args{debug} // $ENV{DEBUG};

    my ( @flagsargs, @intsargs, @out, $in, $err );
    $args{optional} //= 1;

    foreach my ( $key, $value ) ( %args{qw(sync unique linear)} ) {
        push @flagsargs, substr $key, 0, 1 if $value;
    }

    foreach my ( $key, $value ) ( %args{qw(depth optional)} ) {
        push @intsargs, '-' . substr( $key, 0, 1 ) . $value if $value;
    }

    my $res = BS::Common->bsx(
        [ 'pactree', ( '-' . join '', @flagsargs ), @intsargs, $pkgstr ], %args,
        out => \@out,
        in  => undef,
        err => \$err
    );

    die "$err"   if $err;
    die "$?: $!" if $res->cmdexit->[0] != 0;

    carp np @out if $ENV{DEBUG};

    \@out;
}
