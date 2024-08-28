use 5.010_001;
use strict;
use warnings;

package    # hide from PAUSE
  DBIx::Squirrel::ResultSet;

use Scalar::Util qw/weaken/;
use Sub::Name;
use namespace::clean;

BEGIN {
    require DBIx::Squirrel unless keys(%DBIx::Squirrel::);
    $DBIx::Squirrel::ResultSet::VERSION = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::ResultSet::ISA     = qw/DBIx::Squirrel::Iterator/;
}

sub DESTROY {
    no strict 'refs';    ## no critic
    return if DBIx::Squirrel::Utils::global_destruct_phase();
    local($., $@, $!, $^E, $?, $_);
    my $self      = shift;
    my $row_class = $self->row_class;
    $self->_autoloaded_accessors_unload if %{$row_class . '::'};
    undef &{$row_class . '::rs'};
    undef &{$row_class . '::rset'};
    undef &{$row_class . '::results'};
    undef &{$row_class . '::resultset'};
    undef *{$row_class};
    return $self->SUPER::DESTROY;
}

sub _autoloaded_accessors_unload {
    no strict 'refs';    ## no critic
    my $self = shift;
    undef &{$_} foreach @{$self->row_class . '::AUTOLOAD_ACCESSORS'};
    return $self;
}

sub _result_preprocess {
    my $self = shift;
    return ref($_[0]) ? $self->_rebless(shift) : shift;
}

sub _rebless {
    no strict 'refs';    ## no critic
    my $self       = shift;
    my $row_class  = $self->row_class;
    my $results_fn = $row_class . '::results';
    unless (defined(&{$results_fn})) {
        my $resultset_fn = $row_class . '::resultset';
        my $rset_fn      = $row_class . '::rset';
        my $rs_fn        = $row_class . '::rs';
        undef &{$resultset_fn};
        undef &{$rset_fn};
        undef &{$rs_fn};
        *{$resultset_fn} = *{$results_fn} = *{$rset_fn} = *{$rs_fn} = do {
            weaken(my $results = $self);
            subname($results_fn => sub {$results});
        };
        @{$row_class . '::ISA'} = ($self->result_class);
    }
    return $row_class->new(shift);
}

sub result_class {
    return 'DBIx::Squirrel::ResultClass';
}

BEGIN {
    *row_base_class = *result_class;
}

sub row_class {
    my $self = shift;
    return sprintf('%s::Ox%x', ref($self), 0+ $self);
}

sub slice {
    no strict 'refs';    ## no critic
    my($attr, $self) = shift->_private_state;
    my $slice = shift;
    my $old   = defined($attr->{slice}) ? $attr->{slice} : '';
    $self->SUPER::slice($slice);
    if (my $new = defined($attr->{slice}) ? $attr->{slice} : '') {
        if (ref($new) ne ref($old)) {
            $self->_autoloaded_accessors_unload if %{$self->row_class . '::'};
        }
    }
    return $self;
}

1;
