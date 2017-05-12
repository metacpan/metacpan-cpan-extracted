package DBomb::Query::Text;

=head1 NAME

DBomb::Query::Text - Just a wrapper around plain sql.

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.6 $';

use Carp::Assert;
use DBomb::Util qw(ctx_0);
use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [qw(text bind_values)],
  ;

sub init
{
    my ($self, $text, @bind_values) = @_;

        assert(UNIVERSAL::isa($self,__PACKAGE__));
        assert(defined($text),'valid parameters');

    $self->text($text);
    $self->bind_values([]);
    push @{$self->bind_values},@bind_values if @bind_values;
}

sub sql
{
    my ($self, $dbh) = @_;
    return ctx_0($self->text, @{$self->bind_values});
}


1;
__END__

=head1 DESCRIPTION

This class is a wrapper around a scalar $text value.  The reason it exists is
so DBomb::Query can call $foo->sql() and not blow up if $foo is plain text.

=head1 METHODS

=over

=item new($text)

Create the wrapper around $text.

=item sql($dbh)

Returns $self->text

=back

=cut

