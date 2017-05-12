# -*- Mode: perl -*-
#
# $Id: Cfg.pm,v 0.1.1.1 2001/07/13 17:05:28 ram Exp $
#
#  Copyright (c) 2000-2001, Christophe Dehaudt & Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Cfg.pm,v $
# Revision 0.1.1.1  2001/07/13 17:05:28  ram
# patch2: random cleanup (from CDE)
#
# Revision 0.1  2001/03/31 10:04:36  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package Carp::Datum::Cfg;

use Carp::Datum::Flags;

use Getargs::Long qw(ignorecase);

require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = (qw(
              ),
           @Carp::Datum::Flags::EXPORT);

use vars qw($DEBUG_TABLE);

#
# Structure of the hash ref that is returned by the parser:
#
# FLAG_SETTING:
# { debug => [ DTM_SET, DTM_CLEAR ],
#   trace => [ DTM_SET, DTM_CLEAR ],
#   args  => VAL
# }
#
# debug and trace correspond to a two values array. First value is the
# set mask and the second is the clear one.
#
# args indicates the maximum number of arguments that is printed
# during the tracing of the flow. -1 means all arguments.
#
#
# DEBUG_TABLE:
# { default   => FLAG_SETTING,
#
#   routine   => { "routine_name1" => FLAG_SETTING,
#                  "routine_name2" => FLAG_SETTING,
#                  ....
#                },
#
#   file      => { flags     => { "path1" => FLAG_SETTING,
#                                 "path2" => FLAG_SETTING,
#                                 ....
#                               },
#                  routine   => { "routine_name1" => FLAG_SETTING,
#                                 "routine_name2" => FLAG_SETTING,
#                                 ....
#                               }
#                },
#
#   type      => { flags     => { "type1" => FLAG_SETTING,
#                                 "type2" => FLAG_SETTING,
#                                 ....
#                               },
#                  routine   => { "routine_name1" => FLAG_SETTING,
#                                 "routine_name2" => FLAG_SETTING,
#                                 ....
#                               }
#                },
#
#   alias     => [ [ "path1", "alias1" ],
#                  [ "path2", "alias2" ],
#                  ....
#                ],
#
#   define    => { "name1" => FLAG_SETTING,
#                  "name2" => FLAG_SETTING,
#                  ....
#                }
# }
#
#   



# default debug table
$DEBUG_TABLE = {default => { debug => [DBG_ALL, 0],
                             trace => [TRC_ALL, 0],
                             args => -1
                           },
                alias => []
               };

#
# ->make
#
#
# Arguments:
#   -file     => $filename: file to load [optionnal]
#   -config   => $string: string which contains config set up [optionnal]
#
sub make {
    my $self = bless {}, shift;
    my ($filename, $raw_config) = cgetargs(@_, [qw(file config)]);

    $self->{cfg_table} = $DEBUG_TABLE;
	local $_ = '';
    
    if (defined $filename && open(XFILE, $filename)) {
        
        $_ = "\n" . join('', <XFILE>);
        die $@ if $@;
        close XFILE;
    }

    if (defined $raw_config) {
        $_ .= "\n" . $raw_config;
        $filename .= " + " if defined $filename;
        $filename .= "'RAW DATA CONFIGURATION'";
    }

    # to prevent the parsing when the given parameter is a fake
    # filename, there is a test on the string to parse. It must
    # contain a blank character to possibly be parsed. A non existing
    # path will not contain this character.
    if (/\s/) {
        # use the parser to populate the debug tree structure
        my $p = Carp::Datum::Parser->new(\&Carp::Datum::Parser::yylex,
                                          \&Carp::Datum::Parser::yyerror, 0);
        $p->init_parser($filename);
        my $result = $p->yyparse();
        
        # add the default values to the result if they have not been
        # set during the parsing
        while (my ($k, $v) = each %$DEBUG_TABLE) {
            $result->{$k} = $v unless defined $result->{$k};
        }
        
        $self->{cfg_table} = $result;
    }

    # separate the result in different attibutes to speed-up the
    # processing (one dereference is saved). That is also beautifying
    # the code.
    $self->{cfg_file} = $self->cfg_table->{file};
    $self->{cfg_routine} = $self->cfg_table->{routine};
    $self->{cfg_cluster} = $self->cfg_table->{cluster};
    $self->{cfg_type} = $self->cfg_table->{type};
    $self->{cfg_alias} = $self->cfg_table->{alias};

    return $self;
}


