package DBomb::Query::Limit;

=head1 NAME

DBomb::Query::Limit - A LIMIT clause.

=head1 SYNOPSIS

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.3 $';

use Carp::Assert;
use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [qw(offset max_rows)],
    ;

## new Limit ()
## new Limit ($max_rows)
## new Limit ($offset,$max_rows)
## new Limit (+{ offset =>, max_rows=>1})
sub init {
    my $self = shift;
    $self->offset(0);
    $self->max_rows(undef);
    return $self unless @_;

    assert(  (@_ == 1 && (ref($_[0])? ref($_[0]) eq 'HASH' : 1))
          || (@_ == 2 && !ref($_[0]) && ! ref($_[1])), 'parameter validation');

    if (ref($_[0]) eq 'HASH'){
        $self->offset($_[0]->{'offset'});
        $self->max_rows($_[0]->{'max_rows'});
    }
    elsif (@_==1){
        $self->max_rows(shift);
    }
    elsif(@_ == 2){
        $self->offset(shift);
        $self->max_rows(shift);
    }
}

sub sql {
    my ($self, $dbh) = @_;
    my($o,$m) = ($self->offset,$self->max_rows);
    return '' unless defined($o) && defined($m);

    assert(defined($m), 'valid max_rows');
    assert($o >= 0, 'valid offset') if defined $o;

    my $sql = " LIMIT ";
    if(defined $o){
        $sql .= " $o, ";
    }
    $sql .= "$m";
    return $sql;
}

1;
__END__

