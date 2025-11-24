package Cron::Toolkit::Pattern;
use strict;
use warnings;
use Cron::Toolkit::Utils qw(:all);

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        children => [],
        field_type =>  $args{field_type}
    }, $class;
    $self->{value} = $args{value} if defined $args{value};

    return $self;
}
sub add_child {
    my ($self, $child) = @_;
    push @{$self->{children}}, $child;
}

sub children {
    my ($self) = @_;
    return $self->{children};
}

sub has_children {
   my $self = shift;
   return scalar @{ $self->{children} } ? 1 : 0;
}

sub type {
    my ($self, $value) = @_;
    $self->{type} = $value if defined $value;
    return $self->{type};  # Return the value (either set or current)
}

sub field_type {
    my ($self, $value) = @_;
    $self->{field_type} = $value if defined $value;
    return $self->{field_type};
}

sub value {
    my ($self, $value) = @_;
    $self->{value} = $value if defined $value;
    return $self->{value};
}

sub lowest {
   my ( $self, $tm ) = @_;

   my ( $min, $max ) = @{ $LIMITS{ $self->field_type } };
   $max = $tm->length_of_month if $self->field_type eq 'dom';

   for my $v ( $min .. $max ) {
      my $test_tm = $tm;
      $test_tm = $test_tm->with_day_of_month($v) if $self->field_type eq 'dom';
      return $v if $self->match($v);
   }
   return;
}

sub highest {
   my ( $self, $tm ) = @_;
   my ( $min, $max ) = @{ $LIMITS{ $self->field_type } };
   $max = $tm->length_of_month if $self->field_type eq 'dom';

   for my $v ( reverse $min .. $max ) {
      my $test_tm = $tm;
      $test_tm = $test_tm->with_day_of_month($v) if $self->field_type eq 'dom';
      return $v if $self->match($v);
   }
   return;
}

sub english_unit {
   my $self = shift;
   my $unit = $self->field_type =~ /^(dow|dom)$/ ? 'day' : $self->field_type;
   $unit .= 's' if ($self->type eq 'single' && $self->value != 1 && $self->field_type ne 'year');
   return $unit;
}

sub english_value {
   my ( $self ) = @_;
   my $value = $self->{value};
   die "missing value" unless defined $value;
   return 'the ' . num_to_ordinal($value)     if $self->field_type eq 'dom';
   return $MONTH_NAMES{$value}                if $self->field_type eq 'month';
   return $DAY_NAMES{$value}                  if $self->field_type eq 'dow';
   return $value;
}

sub _dump_tree {
    my ($self, $indent) = @_;
    $indent //= '';

    my $type = $self->type;

    # Simple leaf values — inline
    if ($type eq 'wildcard')     { return '*'; }
    if ($type eq 'unspecified')  { return '?'; }
    if ($type eq 'single')       { return $self->{value}; }
    if ($type eq 'last')         { return $self->{value} // 'L'; }
    if ($type eq 'lastW')        { return 'LW'; }
    if ($type eq 'nearest_weekday') { return $self->{value}; }
    if ($type eq 'nth')          { return $self->{value}; }

    my @children = @{$self->{children}};
    return '' unless @children;

    my $out = "";

    if ($type eq 'range') {
        return $children[0]->_dump_tree($indent) . '-' . $children[1]->_dump_tree($indent);
    }

    if ($type eq 'step') {
        my $base = $children[0]->_dump_tree($indent . '  ');
        $out .= $base . "\n";
        $out .= "${indent}└─ /$children[1]{value}";
        return $out;
    }

    if ($type eq 'list') {
        $out = "\n";
        for my $i (0 .. $#children) {
            my $prefix = ($i == $#children) ? '└─ ' : '├─ ';
            my $next_indent = $indent . ($i == $#children ? '   ' : '│  ');
            $out .= "${indent}$prefix" . $children[$i]->_dump_tree($next_indent) . "\n";
        }
        chomp $out;
        return $out;
    }

    return $type;
}

1;
