#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::CheckList 2.155;

use Mouse;
use 5.010;

use Config::Model::Exception;
use Config::Model::IdElementReference;
use Config::Model::Warper;
use List::MoreUtils qw/any none/;
use Carp;
use Log::Log4perl qw(get_logger :levels);
use Storable qw/dclone/;

extends qw/Config::Model::AnyThing/;

with "Config::Model::Role::WarpMaster";
with "Config::Model::Role::Grab";
with "Config::Model::Role::HelpAsText";
with "Config::Model::Role::ComputeFunction";

my $logger = get_logger("Tree.Element.CheckList");
my $user_logger   = get_logger("User");

my @introspect_params = qw/refer_to computed_refer_to/;

my @accessible_params = qw/default_list upstream_default_list choice ordered/;
my @allowed_warp_params = ( @accessible_params, qw/level/ );

has [qw/backup data preset layered/] => ( is => 'rw', isa => 'HashRef', default => sub { {}; } );
has computed_refer_to => ( is => 'rw', isa => 'Maybe[HashRef]' );
has [qw/refer_to/]            => ( is => 'rw', isa => 'Str' );
has [qw/ordered_data choice/] => ( is => 'rw', isa => 'ArrayRef', default => sub { []; } );
has [qw/ordered/]             => ( is => 'ro', isa => 'Bool' );

has [qw/warp help/] => ( is => 'rw', isa => 'Maybe[HashRef]' );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = @_;
    my %h     = map { ( $_ => $args{$_} ); } grep { defined $args{$_} } @allowed_warp_params;
    return $class->$orig( backup => dclone( \%h ), @_ );
};

sub BUILD {
    my $self = shift;

    if ( defined $self->refer_to or defined $self->computed_refer_to ) {
        $self->submit_to_refer_to();
    }

    $self->set_properties();    # set will use backup data

    if ( defined $self->warp ) {
        my $warp_info = $self->warp;
        $self->{warper} = Config::Model::Warper->new(
            warped_object => $self,
            %$warp_info,
            allowed => \@allowed_warp_params
        );
    }

    $self->cl_init;

    $logger->info( "Created check_list element " . $self->element_name );
    return $self;
}

sub cl_init {
    my $self = shift;

    $self->warp if ( $self->{warp} );

    if ( defined $self->{ref_object} ) {
        my $level = $self->parent->get_element_property(
            element  => $self->{element_name},
            property => 'level',
        );
        $self->{ref_object}->get_choice_from_referred_to if $level ne 'hidden';
    }
}

sub name {
    my $self = shift;
    my $name = $self->{parent}->name . ' ' . $self->{element_name};
    return $name;
}

sub value_type { return 'check_list'; }

# warning : call to 'set' are not cumulative. Default value are always
# restored. Lest keeping track of what was modified with 'set' is
# too hard for the user.
sub set_properties {
    my $self = shift;

    # cleanup all parameters that are handled by warp
    for (@allowed_warp_params) {
        delete $self->{$_},
    }

    if ( $logger->is_trace() ) {
        my %h = @_;
        my $keys = join( ',', keys %h );
        $logger->trace("set_properties called on $self->{element_name} with $keys");
    }

    # merge data passed to the constructor with data passed to set
    my %args = ( %{ $self->{backup} }, @_ );

    # these are handled by Node or Warper
    for (qw/level/) {
        delete $args{$_}
    }

    $self->{ordered} = delete $args{ordered} || 0;

    if ( defined $args{choice} ) {
        my @choice = @{ delete $args{choice} };
        $self->{default_choice} = \@choice;
        $self->setup_choice(@choice);
    }

    if ( defined $args{default} ) {
        $logger->warn($self->name, ": default param is deprecated, use default_list");
        $args{default_list} = delete $args{default};
    }

    if ( defined $args{default_list} ) {
        $self->{default_list} = delete $args{default_list};
    }

    # store default data in a hash (more convenient)
    $self->{default_data} = { map { $_ => 1 } @{ $self->{default_list} } };

    if ( defined $args{upstream_default_list} ) {
        $self->{upstream_default_list} = delete $args{upstream_default_list};
    }

    # store upstream default data in a hash (more convenient)
    $self->{upstream_default_data} =
        { map { $_ => 1 } @{ $self->{upstream_default_list} } };

    Config::Model::Exception::Model->throw(
        object => $self,
        error  => "Unexpected parameters :" . join( ' ', keys %args ) ) if scalar keys %args;

    if ( $self->has_warped_slaves ) {
        my $hash = $self->get_checked_list_as_hash; # force scalar context
        $self->trigger_warp($hash, $self->fetch);
    }
}

