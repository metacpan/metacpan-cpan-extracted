package Data::Shared::Compiled;
use strict;
use warnings;
use Scalar::Util qw(refaddr);

our $VERSION = '0.01';

sub components { return [ @{ $_[0]{components} } ] }
sub raw        { return $_[0]{is_array} ? [ @{ $_[0]{raw} } ] : $_[0]{raw} }
sub is_array   { return $_[0]{is_array} ? 1 : 0 }

sub CLONE_SKIP { 1 }

sub DESTROY {
    my ($self) = @_;
    my $owners = $self->{_owners} or return;
    my $id = refaddr($self);
    for my $root (values %$owners) {
        delete $root->{_compiled}{$id} if $root;
    }
}

1;

__END__

=head1 NAME

Data::Shared::Compiled - A pre-parsed Data::Shared path

=head1 SYNOPSIS

    use Data::Shared qw(shared_compile sharedc_get);
    my $cp = shared_compile('/cache/42');
    my $v = sharedc_get($root, $cp);
    my @components = @{ $cp->components };

=head1 DESCRIPTION

Returned by C<shared_compile> in L<Data::Shared>. Holds the parsed
path components once so C<sharedc_*> calls skip re-parsing (and,
after the first use against a root, mount resolution and verb
dispatch). Mount changes automatically invalidate cached dispatch.
The root owns bound dispatch; compiled paths hold weak references to it.
Destroying a root or unmounting a backend releases cached native handles.

=head2 components

Copy of the path components as an arrayref. Changing it does not
change the compiled path.

=head2 raw

The original path argument (string or a copy of the original arrayref).

=head2 is_array

True if the path was compiled from an arrayref.

=cut
