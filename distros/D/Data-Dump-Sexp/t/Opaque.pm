package Opaque;

sub new { bless {}, shift }

sub to_sexp { Data::SExpression::Symbol->new('<opaque>') }

1