#########################################################################
# Internal Attribute Access: these methods are not intended to be used  #
# from the external of the object.                                      #
#########################################################################

sub cfg_table    {$_[0]->{cfg_table}}
sub cfg_alias    {$_[0]->{cfg_alias}}

#
# ->basename
#
sub basename {
    my $name = shift;
    my $result = $name;

    if ($name =~ /\//) {
        ($result) = $name =~ /.*\/(\S+)/;
    }
    return $result;
}


#
# ->add_flag
#
# static class function that is used by the flag routine when additive
# method is requested for flag computation.
#
# Arguments:
#   $old: old value,
#   $new: new value (can be undef or null)
#
# Returns:
#   the clear bits of new are cleared on old and set bits of new are
#   set on old.
#
sub add_flag {
    my ($old, $new) = @_;

    if (defined $new && $new != 0) {
        return $old & ~$new->[DTM_CLEAR] | $new->[DTM_SET];
    }
    return $old;
}

#
# ->add_args
#
# static class function that is used by the flag routine when replacing
# method is requested for flag computation.
#
# Arguments:
#   $old: old value,
#   $new: new value (can be undef or null)
#
# Returns:
#   the new value if defined
#
sub add_args {
    my ($old, $new) = @_;

    return $old unless defined $new;
    return $new;
}

#########################################################################
# Class Feature: usable from the external world                         #
#########################################################################


#
# ->check_debug
#
# return true when the given mask matches the flag setting for debug
# mode
#
# Arguments:
#   $mask: bit field that is compared to the setting.
#
#   $caller_penalty: [optional] allows to provide a penalty used to
#   determine the function features (via caller()) that is used to get
#   the configuration setting. When not specified or 0, the call level
#   right above the function that call the check_debug (2 steps from
#   here) will be used.
#
# Returns:
#   a boolean value.
#
sub check_debug {
    return $_[0]->flag('debug', @_ == 3 ? ($_[2]+1) : 1) & $_[1];
}

#
# ->check_trace
#
# return true when the given mask matches the flag setting for trace
# mode
#
# Arguments:
#   $mask: bit field that is compared to the setting.
#
#   $caller_penalty: [optional] allows to provide a penalty used to
#   determine the function features (via caller()) that is used to get
#   the configuration setting. When not specified or 0, the call level
#   right above the function that call the check_trace (2 steps from
#   here) will be used.
#
# Returns:
#   a boolean value.
#
sub check_trace {
    return $_[0]->flag('trace', @_ == 3 ? ($_[2]+1) : 1) & $_[1];
}


