
package AI::Fuzzy::Set;

## Fuzzy Set ####

sub new { 

    my $class = shift;
    my $self = {} ;

    # accepts a hash of member weights..
    # ( $members{$member}=$weight )

    %{$self->{members}} = @_;

    bless $self, $class;
}

sub membership {
    # naturally, it returns a fuzzy value - the degree
    # to wich $item is a member of the set! :)

    my $self = shift;
    my $item = shift;

    if (defined(${$self->{members}}{$item})) {
	return ${$self->{members}}{$item};
    } else {
	return 0;
    }
}

sub members {
    # returns list of members, sorted from least membership to greatest
    my $self = shift;

    my %l = %{$self->{members}};
    return sort { $l{$a} <=> $l{$b} } keys %l;
}

1;