sub setup_choice {
    my $self = shift;
    my @choice = ref $_[0] ? @{ $_[0] } : @_;

    $logger->trace("CheckList $self->{element_name}: setup_choice with @choice");

    # store all enum values in a hash. This way, checking
    # whether a value is present in the enum set is easier
    delete $self->{choice_hash} if defined $self->{choice_hash};
    for (@choice) {
        $self->{choice_hash}{$_} = 1;
    }

    $self->{choice} = \@choice;

    # cleanup current preset and data if it does not fit current choices
    foreach my $field (qw/preset data layered/) {
        next unless defined $self->{$field};    # do not create if not present
        foreach my $item ( keys %{ $self->{$field} } ) {
            delete $self->{$field}{$item} unless defined $self->{choice_hash}{$item};
        }
    }
}

# Need to extract Config::Model::Reference (used by Value, and maybe AnyId).

sub submit_to_refer_to {
    my $self = shift;

    if ( defined $self->refer_to ) {
        $self->{ref_object} = Config::Model::IdElementReference->new(
            refer_to   => $self->refer_to,
            config_elt => $self,
        );
    }
    elsif ( defined $self->computed_refer_to ) {
        $self->{ref_object} = Config::Model::IdElementReference->new(
            computed_refer_to => $self->computed_refer_to,
            config_elt        => $self,
        );
        my $var = $self->{computed_refer_to}{variables};

        # refer_to registration is done for all element that are used as
        # variable for complex reference (ie '- $foo' , {foo => '- bar'} )
        foreach my $path ( values %$var ) {

            # is ref during test case
            #print "path is '$path'\n";
            next if $path =~ /\$/;    # next if path also contain a variable
            my $master = $self->grab($path);
            next unless $master->can('register_dependency');
            $master->register_dependency($self);
        }
    }
    else {
        croak "checklist submit_to_refer_to: undefined refer_to or computed_refer_to";
    }
}

sub setup_reference_choice {
    my $self = shift;
    $self->setup_choice(@_);
}

sub get_type {
    my $self = shift;
    return 'check_list';
}

sub get_cargo_type { goto &cargo_type }

sub cargo_type {
    my $self = shift;
    return 'leaf';
}

sub apply_fixes {

    # no operation. THere's no check_value method because a check list
    # supposed to be always correct. Hence apply_fixes is empty.
}

sub notify_change {
    my $self       = shift;
    my %args       = @_;

    return if $self->instance->initial_load and not $args{really};

    $self->SUPER::notify_change( %args, value_type => $self->value_type );

    # shake all warped or computed objects that depends on me
    foreach my $s ( $self->get_warped_slaves ) {
        $logger->debug( "calling notify_change on slave ", $s->name )
            if $logger->is_debug;
        $s->needs_check(1);
    }
}


