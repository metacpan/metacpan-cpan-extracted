# Class::Core Wrapper System
# Version 0.03 alpha 2/26/2013
# Copyright (C) 2013 David Helkowski

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.  You may also can
# redistribute it and/or modify it under the terms of the Perl
# Artistic License.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

=head1 NAME

Class::Core - Class wrapper system providing parameter typing, logging, and class auto-instanitation

=head1 VERSION

0.04

=cut

# The container that is wrapped around an object for remote calling
package Class::Core::VIRTCALL;
use strict;
use Carp;
#use Data::Dumper;
use XML::Bare qw/xval forcearray/;
use Data::Dumper;
our $AUTOLOAD;

sub DESTROY { Class::Core::VIRT::DESTROY( @_ ); }

sub AUTOLOAD {
    my $virt = shift;
    my $tocall = $AUTOLOAD;
    $tocall =~ s/^Class::Core::VIRTCALL:://;
    
    my $obj = $virt->{'obj'};
    my $map = $obj->{'_map'};
    my $ref = $map->{ $tocall }; # grab the function reference if there is one ( if not is a virtual call )
    my $cls = $obj->{'_class'};
    my $spec = $obj->{'_spec'};
    if( ( scalar @_ ) % 2 ) { confess "Non even list - $cls->$tocall\n"; }
    my %parms = @_;
    
    # Skipping spec checking on remote calls, for now - TODO
        
    my $inner = { parms => \%parms, _funcspec => ($spec ? $spec->{'funcs'}{$tocall} : 0), virt => $virt };#_glob => $obj->{'_glob'}, 
    bless $inner, "Class::Core::INNER";
    my $callback = $obj->{'_callback'};
    
    my $okay = 1;
    if( $callback ) {
        # inner contains call parameters
        # virt is the virtual wrapper around the object
        $okay = &$callback( $inner, $virt, $tocall, \%parms );
    }
    if( !$okay ) {
        die "Call to $tocall in $cls failed due to callback\n";
    }
    
    my %noremote = (
        #'_duplicate' => 1
        );
    if( $noremote{ $tocall } ) {
       $inner->{'ret'} = &$ref( $inner, $virt ); # call these functions directlhy
    }
    else {
    
        print "Attempt to call remote function $tocall on class $cls\n";
        my $xml = Class::Core::_hash2xml( \%parms );
        print "Args:$xml\n";
        
        my $callfunc = $virt->{'_callfunc'};
        my $app = $obj->{'_app'};
        my $call = $virt->{'_call'};
        $inner->{'ret'} = $callfunc->( $app, $call, $tocall, $xml );
        
        # Skipping checking of return value - TODO
    }
    
    return $inner->{'res'} ? $inner : $inner->{'ret'};
}

sub _duplicate {
    my $virt = shift;
    my $obj = $virt->{'obj'};
    #print "Duplicating ".$obj->{'_class'}."\n";
    my $newvirt = { obj => $obj, src => $virt, @_ };
    return bless $newvirt, 'Class::Core::VIRTCALL';
}

sub _hasfunc {
    my ( $ob, $tocall ) = @_;
    #my $spec = $ob->{'obj'}{'_spec'};
    #return $spec->{'funcs'}{ $tocall };
    return $ob->{'obj'}{'_map'}{ $tocall };
}

# The container that is wrapped around the object
package Class::Core::VIRT;
use strict;
use Carp;
#use Data::Dumper;
use XML::Bare qw/xval forcearray/;
use Data::Dumper;
our $AUTOLOAD;
use threads;

sub DESTROY {
    my $virt = shift;
    my $obj = $virt->{'obj'};
    my $map = $obj->{'_map'};
    my $cls = $obj->{'_class'};
    #my $thr = threads->self();
    #my $tid = $thr->tid();
    #return if( $tid ); # this is only required really if we are using ithreads ( eg: win32 )
    if( $virt->{'src'} ) {
        #print "Attempting to destroy request copy an object of type $cls\n";
    }
    else {
        #print "Attempting to destroy an object of type $cls\n";
    }
} # If this is not defined, AUTOLOAD gets called for it and creates problems ( on Win32 at any rate )

