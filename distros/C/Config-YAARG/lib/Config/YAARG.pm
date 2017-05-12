#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  Copyright (C) 2011 - Anthony J. Lucas - kaoyoriketsu@ansoni.com



package Config::YAARG;
use base qw( Exporter );



our $VERSION = '0.023';



use strict;
use warnings;
use feature 'switch';



use Class::ISA ( );
use Getopt::Long ( );



#EXPORT CONFIGURATION


our @PUBLIC_CONSTANTS = qw/
    ARG_PASSTHROUGH
    ARG_IGNORE
/;

our @SCRIPT_ROUTINES = qw/ARGS/;
our @CLASS_METHODS = qw/process_args/;
our @STANDARD_ROUTINES = qw/ProcessArgs/;

our @EXPORT_OK = (
    @PUBLIC_CONSTANTS,
    @STANDARD_ROUTINES,
    @SCRIPT_ROUTINES,
    @CLASS_METHODS
);

our %EXPORT_TAGS = (
    'class' => [ @PUBLIC_CONSTANTS, @CLASS_METHODS ],
    'script' => [ @PUBLIC_CONSTANTS, @SCRIPT_ROUTINES ]
);



#CONSTANTS


use constant ARG_PASSTHROUGH => 'pass';
use constant ARG_IGNORE => 'ignore';


sub ARG_NAME_LIST {};
sub ARG_NAME_MAP {};
sub ARG_VALUE_TRANS {};



#SCRIPT HELPER ROUTINE


sub ARGS {

    my $class = $_[0] || caller();
    my $config = _yaarg_fetch_config(__PACKAGE__, $class);
    my $names = $config->{names};
    return unless ($names);

    my @names = @$names;
    s/=.*?$// foreach(@$names);

    my %args = ();
    Getopt::Long::GetOptions(\%args,
        map { (!s/=b$// and !/=/) ? "$_=s" : $_ } @names);
    return %{ProcessArgs(__PACKAGE__, $config, %args)};
}



#CLASS HELPER ROUTINE


sub process_args {

    my ($self, @args) = @_;

    #detect alt call signatures
    my $target = (@args % 2)
        ? shift(@args)
        : {};

    #gather config and process args
    my $result = $self->ProcessArgs(
        $self->_yaarg_fetch_config,
        @args);

    #copy results to target struct
    $target->{$_} = $result->{$_}
        foreach (keys(%{$result}));

    return $target;
}



#CORE ROUTINES


sub ProcessArgs {

    my ($context, $config, %args) = @_;

    my $map = $config->{'map'};
    my $trans = $config->{'trans'};

    my $t_args;
    $t_args = $context->_yaarg_transform_values(\%args, $trans)
        if ($trans);
    $context->_yaarg_transform_keys($t_args, $map, 1)
        if ($map);

    return $t_args || {};
}


sub _yaarg_fetch_config {

    my ($context, $class) = @_;
    $class ||= (ref($context) || $context);

    my @ISA = Class::ISA::self_and_super_path($class);
    my (@map, @trans, @names);
    foreach (@ISA) {
        my ($m, $t, $n) =
            $context->_yaarg_fetch_class_config($_);
        push(@map, $context->_yaarg_to_list($m));
        push(@trans, $context->_yaarg_to_list($t));
        push(@names, $context->_yaarg_to_list($n));
    }
    return {
        map => {@map},
        trans => {@trans},
        names => \@names
    };
}


sub _yaarg_fetch_class_config {

    my $class = $_[1];
    my @return;

    foreach (qw/
        ARG_NAME_MAP
        ARG_VALUE_TRANS
        ARG_NAME_LIST/) {

        push(@return, (($class->can($_))
            ? $class->$_() || undef
            : undef));
    }
    return @return;
}



#UTILITY ROUTINES



sub _yaarg_to_list {

    return %{$_[1]} if (ref($_[1]) eq 'HASH');
    return @{$_[1]} if (ref($_[1]) eq 'ARRAY');
    return ();
}


sub _yaarg_transform_keys {

    my ($self, $hash, $key_map, $no_dup) = @_;
    
    my ($thash, $v) = $no_dup ? $hash : {};
    foreach (keys %$key_map) {
        if (defined($v = $hash->{$_})) {
            $thash->{$key_map->{$_}} = $v;
            delete($thash->{$_}) if ($no_dup);
        }
    }
    return $thash;
}


sub _yaarg_transform_values {
    _yaarg_transform_values_r(@_[0..2], '');
}


sub _yaarg_transform_values_r {

    my ($self, $struct, $type_map, $key) = @_;


    #attempt reading common data structures
    given (ref($struct)) {

        when ('ARRAY') {
            return [ map {
                $self->_yaarg_transform_values_r($_, $type_map, $key);
                } @$struct ];
        }
        default {

            my $target = (defined($key) and $type_map)
                ? $type_map->{$key}
                : undef;
            
            #attempt custom type mapping
            if ($target) {
                given (ref($target)) {
                    when ('CODE') {
                        return $target->($struct);
                    }
                    when ('') {
                        return $target->new($struct) if ($target);
                    }
                }
            } elsif (ref($struct) eq 'HASH') {

                $target = {};
                foreach (keys(%$struct)) {
                    $target->{$_} = $self->_yaarg_transform_values_r(
                        $struct->{$_}, $type_map, $_);
                }
                return $target;
            }
        }
    }
    #otherwise return unchanged
    return $struct;
}





1;
