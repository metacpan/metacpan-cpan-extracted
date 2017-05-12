use strict;
use warnings;
use Test::More tests => 6;
use Data::Polymorph;

BEGIN{
  sub die_like (&$;$){
    my $block = shift;
    my $regex = shift;
    if( eval{ $block->() ; 1 } ) {
      &fail(@_);
    }
    else {
      &like( $@, $regex, @_ );
    }
  }
}

{
  package t::000;
  @t::001::ISA = ( __PACKAGE__ );
}

my $p = Data::Polymorph->new;


die_like{
  $p->super_type('t::001');
} qr{t::001 is not a type};

die_like{
  $p->define_type_method('t::001' => foo => sub{});
} qr{unknown type: t::001};

die_like{
  $p->type_method('t::001' => foo =>);
} qr{t::001 is not a type};

die_like{
  $p->super_type_method('t::001' => foo =>);
} qr{t::001 is not a type};

die_like{
  $p->apply(bless({},'t::001') => foo =>);
} qr{method "foo" is not defined in t::001};

$p->define_class_method('t::000' => foo => sub{});

die_like{
  $p->super(bless({},'t::001') => 'foo');
} qr{method "SUPER::foo" is not defined in t::001};


1;
__END__