sub AUTOLOAD {
    my $virt = shift;
    my $tocall = $AUTOLOAD;
    $tocall =~ s/^Class::Core::VIRT:://;
    
    my $obj = $virt->{'obj'};
    my $map = $obj->{'_map'};
    my $ref = $map->{ $tocall }; # grab the function reference
    my $cls = $obj->{'_class'};
    if( !$ref ) {
        confess "No function $tocall in $cls\n";
    }
    my $spec = $obj->{'_spec'};
    my $pcount = ( scalar @_ );
    my $x = 0;
    my %parms;
    if( $pcount % 2 ) {
        if( $pcount != 1 ) {
            confess "Non even list - $cls->$tocall\n";
        }
        else {
            $x = $_[0];
        }
    }
    else {
        %parms = @_;
    }
    
    my $allerr = '';
    my $fspec;
    if( $spec ) {
        $fspec = $spec->{'funcs'}{ $tocall };
        if( $fspec ) { # if the function has specs; make sure one passes
            if( $fspec->{'sig'} ) {
                # Additionally check global specs if they are set
                if( $fspec->{'in'} || $fspec->{'out'} || $fspec->{'ret'} ) {
                    my $err = _checkspec( $obj, $fspec, \%parms );
                    $allerr .= $err if( $err );
                }
                
                my $sigs = forcearray( $fspec->{'sig'} );
                my $ok = 0;
                for my $sig ( @$sigs ) {
                    my $err = _checkspec( $virt, $sig, \%parms );
                    if( $err ) {
                        $allerr .= "$err\n";
                    }
                    else {
                        $ok = 1;
                        if( $sig->{'set'} ) {
                            my $sets = forcearray( $sig->{'set'} );
                            for my $set ( @$sets ) {
                                my $name = xval $set->{'name'};
                                my $val = xval $set->{'val'};
                                print "Setting $name to $val\n";
                            }
                        }
                        last;
                    }
                }
            }
            else {
                $allerr .= _checkspec( $obj, $fspec, \%parms );
            }
        }
    }
    
    die $allerr if( $allerr );
        
    my $inner = { parms => \%parms, _funcspec => $fspec, virt => $virt };#_glob => $obj->{'_glob'}, 
    bless $inner, "Class::Core::INNER";
    my $callback = $obj->{'_callback'};
    my $calldone = $obj->{'_calldone'};
    if( $callback && !$calldone ) { die "wtf"; }
    if( !$callback && $calldone ) { die "wtf"; }
    
    my $okay = 1;
    my $callid = 0;
    if( $callback ) {
        # inner contains call parameters
        # virt is the virtual wrapper around the object
        
        $okay = &$callback( $inner, $virt, $tocall, \%parms, \$callid );
    }
    if( !$okay ) {
        #die "Call to $tocall in $cls failed due to callback\n";
        if( $calldone ) {
            &$calldone( $inner, $virt, $tocall, \%parms, $callid );
        }
        return 0;
    }
    
    my $rval = $inner->{'ret'} = &$ref( $inner, $virt, $x ); # call the function
    if( $spec ) {
        my $retspec = $spec->{'ret'};
        if( $retspec && %$retspec ) {
            my $type = $retspec->{'type'};
            my $err = _checkval( $retspec, $type, $rval );
            die "While checking return - $err" if( $err );
        }
    }
    
    if( $calldone ) {
        &$calldone( $inner, $virt, $tocall, \%parms, $callid );
    }
    
    return $inner->{'res'} ? $inner : $inner->{'ret'};
}

sub get_source {
    my ( $ob ) = @_;
    return $ob->{'src'};
}

sub _hasfunc {
    my ( $ob, $tocall ) = @_;
    #my $spec = $ob->{'obj'}{'_spec'};
    #return $spec->{'funcs'}{ $tocall };
    return $ob->{'obj'}{'_map'}{ $tocall };
}