#
# ->flag
#
# Perform a walkthrough the different level of configuration setting
# and and gets a (additive | replacing) value for the result computation.
#
# When requesting the flag for 'debug' or 'trace', each stage value is
# added.  For 'args' request, each value overwrites the previous one.
#
# The walkthrough is perfomed in the following order:
#    - default
#    - file
#    - routine
#    - routine for file
#    - type
#    - routine for type
# 
# Arguments:
#   $field: string that indicates the key that is used during the
#   walkthrough. It is either 'debug', 'trace' or 'args'.
#
#   $caller_penalty: [optional] allows to provide a penalty used to
#   determine the function features (via caller()) that is used to get
#   the configuration setting. When not specified or 0, the call level
#   right above the function that call the check_trace (2 steps from
#   here) will be used.
#
# Returns:
#   a value that depends from the $field request:
#       for 'debug' and 'trace': it represents a bit field.
#       for 'args': it is an integer..
#
sub flag {
    my $self = shift;
    my ($field, $caller_penalty) = @_;

    # get debug caller (for filename location)
    my $caller_level = defined $caller_penalty ? (1 + $caller_penalty) : 1;
    my ($package, $filename, $line1) = caller($caller_level);

    # get debug caller (for routine name)
    package DB;  
    use vars qw(@args); # ignore warning
    my ($package1, $filename1, $line, $subroutine,
        $hasargs, $wantarray, $evaltext, $is_require) = 
          caller($caller_level + 1);
    package Carp::Datum::Cfg;

    # the method that is gonna used to compute the different flag
    # depends of what it is looked for:
    # 'debug' or 'trace' -> flags are merged during the walkthrough
    # 'args' -> value are overwritten during the walkthough
    my $merge_routine = \&add_flag;
    $merge_routine = \&add_args if $field eq 'args';

	$subroutine = '' unless defined $subroutine;
    my ($func_name) = $subroutine =~ /.*::(\S+)/;
    my $file_routine = undef;
    my $type_routine = undef;

    # first get the default flag setting
    my $result = &$merge_routine(0, $self->cfg_table->{default}->{$field});

    # update with cluster setting
    my $cluster_cfg = $self->{cfg_cluster};
    if (defined $cluster_cfg) {
        # perhaps, the package gets directly an entry in the table
        if (defined $cluster_cfg->{$package}) {
            $result = &$merge_routine(
                $result, 
                $cluster_cfg->{$package}->{flags}->{$field}
            );
        }
        else {
            # anyway, try to find a filter matching a part of the package name
            my $tmp = $package;
            while ($tmp =~ /(.*)::/) {
                $tmp = $1;
                if (defined $cluster_cfg->{$tmp}) {
                    $result = &$merge_routine(
                        $result, 
                        $cluster_cfg->{$tmp}->{flags}->{$field}
                    );
                    last;
                }

            };
        }
    }

    # update with file specific setting (if any), trying base name second
    my $file_cfg = $self->{cfg_file}->{$filename};
    if (defined $file_cfg) {
        $result = &$merge_routine($result, $file_cfg->{flags}->{$field});
        $file_routine = $file_cfg->{routine}->{$func_name};
    }
    else {
        $file_cfg = $self->{cfg_file}->{basename($filename)};
        if (defined $file_cfg) {
            $result = &$merge_routine($result, $file_cfg->{flags}->{$field});
            $file_routine = $file_cfg->{routine}->{$func_name};
        }
    }
    
    # update with routine specific setting (if any)
    my $routine_cfg = $self->{cfg_routine}->{$func_name};
    $result = &$merge_routine($result, $routine_cfg->{flags}->{$field});
    
    # update with routine specific setting from file specification (if any)
    $result = &$merge_routine($result, $file_routine->{flags}->{$field});
    
    # update with dynamic type specific setting (if any)
    my $dyna_type = '';
    ($dyna_type) = $DB::args[0] =~ /(.*)=\w+\(.*\)/ if defined $DB::args[0];
    my $dyna_cfg = $self->{cfg_type}->{$dyna_type};
    $result = &$merge_routine($result, $dyna_cfg->{flags}->{$field});

    # update with routine specific setting from type specification (if any)
    $type_routine = $dyna_cfg->{routine}->{$func_name};
    $result = &$merge_routine($result, $type_routine->{flags}->{$field});

    return $result;
}

1;

=head1 NAME

Carp::Datum::Cfg - Dynamic Debug Configuration Setting for Datum

=head1 SYNOPSIS

 # In application's main
 use Carp::Datum qw(:all on);      # turns Datum "on" or "off"
 DLOAD_CONFIG(-file => "./debug.cf", -config => "config string");

=head1 DESCRIPTION

By using the DLOAD_CONFIG function in an application's main file, 
a debugging configuration can be dynamically loaded to define a particular
level of debug/trace flags for a specific sub-part of code.

For instance, the tracing can be turned off when entering a routine
of a designated package. That is very useful for concentrating the
debugging onto the area that is presently developed and/or to filter
some verbose parts of code (recursive function call), when they don't
need to be monitored to fix the problem.

=head1 EXAMPLE

