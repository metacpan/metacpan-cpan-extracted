use Modern::Perl;

package    # hide from PAUSE
  DBIx::Squirrel::rs;


BEGIN {
    require DBIx::Squirrel
      unless defined($DBIx::Squirrel::VERSION);
    $DBIx::Squirrel::rs::VERSION = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::rs::ISA     = 'DBIx::Squirrel::it';
}

use namespace::autoclean;
use Scalar::Util qw/weaken/;
use Sub::Name;


sub _fetch_row {
    my($attr, $self) = shift->_private_attributes;
    return
      if $self->_no_more_rows;
    return
      if $self->_is_empty and not $self->_fetch;
    my($head, @tail) = @{$attr->{'buffer'}};
    $attr->{'buffer'}     = \@tail;
    $attr->{'row_count'} += 1;
    return $self->_transform($self->_rebless($head))
      if @{$attr->{'callbacks'}};
    return $self->_rebless($head);
}


sub _rebless {
    no strict 'refs';    ## no critic
    my $self = shift;
    return
      unless ref($self);
    my($row_class, $row) = ($self->row_class, @_);
    my $result_class = $self->result_class;
    my $results_fn   = $row_class . '::results';
    my $rs_fn        = $row_class . '::rs';
    unless (defined(&{$rs_fn})) {
        undef &{$rs_fn};
        undef &{$results_fn};
        *{$results_fn} = *{$rs_fn} = do {
            weaken(my $rs = $self);
            subname($rs_fn => sub {$rs});
        };
        @{$row_class . '::ISA'} = $result_class;
    }
    return $row_class->new($row);
}


sub _undef_autoloaded_accessors {
    no strict 'refs';    ## no critic
    my $self = shift;
    undef &{$_} foreach @{$self->row_class . '::AUTOLOAD_ACCESSORS'};
    return $self;
}


sub _slice {
    my($attr, $self) = shift->_private_attributes;
    my $slice = shift;
    my $old   = defined($attr->{'slice'}) ? $attr->{'slice'} : '';
    $self->SUPER::_slice($slice);
    if (my $new = defined($attr->{'slice'}) ? $attr->{'slice'} : '') {
        $self->_undef_autoloaded_accessors
          if ref($new) ne ref($old) && %{$self->row_class . '::'};
    }
    return $self;
}


sub row_class {
    my $self = shift;
    return sprintf('DBIx::Squirrel::rs_0x%x', 0+ $self);
}


sub result_class {
    return 'DBIx::Squirrel::rc';
}


BEGIN {
    *row_base_class = *result_class;
}


sub DESTROY {
    no strict 'refs';    ## no critic
    return
      if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    local($., $@, $!, $^E, $?, $_);
    my $self      = shift;
    my $row_class = $self->row_class;
    $self->_undef_autoloaded_accessors
      if %{$row_class . '::'};
    undef &{$row_class . '::rs'};
    undef &{$row_class . '::results'};
    undef *{$row_class};
    return $self->SUPER::DESTROY;
}

1;
