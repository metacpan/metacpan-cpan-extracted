package Catmandu::Fix::Bind::each;

use strict;
use warnings;

use Catmandu::Sane;
use Moo;

use Catmandu::Util;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Bind';

has path      => (fix_opt => 1);
has var       => (fix_opt => 1);

has _root_ => (is => 'rw');
has flag   => (is => 'rw', default => sub {0});

sub unit {
    my ($self, $data) = @_;

    $self->_root_($data);
    $self->flag(0);

    if (defined($self->path)) {
        return Catmandu::Util::data_at($self->path, $data);
    } else {
        return $data;
    }
}

sub bind {
    my ($self, $data, $code, $name, $fixer) = @_;

    if (!Catmandu::Util::is_hash_ref($data)) {
        $data = $code->($data);
    } else {
        if ($self->flag == 1) {
            return $data;
        }

        $self->flag(1);

        while (my ($key, $value) = each %{$data}) {
            my $scope;
            my $mdata;
            if ($self->var) {
                $scope = $self->_root_;
                $scope->{$self->var} = {
                    'key' => $key,
                    'value' => $value
                };
            } else {
                $scope = $data;
                $scope->{'key'} = $key;
                $scope->{'value'} = $value;
            }

            # Fixes are done directly on $data, so no returns are needed.
            $fixer->fix($scope);

            delete $scope->{$self->var} if $self->var;
        }

    }

}

1;
__END__

=pod

=head1 NAME

Catmandu::Fix::Bind::each - a binder that executes fixes for every (key, value) pair in a hash

=head1 SYNOPSIS

    # Create a hash:
    # demo:
    #   nl: 'Tuin der lusten'
    #   en: 'The Garden of Earthly Delights'

    # Create a list of all the titles, without the language tags.
    do each(path: demo, var: t)
        copy_field(t.value, titles.$append)
    end

    # This will result in:
    # demo:
    #   nl: 'Tuin der lusten'
    #   en: 'The Garden of Earthly Delights'
    # titles:
    #   - 'Tuin der lusten'
    #   - 'The Garden of Earthly Delights'

=head1 DESCRIPTION

The each binder will iterate over a hash and return a (key, value)
pair (see the Perl L<each|http://perldoc.perl.org/functions/each.html> function
for the inspiration for this bind) and execute all fixes for each pair.

The bind always returns a C<var.key> and C<var.value> pair which can be used
in the fixes.

=head1 CONFIGURATION

=head2 path

The path to a hash in the data.

=head2 var

The temporary field that will be created in the root of the record
containing a C<key> and C<value> field containing the I<key> and
I<value> of the iterated data (cfr. L<each|http://perldoc.perl.org/functions/each.html>).

=head1 SEE ALSO

L<Catmandu::Fix::Bind::list>
L<Catmandu::Fix::Bind>

=cut