Before the obscure explaination of the grammar, here is an example of
what can be specified by dynamic configuration:

  /* 
   * flags definition: macro that can be used in further configuration
   * settings
   */
  flags common {
      all(yes);
      trace(yes): all;
  }

  flags silent {
      all(yes);
      flow(no);
      trace(no);
      return(no);
  }

  /*
   * default setting to use when there is no specific setting 
   * for the area
   */
  default common;


  /*
   * specific settings for specific areas
   */
  routine "context", "cleanup"                 { use silent; }
  routine "validate", "is_num", "is_greater"   { use silent; }

  file "Keyed_Tree.pm"                         { use silent; }
  file "Color.pm" {
      use silent; 
      trace(yes): emergency, alert, critical;
  }

  cluster "CGI::MxScreen" {
      use silent; 
      assert(no);
      ensure(no);
  }

  /*
   * aliasing to reduce the trace output line length
   */

  alias "/home/dehaudtc/usr/perl/lib/site_perl/5.6.0/CGI" => "<PM>";

=head1 INTERFACE

The only user interface is the C<DLOAD_CONFIG> routine, which expects
the following optional named parameters:

=over 4

=item C<-config> => I<string>

Give an inlined configuration string that is appended to the one
defined by C<-file>, if any.

=item C<-file> => I<filename>

Specifies the configuration file to load to initialize the
debugging and tracing flags to be used for this run.

=back

=head1 CONFIGURATION DIRECTIVES

=head2 Main Configuration Directives

The following main directives can appear at a nesting level of 0.  The
syntax unit known as I<BLOCK> is a list of semi-colon terminated directives
held within curly braces.

=over 4

=item C<alias> I<large_path> => I<short_path>

Defines an alias to be used during tracing.  The I<large_path> string
is replaced by the I<short_path> in the logs.

For instance, given:

  alias "/home/dehaudtc/lib/CGI" => "<CGI>";

then a trace for file C</home/dehaudtc/lib/CGI/Carp.pm> would be
traced as coming from file C<E<lt>CGIE<gt>/Carp.pm>, which is nicer to read.

=item C<cluster> I<name1>, I<name2> I<BLOCK>

The I<BLOCK> defines the flags to be applied to all named clusters.
A cluster is a set of classes under a given name scope.
Cluster names are given by strings within double quotes, as in:

    cluster "CGI::MxScreen", "Net::MsgLink" { use silent; }

This would apply to all classes under the "CGI::MxScreen" or "Net::MsgLink"
name scopes, i.e. C<CGI::MxScreen::Screen> would be affected.

An exact match is attempted first, i.e. saying:

    cluster "CGI::MxScreen"         { use verbose; }
    cluster "CGI::MxScreen::Screen" { use silent; }

would apply the I<silent> flags for C<CGI::MxScreen::Screen> but the I<verbose>
ones to C<CGI::MxScreen::Tie::Stdout>.

=item C<default> I<name>|I<BLOCK>.

Specifies the default flags that should apply.  The default flags can be
given by providing the I<name> of flags, defined by the C<flags> directive,
or by expansing them in the following I<BLOCK>.

For instance:

    default silent;

would say that the flags to apply by default are the ones defined by an
earlier C<flags silent> directive.  Not expanding defaults allows for
quick switching by replacing I<silent> with I<verbose>.  It is up to the
module user to define what is meant by that though.

=item C<file> I<name1>, I<name2> I<BLOCK>

The I<BLOCK> defines the flags to be applied to all named files.
File names are given by strings withing double quotes, as in:

    file "foo.pm", "bar.pm" { use silent; }

This would apply to all files named "foo.pm" or "bar.pm", whatever their
directory, i.e. it would apply to C</tmp/foo.pm> as well as C<../bar.pm>.

An exact match is attempted first, i.e. saying:

    file "foo.pm"      { use verbose; }
    file "/tmp/foo.pm" { use silent; }

would apply the I<silent> flags for C</tmp/foo.pm> but the I<verbose>
ones to C<./foo.pm>.

=item C<flags> I<name> I<BLOCK>

Define a symbol I<name> whose flags are described by the following I<BLOCK>.
This I<name> can then be used in C<default> and C<use> directives.

For instance:

    flags common {
        all(yes);
        trace(yes): all;
    }

