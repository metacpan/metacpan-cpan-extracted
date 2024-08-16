use Modern::Perl;

package    # hide from PAUSE
  DBIx::Squirrel::st;


BEGIN {
    require DBIx::Squirrel
      unless defined($DBIx::Squirrel::VERSION);
    $DBIx::Squirrel::st::VERSION = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::st::ISA     = 'DBI::st';
}

use namespace::autoclean;
use DBIx::Squirrel::util qw/throw whine/;

use constant E_INVALID_PLACEHOLDER => 'Cannot bind invalid placeholder (%s)';
use constant W_CHECK_BIND_VALS     => 'Check bind values match placeholder scheme';


sub _private_attributes {
    my $self = shift;
    return
      unless ref($self);
    $self->{'private_ekorn'} = {}
      unless defined($self->{'private_ekorn'});
    unless (@_) {
        return $self->{'private_ekorn'}, $self
          if wantarray;
        return $self->{'private_ekorn'};
    }
    unless (defined($_[0])) {
        delete $self->{'private_ekorn'};
        shift;
    }
    if (@_) {
        if (UNIVERSAL::isa($_[0], 'HASH')) {
            $self->{'private_ekorn'} = {%{$self->{'private_ekorn'}}, %{$_[0]}};
        }
        elsif (UNIVERSAL::isa($_[0], 'ARRAY')) {
            $self->{'private_ekorn'} = {%{$self->{'private_ekorn'}}, @{$_[0]}};
        }
        else {
            $self->{'private_ekorn'} = {%{$self->{'private_ekorn'}}, @_};
        }
    }
    return $self;
}


sub prepare {
    my $self = shift;
    return $self->{'Database'}->prepare($self->{'Statement'}, @_);
}


sub execute {
    my $self = shift;
    $self->finish
      if $DBIx::Squirrel::FINISH_ACTIVE_BEFORE_EXECUTE && $self->{'Active'};
    $self->bind(@_)
      if @_;
    return $self->SUPER::execute;
}


sub bind {
    my($attr, $self) = shift->_private_attributes;
    if (@_) {
        my $placeholders = $attr->{'Placeholders'};
        if ($placeholders && !_placeholders_are_positional($placeholders)) {
            if (my %kv = @{_map_placeholders_to_values($placeholders, @_)}) {
                while (my($k, $v) = each(%kv)) {
                    if ($k =~ m/^[\:\$\?]?(?<bind_id>\d+)$/) {
                        throw E_INVALID_PLACEHOLDER, $k
                          unless $+{'bind_id'};
                        $self->bind_param($+{'bind_id'}, $v);
                    }
                    else {
                        $self->bind_param($k, $v);
                    }
                }
            }
        }
        else {
            if (UNIVERSAL::isa($_[0], 'ARRAY')) {
                for my $bind_id (1 .. scalar(@{$_[0]})) {
                    $self->bind_param($bind_id, $_[0][$bind_id - 1]);
                }
            }
            else {
                for my $bind_id (1 .. scalar(@_)) {
                    $self->bind_param($bind_id, $_[$bind_id - 1]);
                }
            }
        }
    }
    return $self;
}


sub _placeholders_are_positional {
    my $placeholders = shift;
    return
      unless UNIVERSAL::isa($placeholders, 'HASH');
    my @placeholders                    = values(%{$placeholders});
    my $total_count                     = @placeholders;
    my $count                           = grep {m/^[\:\$\?]\d+$/} @placeholders;
    my $all_placeholders_are_positional = $count == $total_count;
    return
      unless $all_placeholders_are_positional;
    return $placeholders;
}


sub _map_placeholders_to_values {
    my $placeholders = shift;
    my $mappings     = do {
        if (_placeholders_are_positional($placeholders)) {
            [map {($placeholders->{$_} => $_[$_ - 1])} keys(%{$placeholders})];
        }
        else {
            my @mappings = do {
                if (UNIVERSAL::isa($_[0], 'ARRAY')) {
                    @{$_[0]};
                }
                elsif (UNIVERSAL::isa($_[0], 'HASH')) {
                    %{$_[0]};
                }
                else {
                    @_;
                }
            };
            whine W_CHECK_BIND_VALS
              unless @mappings % 2 == 0;
            \@mappings;
        }
    };
    return @{$mappings}
      if wantarray;
    return $mappings;
}


sub bind_param {
    my($attr, $self) = shift->_private_attributes;
    my $bindings = do {
        if (my $placeholders = $attr->{'Placeholders'}) {
            if ($_[0] =~ m/^[\:\$\?]?(?<bind_id>\d+)$/) {
                +{$+{'bind_id'} => $_[1]};
            }
            else {
                my $prefixed = $_[0] =~ m/^[\:\$\?]/ ? $_[0] : ":$_[0]";
                +{  map  {($_ => $_[1])}
                    grep {$placeholders->{$_} eq $prefixed}
                      keys(%{$placeholders}),
                };
            }
        }
        else {
            +{$_[0] => $_[1]};
        }
    };
    $self->SUPER::bind_param(%{$bindings});
    return %{$bindings}
      if wantarray;
    return $bindings;
}


BEGIN {
    *iterate  = *it   = sub {DBIx::Squirrel::it->new(@_)};
    *results  = *rs   = sub {DBIx::Squirrel::rs->new(@_)};
    *iterator = *itor = sub {shift->_private_attributes->{'Iterator'}};
}

1;
