


package DataCube::Query;


use strict;
use warnings;


sub new {
    my($class,%opts) = @_;
    my $cube  = $opts{cube};
    my $table = $cube->{cube_store}->fetch(join("\t", sort @{$opts{table}}));
    my $self = bless {
        table    => $table,
        callback => $opts{callback},
    }, ref($class) || $class;
    $self->{result_iterator} = DataCube::Query::Iterator->new($self);
    return $self;
}

sub fetchrow_hashref {
    my($self) = @_;
    return $self->{result_iterator}->next_result;
}

package DataCube::Query::Iterator;

sub new {
    my($class,$query) = @_;
    return bless {
        query      => $query,
        eacherator => sub { each %{$query->{table}->{cube}} },
    }, ref($class) || $class;
}

sub next_result {
    my($self) = @_;
    while(my($key,$value) = $self->{eacherator}->()){
        return {key => $key, value => $value}
            if $self->{query}->{callback}->($key,$value);
    }
    return;
}




1;








