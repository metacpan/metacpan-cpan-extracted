use MooseX::Declare;
# Dist::Zilla: -PodWeaver

class Moses::Declare::Syntax::PluginKeyword extends
  MooseX::Declare::Syntax::Keyword::Class {

    use aliased 'Moses::Declare::Syntax::EventKeyword';

    before add_namespace_customizations( Object $ctx, Str $package) {
        $ctx->add_preamble_code_parts( 'use Moses::Plugin', );
    };
    use Moose::Util::TypeConstraints;

    class_type 'POE::Session';
    class_type 'POE::Kernel';
    around default_inner {
        my $val = $self->$orig(@_);
        push @$val,
          (
            EventKeyword->new(
                identifier => 'on',
                prototype_injections =>
                  { declarator => 'on', injections => ['ArrayRef $poe_args'], },
            ),
          );
        return $val;
    };

}

__END__
