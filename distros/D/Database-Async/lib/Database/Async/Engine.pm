package Database::Async::Engine;

use strict;
use warnings;

our $VERSION = '0.013'; # VERSION

use parent qw(IO::Async::Notifier);

=head1 NAME

Database::Async::Engine - base class for database implementation support in L<Database::Async>

=head1 DESCRIPTION

=cut

use URI;
use Scalar::Util;

our %ENGINE_MAP;

UNITCHECK { require Database::Async::Engine::Empty }

=head2 register_class

Class method which will register a package name for a given engine type.

=cut

sub register_class {
    my ($self, $name, $engine_class) = @_;
    die 'already have handler for ' . $name if exists $ENGINE_MAP{$name};
    $ENGINE_MAP{$name} = $engine_class;
    return;
}

sub uri { shift->{uri} }
sub db { shift->{db} }

sub configure {
    my ($self, %args) = @_;
    for (qw(uri)) {
        $self->{$_} = URI->new('' . delete($args{$_})) if exists $args{$_};
    }
    for (qw(db)) {
        Scalar::Util::weaken($self->{$_} = delete $args{$_}) if exists $args{$_};
    }
    $self->next::method(%args);
}

1;

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2011-2020. Licensed under the same terms as Perl itself.

