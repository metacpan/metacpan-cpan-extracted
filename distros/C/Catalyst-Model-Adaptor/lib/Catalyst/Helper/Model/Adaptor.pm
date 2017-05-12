package Catalyst::Helper::Model::Adaptor;
use strict;
use warnings;

=head1 NAME

Catalyst::Helper::Model::Adaptor - helper for the incredibly lazy

=head1 SYNOPSIS

Running:

    ./script/myapp_create.pl model SomeClass Adaptor MyApp::Backend::SomeClass create

Will create C<YourApp::Model::SomeClass> that looks like:

    package YourApp::Model::SomeClass;
    use strict;
    use warnings;
    use base 'Catalyst::Model::Adaptor';
    
    __PACKAGE__->config( 
        class       => 'MyApp::Backend::SomeClass',
        constructor => 'create',
    );

    1;

Why you need a script to generate that is beyond me, but here it is.

=head1 ARGUMENTS

   ./script/myapp_create.pl model <model_name> Adaptor <class> [<constructor>]

You need to sepecify the C<model_name> (the name of the model), and
C<class>, the class being adapted.  If C<< $class->new >> isn't going
to do what you want, pass the name of C<$class>'s constructor as
C<constructor>.

=cut

sub mk_compclass {
    my ( $class, $helper, $adapted_class, $const ) = @_;
    my ($type) = ($class =~ /^Catalyst::Helper::Model::(.+)$/);
    die "i am nothing.  that doesn't make sense." unless $type;

    my %args = ( adapted_class => $adapted_class, 
                 constructor   => $const, 
                 type          => $type
               );
    
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file, \%args );
}

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as perl itself.

No copyright claim is asserted over the generated code.

=cut

1;

__DATA__

__compclass__
package [% class %];
use strict;
use warnings;
use base 'Catalyst::Model::[% type %]';

__PACKAGE__->config( 
    class       => '[% adapted_class || 'Fill::This::In' %]',
    constructor => '[% constructor   || 'new'%]',
);

1;
