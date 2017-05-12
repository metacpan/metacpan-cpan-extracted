package inc::Pod::Weaver::Section::Moo;

use Moose;
with 'Pod::Weaver::Role::Section';

sub weave_section {
    my ($self, $document, $input) = @_;

    my @children;
    for my $section (@{$document->children}) {
        if ($section->content eq 'DESCRIPTION') {
            push @children  => Pod::Elemental::Element::Nested->new({
                command     => 'head1',
                content     => 'WARNING: GONE MOO!',
                children    => [
                    Pod::Elemental::Element::Pod5::Ordinary->new({ content => << 'MOO_SECTION' }),
This module isn't using L<Any::Moose> anymore due to the announced deprecation status of that module.
The switch to the L<Moo> is known to break modules that do C<extend 'AnyEvent::Net::Curl::Queued::Easy'> / C<extend 'YADA::Worker'>!
To keep the compatibility, make sure that you are using L<MooseX::NonMoose>:

    package YourSubclassingModule;
    use Moose;
    use MooseX::NonMoose;
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

Or L<MouseX::NonMoose>:

    package YourSubclassingModule;
    use Mouse;
    use MouseX::NonMoose;
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

Or the L<Any::Moose> equivalent:

    package YourSubclassingModule;
    use Any::Moose;
    use Any::Moose qw(X::NonMoose);
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

However, the recommended approach is to switch your subclassing module to L<Moo> altogether (you can use L<MooX::late> to smoothen the transition):

    package YourSubclassingModule;
    use Moo;
    use MooX::late;
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...
MOO_SECTION
                ],
            });
        }
        push @children => $section;
    }
    $document->children(\@children);

    return;
}

no Moose;
1;

__DATA__
