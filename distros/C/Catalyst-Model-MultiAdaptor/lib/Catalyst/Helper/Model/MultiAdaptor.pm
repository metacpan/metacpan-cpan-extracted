package Catalyst::Helper::Model::MultiAdaptor;
use strict;
use warnings;

=head1 NAME

Catalyst::Helper::Model::MultiAdaptor - helper for the incredibly lazy 

=head1 SYNOPSIS

Running:

    catalyst.pl model SomeClass MultiAdaptor MyApp::Service 

Will create C<MyApp::Model::SomeClass> that looks like:

    package MyApp::Model::SomeClass;
    use strict;
    use warnings;
    use base 'Catalyst::Model::MultiAdaptor';
    
    __PACKAGE__->config( 
        package       => 'MyApp::Service',
    );

    1;

Why you need a script to generate that is beyond me, but here it is.

=head1 ARGUMENTS

   catalyst.pl model <model_name> MultiAdaptor <package>

You need to sepecify the C<model_name> (the name of the model), and
C<package>, the base package for plain old perl models.

=cut

sub mk_compclass {
    my ( $class, $helper, $package, $const ) = @_;
    my ($type) = ( $class =~ /^Catalyst::Helper::Model::(.+)$/ );
    die "i am nothing.  that doesn't make sense." unless $type;

    my %args = (
        package     => $package,
        constructor => $const,
        type        => $type
    );

    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file, \%args );
}

=head1 AUTHOR

Dann C<< <techmemo@gmail.com> >>

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
    package     => '[% package || 'Fill::This::In' %]',
);

1;

