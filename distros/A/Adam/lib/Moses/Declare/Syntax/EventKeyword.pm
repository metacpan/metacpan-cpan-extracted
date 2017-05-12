use MooseX::Declare;
# Dist::Zilla: -PodWeaver

class Moses::Declare::Syntax::EventKeyword extends
  MooseX::Declare::Syntax::Keyword::Method {

    sub register_method_declaration {
        my ( $self, $meta, $name, $method ) = @_;
        my $wrapper = sub {
            $method->(
   				[ @_[ 1 .. POE::Session::ARG0() - 1 ] ],	
                $_[0],
                @_[ POE::Session::ARG0() .. $#_ ],
            );
        };
        $meta->add_state_method( $name => $wrapper );
    }
}
1;

__END__

