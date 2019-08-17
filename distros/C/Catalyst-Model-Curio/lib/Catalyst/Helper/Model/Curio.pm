package Catalyst::Helper::Model::Curio;
our $VERSION = '0.02';

use strictures 2;

sub mk_compclass {
    my ($self, $helper, $class, $key) = @_;

    $helper->{curio_class} = $class || '';
    $helper->{curio_key}   = $key   || '';

    my $file = $helper->{file};
    $helper->render_file( 'curioclass', $file );

    return 1;
}

1;
#__END__

=encoding utf8

=head1 NAME

Catalyst::Helper::Model::Curio - Helper for creating new Curio Catalyst models.

=head1 SYNOPSIS

Usage:

    script/*_create.pl model <model-class> Curio <curio-class> [<curio-key>]

This would create MyApp::Model::Cache:

    script/myapp_create.pl model Cache Curio MyApp::Service::Cache

=head1 DESCRIPTION

This L<Catalyst::Helper> makes it so you can run a CLI command to
create a new L<Catalyst::Model::Curio> model which ties into one of
your L<Curio> classes.

Chapter 2 and 3 of the L<Catalyst::Manual> talk a lot about how to use
helpers.

=head1 OPTIONS

=head2 curio-class

    <curio-class>

This is used as the C<class> configuration option in the model class.

This option is required, if you don't specify it then your model will
throw an exception when loaded by Catalyst.

See L<Catalyst::Model::Curio/class> for more details.

=head2 curio-key

    [<curio-key>]

If your Curio class supports keys you may specify a particular key here
that the model should only interact with.  If you don't specify a key
then your model will support all declared keys, not just one.

This is used as the C<key> configuration option in the model class.

See L<Catalyst::Model::Curio/key> for more details.

=head1 SUPPORT

See L<Catalyst::Model::Curio/SUPPORT>.

=head1 AUTHORS

See L<Catalyst::Model::Curio/AUTHORS>.

=head1 COPYRIGHT AND LICENSE

See L<Catalyst::Model::Curio/COPYRIGHT AND LICENSE>.

=cut

__DATA__

__curioclass__
package [% class %];

use Moo;
use strictures 2;
use namespace::clean;

extends 'Catalyst::Model::Curio';

__PACKAGE__->config(
[%- IF curio_class %]
    class => '[% curio_class %]',
[%- END %]
[%- IF curio_key %]
    key   => '[% curio_key %]',
[%- END %]
);

1;
