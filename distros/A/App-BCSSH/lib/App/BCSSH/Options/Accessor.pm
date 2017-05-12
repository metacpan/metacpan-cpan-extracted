package App::BCSSH::Options::Accessor;
use strictures 1;
use Package::Variant
    importing => ['Role::Tiny'],
    subs => [ qw(before after) ],
;
use Carp;

sub make_variant {
    my ($class, $target_package, $cb) = @_;

    before generate_method => sub {
        my ($self, $into, $name, $spec) = @_;
        if (my $arg_spec = delete $spec->{arg_spec}) {
            my $attr = $name;
            if (exists $spec->{init_arg}) {
                if (!defined $spec->{init_arg}) {
                    croak "Can't define a arg_spec for an attribute with init_arg => undef";
                }
                $attr = $spec->{init_arg};
            }
            $cb->($into, $attr, $arg_spec);
        }
    };
}

1;
__END__

=head1 NAME

App::BCSSH::Options::Accessor - Role for accessors with option parsing

=head1 SYNOPSIS

    use App::BCSSH::Options::Accessor;
    with Accessor(sub {
        my ($into, $attr, $arg_spec) = @_
        # handle accessor creation
    });

=cut
