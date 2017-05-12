use MooseX::Declare;

class CatalystX::Declare::Keyword::Model
    extends CatalystX::Declare::Keyword::Component {

    method default_superclasses { 'Catalyst::Model' }
}

__END__

=head1 NAME

CatalystX::Declare::Keyword::Model - Declare Catalyst Models

=head1 SYNOPSIS

    use CatalystX::Declare;

    model MyApp::Web::Model::Random {

        method upto (Int $n) { int(rand $n) }
    }

=head1 DESCRIPTION

This handler is a simple extension of L<CatalystX::Declare::Keyword::Component>
and defaults to L<Catalyst::Model> as superclass. Additionally, L<CLASS> will
be imported. See L<MooseX::Declare/class> for more information on usage, since
this keyword is subclass extending its parent's features.

=head1 SUPERCLASSES

=over

=item L<CatalystX::Declare::Keyword::Component>

=back

=head1 METHODS

These methods are implementation details. Unless you are extending or 
developing L<CatalystX::Declare>, you should not be concerned with them.

=head2 default_superclasses

    List[Str] Object->default_superclasses ()

Defaults to L<Catalyst::View>.

=head1 SEE ALSO

=over

=item L<CatalystX::Declare>

=item L<CatalystX::Declare::Keyword::Component>

=item L<MooseX::Declare/class>

=back

=head1 AUTHOR

See L<CatalystX::Declare/AUTHOR> for author information.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under 
the same terms as perl itself.

=cut