# does not check the validity, but check the item of the check_list
sub check {
    my $self  = shift;
    my @list  = ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_;
    my %args  = ref $_[0] eq 'ARRAY' ? @_[ 1, $#_ ] : ( check => 'yes' );
    my $check = $self->_check_check( $args{check} );

    if ( defined $self->{ref_object} ) {
        $self->{ref_object}->get_choice_from_referred_to;
    }

    my @changed;
    for (@list) {
        push @changed, $_ if $self->_store( $_, 1, $check )
    }

    $self->notify_change( note => "check @changed" )
        unless $self->instance->initial_load;
}

sub clear_item {
    my $self   = shift;
    my $choice = shift;

    my $inst = $self->instance;
    my $data_name =
          $inst->preset  ? 'preset'
        : $inst->layered ? 'layered'
        :                  'data';
    my $old_v   = $self->{$data_name}{$choice};
    my $changed = 0;
    if ($old_v) {
        $changed = 1;
    }
    delete $self->{$data_name}{$choice};

    if ( $self->{ordered} and $changed ) {
        my $ord = $self->{ordered_data};
        my @new = grep { $_ ne $choice } @$ord;
        $self->{ordered_data} = \@new;
    }
    return $changed;
}

# internal
sub _store {
    my ( $self, $choice, $value, $check ) = @_;

    my $inst = $self->instance;

    if ( $value != 0 and $value != 1 ) {
        Config::Model::Exception::WrongValue->throw(
            error  => "store: check item value must be boolean, " . "not '$value'.",
            object => $self
        );
        return;
    }

    my $ok = $self->{choice_hash}{$choice} || 0;
    my $changed = 0;

    if ($ok) {
        my $data_name =
              $inst->preset  ? 'preset'
            : $inst->layered ? 'layered'
            :                  'data';
        my $old_v = $self->{$data_name}{$choice} ;
        if ( not defined $old_v or $old_v ne $value ) {
            # no change notif when going from undef to 0 as the
            # logical value does not change
            {
                no warnings qw/uninitialized/;
                $changed = (!$old_v xor !$value);
            }
            $self->{$data_name}{$choice} = $value;
        }

        if ( $self->{ordered} and $value ) {
            my $ord = $self->{ordered_data};
            push @$ord, $choice unless scalar grep { $choice eq $_ } @$ord;
        }
    }
    else {
        my $err_str =
            "Unknown check_list item '$choice'. Expected '"
            . join( "', '", @{ $self->{choice} } ) . "'";
        $err_str .= "\n\t" . $self->{ref_object}->reference_info
            if defined $self->{ref_object};
        if ($check eq 'yes') {
            Config::Model::Exception::WrongValue->throw( error => $err_str, object => $self );
        }
        elsif ($check eq 'skip') {
            $user_logger->warn($err_str);
        }
    }

    if (    $ok
        and $changed
        and $self->has_warped_slaves
        and not( $self->instance->layered or $self->instance->preset ) ) {
        my $h = $self->get_checked_list_as_hash;
        my $str = $self->fetch;
        $self->trigger_warp($h , $str);
    }

    return $changed;
}

sub get_arguments {
    my $self = shift;
    my $arg  = shift;
    my @list  = ref $arg eq 'ARRAY' ? @$arg : ($arg, @_);
    my %args  =  ref $arg eq 'ARRAY' ? ( check => 'yes', @_ ) : (check => 'yes');
    my $check = $self->_check_check( $args{check} );
    return \@list, $check, \%args;
}

sub uncheck {
    my $self  = shift;
    my ($list, $check) = $self->get_arguments(@_);

    if ( defined $self->{ref_object} ) {
        $self->{ref_object}->get_choice_from_referred_to;
    }

    my @changed;
    for ( @$list ) {
        push @changed, $_ if $self->_store( $_, 0, $check )
    }

    $self->notify_change( note => "uncheck @changed" )
        unless $self->instance->initial_load;
}

sub has_data {
    my $self = shift;
    my @set = $self->get_checked_list(qw/mode custom/) ;
    return scalar @set;
}

{
    my %accept_mode = map { ( $_ => 1 ) }
        qw/custom standard preset default layered upstream_default non_upstream_default user backend/;

    sub is_bad_mode {
        my ($self, $mode) = @_;
        if ( $mode and not defined $accept_mode{$mode} ) {
            my $good_ones = join( ' or ', sort keys %accept_mode );
            return "expected $good_ones as mode parameter, not $mode";
        }
    }
}

sub is_checked {
    my $self   = shift;
    my $choice = shift;
    my %args   = @_;
    my $mode   = $args{mode} || '';
    my $check  = $self->_check_check( $args{check} );

    my $ok = $self->{choice_hash}{$choice} || 0;

    if ($ok) {

        if ( my $err = $self->is_bad_mode($mode) ) {
            croak "is_checked: $err";
        }

        my $dat    = $self->{data}{$choice};
        my $pre    = $self->{preset}{$choice};
        my $def    = $self->{default_data}{$choice};
        my $ud     = $self->{upstream_default_data}{$choice};
        my $lay    = $self->{layered}{$choice};
        my $std_v  = $pre // $def // 0;
        my $non_up_def = $dat // $pre // $lay // $def // 0;
        my $user_v = $dat // $pre // $lay // $def // $ud // 0;

        my $result =
              $mode eq 'custom' ? ( $dat && !$std_v ? 1 : 0 )
            : $mode eq 'preset' ? $pre
            : $mode eq 'layered'          ? $lay
            : $mode eq 'upstream_default' ? $ud
            : $mode eq 'default'          ? $def
            : $mode eq 'standard'         ? $std_v
            : $mode eq 'non_upstream_default' ? $ud
            : $mode eq 'user'             ? $user_v
            : $mode eq 'backend'          ? $dat // $std_v
            :                               $dat // $std_v;

        return $result;
    }
    elsif ( $check eq 'yes' ) {
        my $err_str =
            "Unknown check_list item '$choice'. Expected '"
            . join( "', '", @{ $self->{choice} } ) . "'";
        $err_str .= "\n\t" . $self->{ref_object}->reference_info
            if defined $self->{ref_object};
        Config::Model::Exception::WrongValue->throw(
            error  => $err_str,
            object => $self
        );
    }
}

# get_choice is always called when using check_list, so having a
# warp safety check here makes sense

sub get_choice {
    my $self = shift;

    if ( defined $self->{ref_object} ) {
        $self->{ref_object}->get_choice_from_referred_to;
    }

    if ( not defined $self->{choice} ) {
        my $msg = "check_list element has no defined choice. " . $self->warp_error;
        Config::Model::Exception::UnavailableElement->throw(
            info    => $msg,
            object  => $self->parent,
            element => $self->element_name,
        );
    }

    return @{ $self->{choice} };
}

sub get_default_choice {
    my $self = shift;
    return @{ $self->{default_choice} || [] };
}

sub get_builtin_choice {
    carp "get_builtin_choice is deprecated, use get_upstream_default_choice";
    goto &get_upstream_default_choice;
}

sub get_upstream_default_choice {
    my $self = shift;
    return @{ $self->{upstream_default_data} || [] };
}

sub get_help {
    my $self = shift;
    my $help = $self->{help};

    return $help unless @_;

    my $on_value = shift;
    return $help->{$on_value} if defined $help and defined $on_value;

    return;
}

sub get_info {
    my $self = shift;

    my @items = ('type: check_list');
    if ( defined $self->refer_to ) {
        push @items, "refer_to: " . $self->refer_to;
    }
    push @items, "ordered: " . ( $self->ordered ? 'yes' : 'no' );
    return @items;
}

sub clear {
    my $self = shift;
    # also triggers notify changes
    for ($self->get_choice) {
        $self->clear_item($_)
    }
}

sub clear_values { goto &clear; }

sub clear_layered {
    my $self = shift;
    $self->{layered} = {};
}

my %old_mode = ( built_in_list => 'upstream_default_list', );

sub get_checked_list_as_hash {
    my $self = shift;
    my %args = @_ > 1 ? @_ : ( mode => $_[0] );
    my $mode = $args{mode} || '';

    foreach my $k ( keys %old_mode ) {
        next unless $mode eq $k;
        $mode = $old_mode{$k};
        carp $self->location, " warning: deprecated mode parameter: $k, ", "expected $mode\n";
    }

    if ( my $err = $self->is_bad_mode($mode)) {
        croak "get_checked_list_as_hash: $err";
    }

    my $dat = $self->{data};
    my $pre = $self->{preset};
    my $def = $self->{default_data};
    my $lay = $self->{layered};
    my $ud  = $self->{upstream_default_data};

    # fill empty hash result
    my %h = map { $_ => 0 } $self->get_choice;

    my %predef = ( %$def, %$pre );
    my %std = ( %$ud, %$lay, %$def, %$pre );

    # use _std_backup if all data values are null (no checked items by user)
    my %old_dat = ( none { $_; } values %$dat ) ? %{ $self->{_std_backup} || {} } : %$dat;

    if ( not $mode and any { $_; } values %predef and none { $_; } values %old_dat ) {

        # changed from nothing to default checked list that must be written
        $self->{_std_backup} = { %$def, %$pre };
        $self->notify_change( note => "use default checklist" );
    }

    # custom test must compare the whole list at once, not just one item at a time.
    my %result =
        $mode eq 'custom' ? ( ( grep { $dat->{$_} xor $std{$_} } keys %h ) ? ( %$pre, %$dat ) : () )
        : $mode eq 'preset'           ? (%$pre)
        : $mode eq 'layered'          ? (%$lay)
        : $mode eq 'upstream_default' ? (%$ud)
        : $mode eq 'default'          ? (%$def)
        : $mode eq 'standard'         ? %std
        : $mode eq 'user'             ? ( %h, %std, %$dat )
        :                               ( %predef, %$dat );

    return wantarray ? %result : \%result;
}

sub get_checked_list {
    my $self = shift;

    my %h          = $self->get_checked_list_as_hash(@_);
    my @good_order = $self->{ordered} ? @{ $self->{ordered_data} } : sort keys %h;
    my @res        = grep { $h{$_} } @good_order;
    return wantarray ? @res : \@res;
}

sub fetch {
    my $self = shift;
    return join( ',', $self->get_checked_list(@_) );
}

sub fetch_custom {
    my $self = shift;
    return join( ',', $self->get_checked_list('custom') );
}

sub fetch_preset {
    my $self = shift;
    return join( ',', $self->get_checked_list('preset') );
}

sub fetch_layered {
    my $self = shift;
    return join( ',', $self->get_checked_list('layered') );
}

sub get {
    my $self = shift;
    my $path = shift;
    if ($path) {
        Config::Model::Exception::User->throw(
            object  => $self,
            message => "get() called with a value with non-empty path: '$path'"
        );
    }
    return $self->fetch(@_);
}

sub set {
    my ($self, $path, $list, %args) = @_;

    my $check_validity = $self->_check_check( $args{check} );
    if ($path) {
        Config::Model::Exception::User->throw(
            object  => $self,
            message => "set() called with a value with non-empty path: '$path'"
        );
    }

    my @list = split /,/, $list;
    return $self->set_checked_list( \@list, check => $check_validity );
}

sub load {
    goto &store;
}

sub store     {
    my $self = shift;
    my %args =
          @_ == 1 ? ( value => $_[0] )
        : @_ == 3 ? ( 'value', @_ )
        :           @_;
    my $check_validity = $self->_check_check( $args{check} );

    my @set = split /\s*,\s*/, $args{value};
    foreach (@set) { s/^"|"$//g; s/\\"/"/g; }
    $self->set_checked_list(\@set, check => $check_validity);
}

sub store_set { goto &set_checked_list }

sub set_checked_list {
    my $self = shift;
    my ($list, $check) = $self->get_arguments(@_);

    $logger->trace("called with @$list");
    my %set = map { $_ => 1 } @$list;
    my @changed;

    foreach my $c ( $self->get_choice ) {
        my $v = delete $set{$c} // 0;
        push @changed, "$c:$v" if $self->_store( $c, $v, $check );
    }

    # Items left in %set are unknown. _store will handle the error
    foreach my $item (keys %set) {
        $self->_store( $item, 1, $check );
    }

    $self->{ordered_data} = $list;

    $self->notify_change( note => "set_checked_list @changed" )
        if @changed and not $self->instance->initial_load;
}

sub set_checked_list_as_hash {
    my $self = shift;
    my %check_list = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;
    my %args  = ref $_[0] eq 'HASH' ? @_[ 1, $#_ ] : ( check => 'yes' );
    my $check_validity = $self->_check_check( $args{check} );

    foreach my $c ( $self->get_choice ) {
        if ( defined $check_list{$c} ) {
            $self->_store( $c, $check_list{$c}, $check_validity );
        }
        else {
            $self->clear_item($c);
        }
    }
}

sub load_data {
    my $self = shift;

    my %args  = @_ > 1 ? @_ : ( data => shift );
    my $data  = $args{data};
    my $check_validity = $self->_check_check( $args{check} );

    if ( ref($data) eq 'ARRAY' ) {
        $self->set_checked_list($data, check => $check_validity);
    }
    elsif ( ref($data) eq 'HASH' ) {
        $self->set_checked_list_as_hash($data, check => $check_validity);
    }
    elsif ( not ref($data) ) {
        $self->set_checked_list([$data], check => $check_validity );
    }
    else {
        Config::Model::Exception::LoadData->throw(
            object     => $self,
            message    => "check_list load_data called with unexpected type. ".
                          "Expected plain scalar, array or hash ref",
            wrong_data => $data,
        );
    }
}

sub swap {
    my ( $self, $a, $b ) = @_;

    foreach my $param ( $a, $b ) {
        unless ( $self->is_checked($param) ) {
            my $err_str = "swap: choice $param must be set";
            Config::Model::Exception::WrongValue->throw(
                error  => $err_str,
                object => $self
            );
        }
    }

    # perform swap in ordered list
    foreach ( @{ $self->{ordered_data} } ) {
        if ( $_ eq $a ) {
            $_ = $b;
        }
        elsif ( $_ eq $b ) {
            $_ = $a;
        }
    }
}

sub move_up {
    my ( $self, $c ) = @_;

    unless ( $self->is_checked($c) ) {
        my $err_str = "swap: choice $c must be set";
        Config::Model::Exception::WrongValue->throw(
            error  => $err_str,
            object => $self
        );
    }

    # perform move in ordered list
    my $list = $self->{ordered_data};
    for ( my $i = 1 ; $i < @$list ; $i++ ) {
        if ( $list->[$i] eq $c ) {
            $list->[$i] = $list->[ $i - 1 ];
            $list->[ $i - 1 ] = $c;
            last;
        }
    }
}

sub move_down {
    my ( $self, $c ) = @_;

    unless ( $self->is_checked($c) ) {
        my $err_str = "swap: choice $c must be set";
        Config::Model::Exception::WrongValue->throw(
            error  => $err_str,
            object => $self
        );
    }

    # perform move in ordered list
    my $list = $self->{ordered_data};
    for ( my $i = 0 ; $i + 1 < @$list ; $i++ ) {
        if ( $list->[$i] eq $c ) {
            $list->[$i] = $list->[ $i + 1 ];
            $list->[ $i + 1 ] = $c;
            last;
        }
    }
}

# dummy to match Value call
sub warning_msg { '' }

1;

# ABSTRACT: Handle check list element

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::CheckList - Handle check list element

=head1 VERSION

version 2.155

=head1 SYNOPSIS

 use Config::Model;

 # define configuration tree object
 my $model = Config::Model->new;
 $model->create_config_class(
    name => "MyClass",

    element => [

        # type check_list uses Config::Model::CheckList
        my_check_list => {
            type   => 'check_list',
            choice => [ 'A', 'B', 'C', 'D' ],
            help   => {
                A => 'A effect is this',
                D => 'D does that',
            }
        },
    ],
 );

 my $inst = $model->instance( root_class_name => 'MyClass' );

 my $root = $inst->config_root;

 # put data
 $root->load( steps => 'my_check_list=A' );

 my $obj = $root->grab('my_check_list');

 my $v = $root->grab_value('my_check_list');
 print "check_list value '$v' with help '", $obj->get_help($v), "'\n";

 # more data
 $obj->check('D');
 $v = $root->grab_value('my_check_list');
 print "check_list new value is '$v'\n";   # prints check_list new value is 'A,D'

=head1 DESCRIPTION

This class provides a check list element for a L<Config::Model::Node>.
In other words, this class provides a list of booleans items. Each item
can be set to 1 or 0.

The available items in the check list can be :

=over

=item * 

A fixed list (with the C<choice> parameter)

=item *

A dynamic list where the available choice are the keys of another hash
of the configuration tree. See L</"Choice reference"> for details.

=back

=head1 CONSTRUCTOR

CheckList object should not be created directly.

=head1 CheckList model declaration

A check list element must be declared with the following parameters:

=over

=item type

Always C<checklist>.

=item choice

A list ref containing the check list items (optional)

=item refer_to

This parameter is used when the keys of a hash are used to specify the
possible choices of the check list. C<refer_to> point to a hash or list
element in the configuration tree. See L<Choice reference> for
details. (optional)

=item computed_refer_to

Like C<refer_to>, but use a computed value to find the hash or list
element in the configuration tree. See L<Choice reference> for
details. (optional)

=item default_list

List ref to specify the check list items which are "on" by default.
(optional)

=item ordered

Specify whether the order of checked items must be preserved. 

=item help

Hash ref to provide information on the check list items.

=item warp

Used to provide dynamic modifications of the check list properties
See L<Config::Model::Warper> for details

=back

For example:

=over

=item *

A check list with help:

 choice_list => {
     type   => 'check_list',
     choice => ['A' .. 'Z'],
     help   => { A => 'A help', E => 'E help' } ,
 },

=item *

A check list with default values:

 choice_list_with_default => {
     type => 'check_list',
     choice     => ['A' .. 'Z'],
     default_list   => [ 'A', 'D' ],
 },

=item *

A check list whose available choice and default change depending on
the value of the C<macro> parameter:

 warped_choice_list => {
     type => 'check_list',
     warp => {
         follow => '- macro',
         rules  => {
             AD => {
                 choice => [ 'A' .. 'D' ],
                 default_list => ['A', 'B' ]
             },
             AH => { choice => [ 'A' .. 'H' ] },
         }
     }
 },

=back

=head1 Introspection methods

The following methods returns the checklist parameter :

=over

=item refer_to

=item computed_refer_to

=back

=head1 Choice reference

The choice items of a check_list can be given by another configuration
element. This other element can be:

=over

=item *

The keys of a hash

=item *

Another checklist. In this case only the checked items of the other
checklist are available.

=back

This other hash or other checklist is indicated by the C<refer_to> or
C<computed_refer_to> parameter. C<refer_to> uses the syntax of the
C<steps> parameter of L<grab(...)|Config::Role::Grab/grab">

See L<refer_to parameter|Config::Model::IdElementReference/"refer_to parameter">.

=head2 Reference examples

=over

=item *

A check list where the available choices are the keys of C<my_hash>
configuration parameter:

 refer_to_list => {
     type => 'check_list',
     refer_to => '- my_hash'
 },

=item *

A check list where the available choices are the checked items of
C<other_check_list> configuration parameter:

 other_check_list => {
     type => 'check_list',
     choice => [qw/A B C/]
 },
 refer_to_list => {
     type => 'check_list',
     refer_to => '- other_check_list'
 },

=item *

A check list where the available choices are the keys of C<my_hash>
and C<my_hash2> and C<my_hash3> configuration parameter:

 refer_to_3_lists => {
     type => 'check_list',
     refer_to => '- my_hash + - my_hash2   + - my_hash3'
 },

=item *

A check list where the available choices are the specified choice and
the choice of C<refer_to_3_lists> and a hash whose name is specified
by the value of the C<indirection> configuration parameter (this
example is admittedly convoluted):

 refer_to_check_list_and_choice => {
     type => 'check_list',
     computed_refer_to => {
         formula => '- refer_to_2_list + - $var',
         variables => {
             var => '- indirection '
         }
     },
     choice  => [qw/A1 A2 A3/],
 },

=back

=head1 Methods

=head2 get_type

Returns C<check_list>.

=head2 cargo_type

Returns 'leaf'.

=head2 check

Set choice. Parameter is either a list of choices to set or 
a list ref and some optional parameter. I.e:

  check (\@list, check => 'skip') ;

C<check> parameter decide on behavior in case of invalid
choice value: either die (if yes) or discard bad value (if skip)

=head2 uncheck

Unset choice. Parameter is either a list of choices to unset or 
a list ref and some optional parameter. I.e:

  uncheck (\@list, check => 'skip') ;

C<check> parameter decide on behavior in case of invalid
choice value: either die (if yes) or discard bad value (if skip)

=head2 is_checked

Parameters: C<< ( choice, [ check => yes|skip ] , [ mode => ... ]) >>

Return 1 if the given C<choice> was set. Returns 0 otherwise.

C<check> parameter decide on behavior in case of invalid
choice value: either die (if yes) or discard bad value (if skip)

C<mode> is either: custom standard preset default layered upstream_default

=head2 has_data

Return true if the check_list contains a set of checks different from default
or upstream default set of check.

=head2 get_choice

Returns an array of all items names that can be checked (i.e.
that can have value 0 or 1).

=head2 get_help

Parameters: C<(choice_value)>

Return the help string on this choice value

=head2 get_info

Returns a list of information related to the check list. See
L<Config::Model::Value/get_info> for more details.

=head2 clear

Reset the check list (can also be called as C<clear_values>)

=head2 clear_item

Parameters: C<(choice_value)>

Reset an element of the checklist.

=head2 get_checked_list_as_hash

Accept a parameter (referred below as C<mode> parameter) similar to
C<mode> in L<Config::Model::Value/fetch>.

Returns a hash (or a hash ref) of all items. The boolean value is the
value of the hash.

Example:

 { A => 0, B => 1, C => 0 , D => 1}

By default, this method returns all items set by the user, or
items set in preset mode or checked by default.

With a C<mode> parameter set to a value from the list below, this method
returns:

=over

=item backend

The value written in config file, (ie. set by user or by layered data
or preset or default)

=item custom

The list entered by the user. An empty list is returned if the list of
checked items is identical to the list of items checked by default. The
whole list of checked items is returned as soon as B<one> item is different
from standard value.

=item preset

The list entered in preset mode

=item standard

The list set in preset mode or checked by default.

=item default

The default list (defined by the configuration model)

=item layered

The list specified in layered mode. 

=item upstream_default

The list implemented by upstream project (defined in the configuration
model)

=item user

The set that is active in the application. (ie. set by user or
by layered data or preset or default or upstream_default)

=item non_upstream_default

The choice set by user or by layered data or preset or default.

=back

=head2 get_checked_list

Parameters: C<< ( < mode > ) >>

Returns a list (or a list ref) of all checked items (i.e. all items
set to 1).

=head2 fetch

Parameters: C<< ( < mode > ) >>

Returns a string listing the checked items (i.e. "A,B,C")

=head2 get

Parameters: C<< ( path  [, < mode> ] ) >>

Get a value from a directory like path.

=head1 Method to check or clear items in the check list

All these methods accept an optional C<check> parameter that can be:

=over

=item yes

A wrong item to check trigger an exception (default)

=item skip

A wrong item trigger a warning

=item no

A wrong item is ignored

=back

=head2 set

Parameters: C<< ( path, items_to_set, [ check => [ yes | no | skip  ] ] ) >>

Set a checklist with a directory like path. Since a checklist is a leaf, the path
should be empty.

The values are a comma separated list of items to set in the check list.

Example :

  $leaf->set('','A,C,Z');
  $leaf->set('','A,C,Z', check => 'skip');

=head2 set_checked_list

Set all passed items to checked (1). All other available items
in the check list are set to 0.

Example, for a check list that contains A B C and D check items:

  # set cl to A=0 B=1 C=0 D=1
  $cl->set_checked_list('B','D')
  $cl->set_checked_list( [ 'B','D' ])
  $cl->set_checked_list( [ 'B','D' ], check => 'yes')

=head2 store_set

Alias to L</set_checked_list>, so a list and a check_list can use the same store method

=head2 store

Set all items listed in a string to checked. The items must be
separated by commas. All other available items in the check list are
set to 0.

Example:

  $cl->store('B, D')
  $cl->store( value => 'B,C' )
  $cl->store( value => 'B,C', check => 'yes' )

=head2 load

Alias to L</store>.

=head2 set_checked_list_as_hash

Set check_list items. Missing items in the given hash of parameters
are cleared (i.e. set to undef).

Example for a check list containing A B C D

  $cl->set_checked_list_as_hash( { A => 1, B => 0} , check => 'yes' )
  # result A => 1 B => 0 , C and D are undef

=head2 load_data

Load items as an array or hash ref. Array is forwarded to
L<set_checked_list> , and hash is forwarded to L<set_checked_list_as_hash>.

Example:

 $cl->load_data(['A','B']) # cannot use check param here
 $cl->load_data( data => ['A','B'])
 $cl->load_data( data => ['A','B'], check => 'yes')
 $cl->load_data( { A => 1, B => 1 } )
 $cl->load_data( data => { A => 1, B => 1 }, check => 'yes')

=head2 is_bad_mode

Accept a mode parameter. This function checks if the mode is accepted
by L</fetch> method. Returns an error message if not. For instance:

 if (my $err = $val->is_bad_mode('foo')) {
    croak "my_function: $err";
 }

This method is intented as a helper ti avoid duplicating the list of
accepted modes for functions that want to wrap fetch methods (like
L<Config::Model::Dumper> or L<Config::Model::DumpAsData>)

=head1 Ordered checklist methods

All the methods below are valid only for ordered checklists.

=head2 swap

Parameters: C<< ( choice_a, choice_b) >>

Swap the 2 given choice in the list. Both choice must be already set.

=head2 move_up

Parameters: C<< ( choice ) >>

Move the choice up in the checklist.

=head2 move_down

Parameters: C<< ( choice ) >>

Move the choice down in the checklist.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,
L<Config::Model::Instance>,
L<Config::Model::Node>,
L<Config::Model::AnyId>,
L<Config::Model::ListId>,
L<Config::Model::HashId>,
L<Config::Model::Value>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005-2022 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
