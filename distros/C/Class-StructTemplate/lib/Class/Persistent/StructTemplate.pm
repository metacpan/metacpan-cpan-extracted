#
# Class::Persistent::StructTemplate - Persistent implementation of Class::StructTemplate. Uses a plugin to enable persistence through various interfaces.
# $Id$
#
# Copyright (C) 2000 by Heiko Wundram.
# All rights reserved.
#
# This program is free software; you can redistribute and/or modify it under the same terms as Perl itself.
#
# $Log$
#

package Class::Persistent::StructTemplate;
$Class::Persistent::StructTemplate::VERSION = '0.01';

require Exporter;
@Class::Persistent::StructTemplate::ISA = qw(Exporter Class::StructTemplate);
@Class::Persistent::StructTemplate::EXPORT = qw(attributes);

use Class::StructTemplate qw();

use Carp;

use Data::Dumper;

sub attributes
{
    my ($pkg) = ref $_[0] ? (${ shift() }) : caller();

    if( @_ < 2 )
    {
	confess "Need at least one attribute to assign to new class!";
    }

    my $plugin = shift();
    my $plugin_parms = shift();

    eval "use $plugin;";
    confess "Couldn't load storage plugin $plugin (error: $@)!" if $@;
    (${"${pkg}::_PLUGIN"} = new $plugin (@$plugin_parms)) or confess "Couldn't create storage plugin $plugin!";

    Class::StructTemplate::attributes(\$pkg,@_) or confess "Couldn't create class $pkg!";

    ${"${pkg}::_max_id"} = ${"${pkg}::_PLUGIN"}->get_max_id($pkg);

    _define_load($pkg) or confess "Couldn't create load-constructor for class $pkg!";

    return 1;
}

sub _define_load
{
    if( @_ != 1 )
    {
	confess "_define_load can only be called with one argument!";
    }

    my ($pkg) = @_;

    my $accs = qq|
	package $pkg;

	sub load
	{
	    my (\$class,\$type) = \@_;
	    \$class = ref \$class ? ref \$class : \$class;
	    my (\@self);

	    \@self = \$class->load_into(\$type);

	    return \@self;
	}|;

    eval $accs;

    croak $@ if $@;
    return !$@;
}

sub load_into
{
    if( @_ != 2 )
    {
	confess "load_into can only be called with one arguments!";
    }

    my ($class,$type) = @_;
    my $done = 0;
    my $pkg = ref $class ? ref $class : $class;
    my $self;
    my @ret_val = ();

    if( ref $class )
    {
	$done = ${"${pkg}::_PLUGIN"}->load($class,$pkg,$type);
        if( $done != -1 )
	{
	    $class->{"_created"} = 1;
	    $class->{"_changed"} = 0;
	}

        return $done!=-1?$class:undef;
    }
    else
    {
	while( !$done && $done != -1 )
	{
	    $self = new $pkg;
	    $done = ${"${pkg}::_PLUGIN"}->load($self,$pkg,$type);
            $self->{"_created"} = 1;
            $self->{"_changed"} = 0;

	    if( !$done && $done != -1 )
	    {
		$self->{"_created"} = 1;
		$self->{"_changed"} = 0;
		push @ret_val, $self;
	    }
	}

	return @ret_val;
    }
}

sub save
{
    if( @_ != 1 )
    {
	confess "save isn't called with any arguments!";
    }

    my ($class) = @_;
    ref $class or confess "Can only save an instance of class ".ref($class)."!";
    my $pkg = ref $class;
    my $done;

    if( !$class->{"_changed"} )
    {
	return 1;
    }

    if( $class->{"_created"} )
    {
	$done = ${"${pkg}::_PLUGIN"}->save($class,$pkg);
    }
    else
    {
	$done = ${"${pkg}::_PLUGIN"}->store($class,$pkg);
    }

    if( $done )
    {
	$class->{"_changed"} = 0;
	$class->{"_created"} = 1;
    }

    return $done;
}

