#
# Class::StructTemplate - Replacement class for Class::Struct
# $Id$
#
# Copyright (C) 2000 by Heiko Wundram.
# All rights reserved.
#
# This program is free software; you can redistribute and/or modify it under the same terms as Perl itself.
#
# $Log$
#

package Class::StructTemplate;
$Class::StructTemplate::VERSION = '0.01';

require Exporter;
@Class::StructTemplate::ISA = qw(Exporter);
@Class::StructTemplate::EXPORT = qw(attributes);

use Carp;

sub attributes
{
    my $pkg = ref $_[0] ? ${ shift() } : caller();

    if( @_ < 1 )
    {
	confess "Need at least one attribute to assign to class!";
    }

    my $attrib;

    ${"${pkg}::_ATTRIBUTES"} = [@_];
    ${"${pkg}::_max_id"} = 1;

    _define_constructor($pkg) or confess("Couldn't create constructor for $pkg!");

    foreach $attrib (@${"${pkg}::_ATTRIBUTES"},"_id")
    {
	_define_accessor($pkg,$attrib) or confess("Couldn't create accessor for $pkg!");
    }

    return 1;
}

sub _define_constructor
{
    if( @_ != 1 )
    {
	confess "_define_constructor is only called with one argument!";
    }

    my ($pkg) = @_;

    my $accs = qq|
	package $pkg;

	sub new
	{
	    my (\$class,\%attribs) = \@_;
	    \$class = ref \$class ? ref \$class : \$class;
	    bless( my \$self = {}, \$class );

	    \$self->set_attributes(\%attribs,"_id"=>\$self->_next_id());

	    \$self->{"_created"} = 0;
	    \$self->{"_changed"} = 1;

	    return \$self;
	}|;

    eval $accs;

    croak $@ if $@;
    return !$@;
}

sub _define_accessor
{
    if( @_ != 2 )
    {
	confess "_define_accessor is only called with two arguments!";
    }

    my ($pkg,$attrib) = @_;

    my $accs = qq|
	package $pkg;

	sub $attrib
	{
	    my (\$class) = (shift);
	    ref \$class or confess("Can only set attribute $attrib on an instance of class $pkg!");

	    if( \@_ == 0 )
	    {
		return \$class->{"$attrib"};
	    }
	    elsif( \@_ == 1 )
	    {
		\$class->{"$attrib"} = \$_[0];
		\$class->{"_changed"} = 1;
		return \$class->{"$attrib"};
	    }
	    else
	    {
		confess("Can only retrieve or set class-data!");
		return undef;
	    }
	}|;

    eval $accs;

    croak $@ if $@;
    return !$@;
}

sub _next_id
{
    if( @_ != 1 )
    {
	confess "_next_id only called with one argument!";
    }

    my ($class) = @_;
    ref $class or confess "Can only get the next id on an instance of class $class!";
    my $pkg = ref $class;

    return ${"${pkg}::_max_id"}++;
}

sub set_attributes
{
    if( ( @_ - 1 ) % 2 != 0 )
    {
	confess "set_attributes can only be called with an even number of arguments!";
    }

    my ($class,%attribs) = @_;
    ref $class or confess "set_attributes can only be called on an instance of class $class!";
    my $pkg = ref $class;
    my $attrib;

    foreach $attrib (@${"${pkg}::_ATTRIBUTES"},"_id")
    {
	if( exists $attribs{$attrib} )
	{
	    $class->$attrib($attribs{$attrib});
	}
	elsif( !$class->{"_allset"} )
	{
	    $class->$attrib(undef);
	}
    }

    $class->{"_allset"} = 1;
    $class->{"_changed"} = 1;

    return $class;
}

sub get_attributes
{
    if( @_ != 1 )
    {
	confess "get_attributes is never called with any arguments!";
    }

    my ($class) = @_;
    ref $class or confess "get_attributes can only be called on an instance of class $class!";
    my $pkg = ref $class;
    my %ret_val = ();
    my $attrib;

    foreach $attrib (@${"${pkg}::_ATTRIBUTES"},"_id")
    {
	$ret_val{$attrib} = $class->$attrib();
    }

    return %ret_val;
}

1;
