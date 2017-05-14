package AutoSQL::DBObject;
use strict;
use vars qw(@ISA);
use AutoCode::Root;
@ISA=qw(AutoCode::Root);
use AutoCode::AccessorMaker('$'=>[qw(adaptor)]);

sub _initialize {
    my ($self, @args)=@_;
    $self->SUPER::_initialize(@args);
    my ($dbid, $adaptor)=
        $self->_rearrange([qw(DBID ADAPTOR)], @args);

    defined $dbid and $self->dbID($dbid);
    defined $adaptor and $self->adaptor($adaptor);

}

sub dbID {
    my $self = shift;
    return $self->{_dbID} = shift if @_;
    return $self->{_dbID};
}

1;