sub _checkspec {
    my ( $obj, $spec, $parms ) = @_;
    my $state = $spec->{'state'};
    if( $state && $state ne $obj->{'_state'} ) {
        _tostate( $obj, $state );
    }
    my $ins = $spec->{'in'};
    for my $key ( keys %$ins ) {
        my $in = $ins->{ $key };
        my $type = $in->{'type'};
        my $val = $parms->{ $key };
        my $err = _checkval( $in, $type, $val );
        return "While checking $key - $err" if( $err );
    }
    return 0;
}

sub _tostate {
    my ( $obj, $dest ) = @_;
    print "Attempt to change to state $dest\n";
    $obj->{'_map'}{'init_'.$dest}->();
    $obj->{'_state'} = $dest;
}

sub _checkval {
    my ( $node, $type, $val ) = @_;
    my $xml = $node->{'xml'};
    if( ! defined $val ) {
        if( $xml->{'optional'} ) { return 0; }
        #my @arr = caller;
        return "not defined and should be a $type";
    }
    my $err = 'undefined';
    
    if( $type eq 'number' ) { $err = _checknum( $node, $val ); }
    if( $type eq 'bool' ) { $err = _checkbool( $node, $val ); }
    if( $type eq 'path' ) { $err = _checkpath( $node, $val ); }
    if( $type eq 'hash' ) { $err = _checkhash( $node, $val ); }
    return $err;
}

# Note that the 'hash' type could refer to another 'hash' type.
#   This will not actually cause loops even if referring to the same hash, because
#   a different inset set of specs will be followed. If the spec is changed to take use
#   of 'shared' signatures that can be checked in multiple functions, then loops could occur.
sub _checkhash {
    my ( $node, $val ) = @_;
    my $spec = $node->{'xml'};
    if( $spec->{'sig'} ) {
        my $sigs = forcearray( $spec->{'sig'} );
        my $allerr = '';
        my $ok = 0;
        for my $sig ( @$sigs ) {
            # Note that the first parameter to the following function is set to 0. This is ob.
            #   This is needed to be able to change the state of ob if needed based on the spec.
            #   When checking a hash, a hash does not need to change the state so this doesn't matter.
            #   Note that bad things will happen if you set the 'state' attribute on a hash signature.
            #   Don't do that.
            my $err = _checkspec( 0, $sig, $val );
            if( $err ) {
                $allerr .= "$err\n";
            }
            else {
                $ok = 1;
                # We are going to still allow setting of variables within a hash. This is likely overkill, and
                #   this code should probably be removed. Leaving it for now for parallelism.
                if( $sig->{'set'} ) {
                    my $sets = forcearray( $sig->{'set'} );
                    for my $set ( @$sets ) {
                        my $name = xval $set->{'name'};
                        my $val = xval $set->{'val'};
                        print "Setting $name to $val\n";
                    }
                }
                last;
            }
        }
        if( !$ok ) {
            return $allerr;
        }
    }
    else {
         my $err = _checkspec( 0, $spec, $val );
         return $err if( $err );
    }
    return 0;
}

sub _checkpath {
    my ( $in, $val ) = @_;
    my $clean = $val;
    $clean =~ s|//+|/|g;
    if( $clean ne $val ) { return "Path contains // - Path is \"$val\""; }
    $clean =~ s/[:?*+%<>|]//g;
    if( $clean ne $val ) { return "Path contains one of the following ':?*+\%<>|' - Path is \"$val\""; }
    my $xml =  $in->{'xml'};
    if   ( $xml->{'isdir' } && ! -d $clean ) { return "Dir  does not exist - \"$clean\""; }
    elsif( $xml->{'isfile'} && ! -f $clean ) { return "File does not exist - \"$clean\""; }
    elsif( $xml->{'exists'} && ! -e $clean ) { return "Path does not exist - \"$clean\""; }
}

sub _checkbool {
    my ( $in, $val ) = @_;
    {
        no warnings 'numeric';
        if( ($val+0 ne $val) || ( $val != 0 && $val != 1 ) ) {
            return "not a boolean ( it is $val )";
        }
    }
    return 0;
}

