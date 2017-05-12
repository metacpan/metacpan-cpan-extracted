package Benchmark::Harness::Values;
use base qw(Benchmark::Harness::Trace);
use strict;
use vars qw($VERSION); $VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);


=pod

=head1 Benchmark::Harness::Values

=head2 SYNOPSIS

A harness that records the input parameters and return values of each
function in the target program.

See Benchmark::Harness, "Parameters", for instruction on how to configure
a test harness, and use 'Values' as your harness name.

=head2 REPORT

The report is an XML file with schema you can find in xsd/Values.xsd,
or at http://schemas.benchmark-harness.org/Values.xsd

This schema adds a list of <V> sub-elements to each <T> element you would
find in the basic Trace.xsd. An illustration of that <V> element:

  <T some-trace-attributes-see-Trace.xsd>
    <V n="1" v="15"/>
    <V n="2" v="3"/>
    <V n="3" v="4"/>
    <V n="0" v="22"/>
  </T>

The @n attribute is the index into the function's input parameter list.
If @n="0", this is the return value of the function.
The @v attribute is the value you would get by the expression "$_[@n]",
i.e., the stringified value of the @n-th parameter.

=head2 GETTING MORE

The reporting mechanism uses the Stringify method to generate the @v attribute.
You can control what gets printed here when rendering objects (i.e., bless refs)
with this simple but powerful gimmick.

Add the following to the module that defines your parameter(s)' object(s):

  package MyClass;
  use overload '""' => \&stringify;
  sub stringify {
      my $self = shift;
      return 'MyClass::'.$self->{some_meaningful_value};
  }

Put your own specialized code in stringify() to render your MyClass
objects in whatever form you would rather see them.
Otherwise you will see something like "MyClass::HASH{0x1bf2cd8}";

=head2 SEE ALSO

L<Benchmark::Harness|Benchmark::Harness>, L<Benchmark::Harness::Trace|Benchmark::Harness::Trace>

=cut

### ###########################################################################
### ###########################################################################
### ###########################################################################
package Benchmark::Harness::Handler::Values;
use base qw(Benchmark::Harness::Handler::Trace);
use Benchmark::Harness::Constants;

### ###########################################################################
#sub reportTraceInfo {
#    return Benchmark::Harness::Handler::Trace::reportTraceInfo(@_);
#}

### ###########################################################################
#sub reportValueInfo {
#    return Benchmark::Harness::Handler::Trace::reportValueInfo(@_);
#}

### ###########################################################################
# USAGE: Benchmark::Trace::MethodArguments('class::method', [, 'class::method' ] )
sub OnSubEntry {
  my $self = shift;
  my $origMethod = shift;

  my $i=1;
  for ( @_ ) {
    $self->NamedObjects($i, $_) if defined $_;
    last if ( $i++ == 20 );
  }
  if ( scalar(@_) > 20 ) {
    #$self->print("<G n='".scalar(@_)."'/>");
  };
  $self->reportTraceInfo();#(shift, caller(1));
  return @_; # return the input arguments unchanged.
}

### ###########################################################################
# USAGE: Benchmark::Trace::MethodReturn('class::method', [, 'class::method' ] )
sub OnSubExit {
  my $self = shift;
  my $origMethod = shift;

  if (wantarray) {
    my $i=1;
    for ( @_ ) {
      $self->NamedObjects($i, $_) if defined $_;
      last if ( $i++ == 20 );
    }
    if ( scalar(@_) > 20 ) {
      #$self->print("<G n='".scalar(@_)."'/>");
    };
  } else {
    scalar $self->NamedObjects('0', $_[0]) if defined $_[0];
    return $_[0];
  }
  return @_;
}

### ###########################################################################

=head1 AUTHOR

Glenn Wood, <glennwood@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2004 Glenn Wood. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;