sub delete
{
    if( @_ != 1 )
    {
	confess "delete isn't called with any arguments!";
    }

    my ($class) = @_;
    ref $class or confess "Can only delete an instance of class ".ref($class)."!";
    my $pkg = ref $class;
    my $done = 1;
    my $is_a;

    if( $class->{"_changed"} || !$class->{"_created"} )
    {
	return 0;
    }

    foreach $attrib (@${"${pkg}::_ATTRIBUTES"},"_id")
    {
	eval "\$is_a = \$class->{\$attrib}->isa('Class::Persistent::StructTemplate')";

	if( !$@ && $is_a )
	{
	    $done &= $class->{$attrib}->delete;
	}
    }

    if( ${"${pkg}::_PLUGIN"}->calc_refs($class,$pkg) <= 1 )
    {
        ${"${pkg}::_PLUGIN"}->delete($class,$pkg);
        $class->{"_created"} = 0;
        $class->{"_changed"} = 1;
    }

    ${"${pkg}::_PLUGIN"}->check_tables;

    return $done;
}


sub set_attributes_type
{
    if( @_ != 3 )
    {
	confess "set_attributes_type can only be called with two arguments!";
    }

    my ($class,$attribs,$types) = @_;
    ref $class or confess "Can only set attributes to an instance of this class!";
    my $pkg = ref $class;
    my ($attrib);

    foreach $attrib (@${"${pkg}::_ATTRIBUTES"},"_id")
    {
	if( exists $attribs->{$attrib} )
	{
	    $class->$attrib(restore_val($attribs->{$attrib},$types->{$attrib}));
	}
	elsif( !$class->{"_allset"} )
	{
	    $class->$attrib(undef);
	}
    }

    $class->{"_allset"} = 1;

    return $class;
}

sub get_attributes_type
{
    if( @_ != 1 )
    {
	confess "get_attributes is never called with arguments!";
    }

    my ($class) = @_;
    ref $class or confess "Can only get attributes of an instance of this class!";
    my $pkg = ref $class;
    my ($attrib);
    my ($ret_val1,$ret_val2) = ({},{});

    foreach $attrib (@${"${pkg}::_ATTRIBUTES"},"_id")
    {
	($ret_val1->{$attrib},$ret_val2->{$attrib}) = store_val($class->{$attrib});
    }

    return ($ret_val1,$ret_val2);
}

sub restore_val
{
    if( @_ != 2 )
    {
	confess "restore_val can only be called with two parameters!";
    }

    my ($val,$type) = @_;
    my ($id,$class);
    my $ret_val;

    if( $type eq 'n' || $type eq 's' )
    {
	$ret_val = $val;
    }
    elsif( $type eq 'c' )
    {
	$val =~ /^(.*?)\|(.*)$/;
	$id = $1;
	$class = $2;

	eval "use $class;";
	confess "Could not load class $class (error: $@)!" if $@;

	($ret_val) = $class->load("_id = $id");
    }
    else
    {
	eval $val;
    }

    return $ret_val;
}

sub store_val
{
    if( @_ != 1 )
    {
	confess "store_val can only be called with one parameter!";
    }

    my ($val) = @_;
    my ($ret_val1,$ret_val2);
    my $is_a;

    if( ref $val )
    {
	eval "\$is_a = \$val->isa('Class::Persistent::StructTemplate');";
	if( !$@ && $is_a )
	{
	    $ret_val2 = 'c';
	    $ret_val1 = $val->_id()."|".ref($val);

	    $val->save();
	}
	else
	{
	    local $Data::Dumper::Purity = 1;
	    local $Data::Dumper::Useqq = 1;
	    local $Data::Dumper::Indent = 0;

	    $ret_val2 = 'd';
	    $ret_val1 = Data::Dumper->Dump([$val],[qw(ret_val)]);
	}
    }
    elsif( $val == 0 && $val ne '0' )
    {
	$ret_val2 = 's';
	$ret_val1 = $val;
    }
    else
    {
	$ret_val2 = 'n';
	$ret_val1 = $val;
    }

    return ($ret_val1,$ret_val2);
}

1;
