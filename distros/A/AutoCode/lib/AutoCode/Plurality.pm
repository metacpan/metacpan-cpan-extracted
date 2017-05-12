package AutoCode::Plurality;
use strict;
use AutoCode::Root;
our @ISA=qw(AutoCode::Root);

our %REGISTERED;

sub add_plural {
    my ($class, $singular, $plural)=@_;
    $REGISTERED{$singular}=$plural;
}

sub query_plural {
    my ($class, $singular)=@_;
    (exists $REGISTERED{$singular})?$REGISTERED{$singular}:"${singular}s";
}

sub plural_ref {
    my ($self, $singular)=@_;
    [$singular, $REGISTERED{$singular}];
}

sub plural_deref {
    my ($class, $accessor)=@_;
    (ref($accessor) eq 'ARRAY')? @$accessor: ($accessor, "${accessor}s");
}

1;
