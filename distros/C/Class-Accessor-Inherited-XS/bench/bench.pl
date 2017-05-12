#!perl
use Class::Accessor::Inherited::XS;
use Class::Accessor::Grouped;
use Class::XSAccessor;
use strict;
use Benchmark qw/cmpthese/;

BEGIN {
    sub __read_caxsi {}
    Class::Accessor::Inherited::XS::register_type(
        caxsi => {read_cb => \&__read_caxsi}
    );
}

use CAIXS {
    package => 'CCC',
    object  => 'caixo',
    class   => 'caixc',
    caxsi   => 'caxsi',
};

my $o = CCC->new;
$o->a(3);
$o->caixc(42);
$o->caxsi(43);
$o->caixo(44);

my $o2 = CCC2->new;
$o2->a(4);
$o2->simple(5);

AAA->a(7);
AAA2->a(8);

cmpthese(
    -2,
    {
        pkg_caix          => sub { AAA->a },
        pkg_cag           => sub { AAA2->a },
        pkg_gparent_caix  => sub { CCC->a },
        pkg_gparent_cag   => sub { CCC2->a },
        pkg_set_caix      => sub { AAA->a(42) },
#        pkg_set_cag       => sub { AAA2->a(42) },
#        class_set_caix    => sub { $o->caixc(42) },
        class_caix        => sub { $o->caixc },
        obj_caix          => sub { $o->caixo },
        obj_caix_cb       => sub { $o->caxsi },
        obj_cag           => sub { $o2->a },
        obj_cxa           => sub { $o2->simple },
        obj_direct        => sub { $o2->{a} },
    }
);

BEGIN {
    package AAA;
    use base qw/Class::Accessor::Inherited::XS/;
    use strict;

    sub new { return bless {}, shift }

    AAA->mk_inherited_accessors(qw/a/);

    package BBB;
    use base 'AAA';

    package CCC;
    use base 'BBB';

    package AAA2;
    use base qw/Class::Accessor::Grouped/;
    use strict;

    sub new { return bless {}, shift }

    AAA2->mk_group_accessors(inherited => qw/a/);
    AAA2->mk_group_accessors(simple    => qw/simple/);

    package BBB2;
    use base 'AAA2';

    package CCC2;
    use base 'BBB2';

    1;
}