sub _checknum {
    my ( $in, $val ) = @_;
    {
        no warnings 'numeric';
        if( $val*1 ne $val ) {
            return "not a number ( it is \"$val\" )";
        }
    }
    my $xml = $in->{'xml'};
    if( $xml->{'min'} ) {
        my $min = xval $xml->{'min'};
        if( $val < $min ) {
            return "less than the allowed minimum of $min ( it is $val )";
        }
    }
    if( $xml->{'max'} ) {
        my $max = xval $xml->{'max'};
        if( $val > $max ) {
            return "more than the allowed maxmimum of $max ( it is $val )";
        }
    }
    return 0;
}

sub _duplicate {
    my $virt = shift;
    my $obj = $virt->{'obj'};
    #print "Duplicating ".$obj->{'_class'}."\n";
    my $newvirt = { obj => $obj, src => $virt, @_ };
    return bless $newvirt, 'Class::Core::VIRT';
}

# Parameter input and output container
package Class::Core::INNER;
use strict;
use Data::Dumper;
use Carp;

our $AUTOLOAD;

sub AUTOLOAD {
    my $virt = shift;
    my $tocall = $AUTOLOAD;
    #print "Tocall: $tocall\n";
    if( $tocall =~ s/^Class::Core::INNER::// ) {
        my $extend;
        #print "******** Virt call to $tocall\n";
        #$Data::Dumper::Maxdepth = 2;
        $virt = $virt->{'virt'};
        #print Dumper( $virt );
        if( $extend = $virt->{'_extend'} ) {
            return $extend->$tocall( $virt, @_ );
        }
        confess "No extension - $tocall";
    }
}
sub DESTROY {
}
sub get {
    my ( $inner, $name ) = @_;
    return $inner->{'parms'}{ $name }; 
}
sub get_all {
    my $inner = shift;
    return $inner->{'parms'};
}
sub set {
    my ( $inner, $name, $val ) = @_;
    $inner->{'res'}{ $name } = $val;
}
sub get_res {
    my ( $inner, $name ) = @_;
    return $inner->{'res'}{ $name } || undef; 
}
sub get_all_res {
    my ( $inner, $name ) = @_;
    return $inner->{'res'}; 
}

# get an array of items
sub get_arr {
    my ( $inner ) = shift;
    my @ret;
    for my $key ( @_ ) {
        push( @ret, $inner->{'parms'}{ $key } );
    }
    return @ret;
}
sub add {
    my ( $inner, $name, $val ) = @_;
    
    my $spec = $inner->{'_funcspec'};
    my $outs = $spec->{'out'};
    #print Dumper( $self );
    my $outspec = $outs->{ $name };
    
    if( $outspec ) {
       my $type = $outspec->{'type'};
       my $err = Class::Core::VIRT::_checkval( $outspec, $type, $val );
       die "While checking $name - $err" if( $err );
    }
    $inner->{'parms'}{$name} = $val;
}

package Class::Core;
use strict;
use Data::Dumper;
use XML::Bare qw/xval forcearray/;
use vars qw/@EXPORT_OK @EXPORT @ISA %EXPORT_TAGS $VERSION/;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw//;
@EXPORT_OK = qw/new/;
%EXPORT_TAGS = ( all => [ qw/new/ ] );
$VERSION = '0.04';

sub read_spec {
    my ( $func ) = @_;
    my ( %in, %out, %ret );
    my $func_spec = { in => \%in, out => \%out, ret => \%ret, x => $func };
    
    my $ins = forcearray( $func->{'in'} );
    for my $in ( @$ins ) {
        my $name = xval $in->{'name'};
        my $type = xval $in->{'type'}, 'any';
        $in{ $name } = { type => $type, xml => $in };
    }
    
    my $outs = forcearray( $func->{'out'} );
    for my $out ( @$outs ) {
        my $name = xval $out->{'name'};
        my $type = xval $out->{'type'}, 'any';
        $out{ $name } = { type => $type, xml => $out };
    }
    
    my $ret_x = $func->{'ret'};
    if( $ret_x ) {
       my $type = xval $ret_x->{'type'};
       $ret{'type'} = $type;
       $ret{'xml'} = $ret_x;
    }
    
    if( $func->{'state'} ) {
        my $state = xval $func->{'state'};
        $func_spec->{'state'} = $state;
    }
    
    if( $func->{'set'} ) {
        $func_spec->{'set'} = $func->{'set'};
    }
    
    if( $func->{'perms'} ) {
        my @arr = split(',', $func->{'perms'}{'value'} );
        $func_spec->{'perms'} = \@arr;
    }
    
    return $func_spec;
}