would define the flags known as I<common>, which can then be re-used, as in:

    flags other {
        use common;         # reuses definiton of common flags
        panic(no);          # but switches off panic, enabled in common
    }

A flag symbol must be defined prior being used.

=item C<routine> I<name1>, I<name2> I<BLOCK>

The I<BLOCK> defines the flags to be applied to all named routines.
Routine names are given by strings within double quotes, as in:

    routine "foo", "bar" { use silent; }

This would apply to all routines named "foo" or "bar", whatever their package,
for instance C<main::foo> and C<x::bar>.

=head2 Debugging and Tracing Flags

Debugging (and tracing) flags can be specified only within syntactic I<BLOCK>
items, as expected by main directives such as C<flags> or C<file>.

Following is a list of debugging flags that can be specified in the
configuration.  The order in which they are given in the file is significant:
the I<yes>/I<no> settings are applied sequentially.

=over 4

=item C<use> I<name>

Uses flags defined by a C<flags> directive under I<name>.  It acts as a
recursive macro expansion (since C<use> can also be specified in C<flags>).
The symbol I<name> must have been defined earlier.

=item flow(yes|no)

Whether to print out the entering/exiting of routines. That implies the
invocation of the C<DFEATURE> function in the routines.

=item return(yes|no)

Whether to print out the returned when using the return
C<DVAL> and C<DARY> routines.

=item trace(yes|no)

Whether to print out traces specified by the C<DTRACE> function. By 
default all trace levels are affected.  It may be followed by a list
of trace levels affected by the directive, as in.

    trace(yes): emergency, alert, critical;

Trace levels are purely conventional, and have a strict one-to-one mapping
with C<DTM_TRC_> levels given at the C<DTRACE> call.  They are further
described in L<Trace Levels> below.  There is one bit per defined trace
level, contrary to the convention established by syslog(), for better
tuning.

=item require(yes|no)

Whether to evaluate the pre-condition given by C<DREQUIRE>.  But see
L<Assertion Evaluation Note> below.

=item assert(yes|no)

Whether to evaluate the assertion given by C<DASSERT>.  But see
L<Assertion Evaluation Note> below.

=item ensure(yes|no)

Whether to evaluate the post-condition given by C<DENSURE>.  But see
L<Assertion Evaluation Note> below.

=item panic(yes|no)

Whether to panic upon an assertion failure (pre/post condition or 
assertion).  If not enabled, a simple warning is issued, tracing the
assertion failure.

=item stack(yes|no)

Whether to print out a stack trace upon assertion failure.

=item all(yes|no)

Enable or disables B<all> the previously described items.

=back

=head2 Assertion Evaluation Note

When C<Carp::Datum> is switched off, the assertions are always monitored,
and any failure is fatal.  This is because a failing assertion is a Bad Thing
in production mode. Also, since C<DREQUIRE> and friends are not
C macros but routines, the assertion expression is evaluated anyway, so
it might as well be tested.

Therefore, a directive like:

    require(no);

will only turn off monitoring of pre-conditions in debugging mode (e.g. because
the interface is not finalized, or the clients do not behave properly yet).

=head2 Trace Levels

Here is the list of trace flags that can be specified by the configuration:

    Configuration    DTRACE flag
    -------------    -------------
              all    TRC_ALL
        emergency    TRC_EMERGENCY
            alert    TRC_ALERT
         critical    TRC_CRITICAL
            error    TRC_ERROR
          warning    TRC_WARNING
           notice    TRC_NOTICE
             info    TRC_INFO
            debug    TRC_DEBUG

A user could say something like:

    trace(no): all;
    trace(yes): emergency, alert, critical, error;

Since flags are applied in sequence, the first directive turns all tracing
flags to off, the second enables only the listed ones.

=head1 BUGS

Some things are not fully documented.

=head1 AUTHORS

Christophe Dehaudt and Raphael Manfredi are the original authors.

Send bug reports, hints, tips, suggestions to Dave Hoover at <squirrel@cpan.org>.

=head1 SEE ALSO

Log::Agent(3).

=cut


