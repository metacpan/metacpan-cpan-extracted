package App::PerlNitpick::Nitpicker;
use Moose;

has file => (
    is => 'ro',
    required => 1,
    isa => 'Str',
);

has rules => (
    is => 'ro',
    required => 1,
    isa => 'ArrayRef[Str]',
);

has inplace => (
    is => 'ro',
    required => 1,
    default  => 0,
    isa => 'Bool',
);

use Module::Find qw( findallmod );
use PPI::Document ();

sub list_rules {
    my ($class) = @_;
    my @found = sort { $a cmp $b } findallmod( 'App::PerlNitpick::Rule' );
    my @rules = map { $_ =~ s{App::PerlNitpick::Rule::}{}; $_; } @found;
    for my $rule (@rules) {
        $rule =~ s/\A .+ :://x;
        print "$rule\n";
    }
    return;
}

sub rewrite {
    my ($self) = @_;

    my $ppi = PPI::Document->new( $self->file ) or return;
    for my $rule (@{$self->rules}) {
        my $rule_class = 'App::PerlNitpick::Rule::' . $rule;
        eval "require $rule_class" || die;

        $ppi = $rule_class->new->rewrite($ppi);
    }
    if ($self->inplace) {
        $ppi->save( $self->file );
    } else {
        $ppi->save( $self->file . ".new" );
    }
    return;
}

1;