sub create_object {
    my ( $class, $objin ) = @_;
    no strict 'refs';
    
    my $map = {};
    my %obj = ( _class => $class, _state => '_loaded', _map => $map, %$objin );
    my $glob = $obj{'_glob'};
    
    my $classes = $glob->{'classes'};
    
    # Read in the specification setup for the passed class
    my $spectext = ${"$class\::spec"} || 'file';
    if( $spectext ) {
        my ( $ob, $xml );
        if( $spectext eq 'file' ) {
            my $file = $class;
            $file =~ s|::|/|g;
            my $pm_xml = $INC{ "$file.pm" } . ".xml";
            ( $ob, $xml ) = new XML::Bare( file => $pm_xml );
        }
        else {
            ( $ob, $xml ) = new XML::Bare( text => $spectext );
        }
        my $func_specs = {};
        my %spec = ( funcs => $func_specs );
        $obj{'_spec'} = \%spec;
        $obj{'_specx'} = $xml;
        my $funcs = forcearray( $xml->{'func'} );
        for my $func ( @$funcs ) {
            my $name = xval $func->{'name'};
            
            my $func_spec;
            if( $func->{'sig'} ) {
                my $sigs = forcearray( $func->{'sig'} );
                my @func_specs = ();
                for my $sig ( @$sigs ) {
                    push( @func_specs, read_spec( $sig ) );
                }
                $func_spec = { sig => \@func_specs };
            }
            else {
                $func_spec = read_spec( $func );
            }
            $func_specs->{ $name } = $func_spec;
        }
    }
    
    # Create duplicates of all functions in the source class
    my $ref = \%{"$class\::"};
    
    #print "$class:\n";
    for my $key ( keys %$ref ) {
        next if( $key =~ m/^(new|import|DESTROY|BEGIN)$/ );
        #print "  $key\n";
        my $func_ref = \&{"$class\::$key"};
        my $fname = $key;
        $key =~ s/^$class\:://;
        $map->{ $fname } = $func_ref;
    }
    
    return \%obj;
}
my %obj_store;
sub new {
    my $class = shift; # this is the name of the class; eg: Module::test
    no strict 'refs';
    
    my %hashin = ( @_ );
    
    my $objin = $hashin{'obj'} || {};
    my $glob = ( $objin->{'_glob'} ||= { objs => {} } );
    my $objs = $glob->{'objs'};  
    
    my $obj;
    if( ( $obj = $objs->{ $class } ) ) {
    }
    else {
        $obj = $objs->{ $class } = create_object( $class, $objin );
    }
        
    # Create the virtual wrapper
    my %hash = ( %hashin, obj => $obj );
    my $hashref = \%hash; 
    if( $hashin{'_call'} ) {
        bless $hashref, 'Class::Core::VIRTCALL';
    }
    else {
        bless $hashref, 'Class::Core::VIRT';
    }
    # push( @{ $obj->{'insts'} }, $hashref ); perhaps we want to store the instance
     
    # Call the constructor if one exists
    my $map = $obj->{'_map'};
    if( $map->{'construct'} ) { $hashref->construct(); }
    
    return $hashref;
}

sub _hash2xml {
    my ( $node, $name ) = @_;
    my $ref = ref( $node );
    return if( $name && $name =~ m/^\_/ );
    my $txt = $name ? "<$name>" : '';
    if( $ref eq 'ARRAY' ) {
       $txt = '';
       for my $sub ( @$node ) {
           $txt .= _hash2xml( $sub, $name );
       }
       return $txt;
    }
    elsif( $ref eq 'HASH' ) {
       for my $key ( keys %$node ) {
           $txt .= _hash2xml( $node->{ $key }, $key );
       }
    }
    else {
        $node ||= '';
        if( $node =~ /[<]/ ) { $txt .= '<![CDATA[' . $node . ']]>'; }
        else { $txt .= $node; }
    }
    if( $name ) {
        $txt .= "</$name>";
    }
        
    return $txt;
}

1;

__END__

=head1 SYNOPSIS

TestMod.pm.xml

    <func name='test'>
        <in name='input' type='number'/>
        <ret type='bool'/>
    </func>

TestMod.pm

    package TestMod;
    use Class::Core qw/:all/;
    
    sub test {
        my ( $core, $self ) = @_;
        my $input = $core->get('input');
        return 0;
    }

Test.pl

    use TestMod;
    my $ob = new TestMod();
    $ob->test( input => '1' ); # will work fine
    $ob->test( input => 'string' ); # will cause an error

=head1 DESCRIPTION

This module is meant to provide a clean class/object system with the following features:

=over 4

=item * Wrapped functions

All class functions are wrapped and used indirectly

=item * Named parameters

Function parameters are always passed by name

    <func name='add'>
        <in name='a'/>
        <in name='b'/>
    </func>

=item * Parameter Type Checking

Function parameters are type checked based on a provided specification in XML

    <func name='add'>
        <in name='a' type='number'/>
        <in name='b' type='number'/>
    </func>

=item * Function Overloading

Functions can be overloaded by using multiple typed function "signatures"

    <func name='runhash'>
        <sig>
            <in name='recurse' type='bool' optional/>
            <in name='path' type='path' isdir/>
            <set name='mode' val='dir'/>
        </sig>
        <sig>
            <in name='path' type='path' isfile/>
            <set name='mode' val='file'/>
        </sig>
    </func>
    
Each 'sig' ( signature ) will be checked in order till one of them validates. The
first one to validate is used. The 'set' node are run on the signature that validates.

=item * Automatic Object Instantiation ( coming )

Classes are automatically instantiated when needed based on dependencies 

=item * Object States ( coming )

Classes / Objects can have multiple states 

=item * Automatic State Change ( coming )

Class methods may require their owning object to be in a specific case in order to run
 ( in which case the proper function to change states will be called automatically ) 

=back

=head2 Function Parameter Validation

=head3 Input Parameters

    <func name='add'>
        <in name='a'/>
        <in name='b'/>
    </func>

=head3 Output Parameters

    <func name='add'>
        <out name='a'/>
        <out name='b'/>
    </func>

=head3 Classic Return Type

    <func name='check_okay'>
        <ret type='bool'/>
    </func>

=head2 Parameter Types

=head3 Number

The 'number' type validates that the parameter is numerical. Note that it does this
by checked that adding 0 to the number does not affect it. Because of this trailing
zeros will cause the validation to fail. This is expected and normal behavior.

The 'min' and 'max' attributes can be used to set the allowable numerical range.

=head3 Text

The 'text' type validates that the passed parameter is a literal string of some sort.
( as opposed to being a reference of some sort )

=head3 Date ( coming )

=head3 Path

The 'path' type validates that the passed parameter is a valid pathname.

The 'exists' attribute can be added to ensure there is a directory or file
existing at the specified path.

The 'isdir' attribute can be used to check that the path is to a directory.

The 'isfile' attribute can be used to check that the path is to a file.

=head3 Boolean

The 'boolean' type validates that the passed parameter is either 0 or 1. Any
other values will not validate.

=head3 Hash

The 'hash' type vlidates that the passed paramter is a reference to a hash,
and then further validates the contents of the hash in the same way that
parameters are validated.

    <func name='do_something'>
        <in name='person' type='hash'>
            <in name='name' type='text'/>
            <in name='age' type='number'/>
        </in>
    </func>

=head1 LICENSE

  Copyright (C) 2013 David Helkowski
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 2 of the
  License, or (at your option) any later version.  You may also can
  redistribute it and/or modify it under the terms of the Perl
  Artistic License.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

=cut
