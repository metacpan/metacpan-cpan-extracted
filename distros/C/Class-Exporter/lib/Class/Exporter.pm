package Class::Exporter;

=head1 NAME

Class::Exporter - Export class methods as regular subroutines

=head1 SYNOPSIS

  package MagicNumber;
  use base 'Class::Exporter';

  # Export object-oriented methods!
  @EXPORT_OK       = qw(magic_number);

  sub new {
    my $class = shift;
    bless { magic_number=>3, @_ }, $class
  }
    
  sub magic_number {
    my $self = shift;
    @_ and $self->{magic_number} = shift;
    $self->{magic_number}
  }

  # Meanwhile, in another piece of code!
  package Bar;
  use MagicNumber;  # exports magic_number
  print magic_number; # prints 3
  magic_number(7);
  print magic_number; # prints 7
  
  # Each package gets its own instance of the object. This ensures that
  # two packages both using your module via import semantics don't mess
  # with each other.
  
  package Baz;
  use MagicNumber; # exports magic_number
  print magic_number; # prints 3 because this package has a different 
                      # MagicNumber object than package Bar.
  
=head1 DESCRIPTION

This module makes it much easier to make a module have a hybrid object/method 
interface similar to the one of CGI.pm. You can take any old module that has 
an object- oriented interface and convert it to have a hybrid interface by 
simply adding "use base 'Class::Exporter'" to your code.

This package allows you to export object methods. It supports C<import()>, 
C<@EXPORT> and C<@EXPORT_OK> and not a whole lot else. Each package into 
which your object methods are imported gets its own instance of the object. 
This ensures that there are no interaction effects between multiple packages 
that use your object.

Setting up a module to export its variables and functions is simple:

    package My::Module;
    use base 'Class::Exporter';

    @EXPORT = qw($Foo bar);

now when you C<use My::Module>, C<$Foo> and C<bar()> will show up.

In order to make exporting optional, use @EXPORT_OK.

    package My::Module;
    use base 'Class::Exporter';

    @EXPORT_OK = qw($Foo bar);

when My::Module is used, C<$Foo> and C<bar()> will I<not> show up.
You have to ask for them.  C<use My::Module qw($Foo bar)>.

=head1 Methods

Class::Exporter has one public method, import(), which is called
automatically when your modules is use()'d.  

In normal usage you don't have to worry about this at all.

=over 4

=item B<import>

  Some::Module->import;
  Some::Module->import(@symbols);

Works just like C<Exporter::import()> excepting it only honors
@Some::Module::EXPORT and @Some::Module::EXPORT_OK.

The given @symbols are exported to the current package provided they
are in @Some::Module::EXPORT or @Some::Module::EXPORT_OK.  Otherwise
an exception is thrown (ie. the program dies).

If @symbols is not given, everything in @Some::Module::EXPORT is
exported.

=back

=head1 DIAGNOSTICS

=over 4

=item '"%s" is not exported by the %s module'

Attempted to import a symbol which is not in @EXPORT or @EXPORT_OK.

=item 'Can\'t export symbol: %s'

Attempted to import a symbol of an unknown type (ie. the leading $@% salad
wasn't recognized).

=back

=head1 AUTHORS

David James <david@jamesgang.com>

Most of the code and documentation was borrowed from Exporter::Lite.
Exporter::Lite was written by Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Exporter>, L<Exporter::Lite>, L<UNIVERSAL::exports>

=head1 LICENSE

  Copyright (c) 2002 David James
  All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
  
=cut

require 5.005;

$VERSION = 0.03;
@EXPORT = ();
@EXPORT_OK = ();
use strict 'vars';  # we're going to be doing a lot of sym refs

sub import {
    my($exporter, @imports)  = @_;
    my($caller, $file, $line) = caller;

    unless( @imports ) {        # Default import.
        @imports = @{$exporter.'::EXPORT'};
    } else {
        # If exporting module has an EXPORT_OK array, then exports are
        # limited to its contents.
        if( *{$exporter.'::EXPORT_OK'}{ARRAY} ) {
            if( @{$exporter.'::EXPORT_OK'} ) {
                # This can also be cached.
                my %ok = map { s/^&//; $_ => 1 } @{$exporter.'::EXPORT_OK'},
                                                 @{$exporter.'::EXPORT'};
            
                my($denied) = grep {s/^&//; !$ok{$_}} @imports;
                _not_exported($denied, $exporter, $file, $line) if $denied;
            } else {      # We don't export anything.
                _not_exported($imports[0], $exporter, $file, $line);
            }
        }
    }

    @imports and _export($caller, $exporter, @imports);
}


sub _export {
    my($caller, $exporter, @imports) = @_;

    $exporter->can("new") or do {
        require Carp;
        Carp::croak(
            "Class must have 'new' method in order to export class methods"
        );
    };  

    # Declare an individual instance for each module that uses us.
    my $instance = $exporter->new(exports=>[\@imports]);

    # Stole this from Exporter::Heavy.  I'm sure it can be written better
    # but I'm lazy at the moment.
    foreach my $sym (@imports) {
        my $type = "&";
        $sym =~ s/^(\W)// and $type = $1;

        my $export_sym = $exporter.'::'.$sym;
        *{$caller.'::'.$sym} =
            $type eq '&' ? sub { $instance->$sym(@_) } :
            $type eq '$' ? \${$export_sym} :
            $type eq '@' ? \@{$export_sym} :
            $type eq '%' ? \%{$export_sym} :
            $type eq '*' ?  *{$export_sym} :
            do { require Carp; Carp::croak("Can't export symbol: $type$sym") };
    }
}

sub _not_exported {
    my($thing, $exporter, $file, $line) = @_;
    die sprintf qq|"%s" is not exported by the %s module at %s line %d\n|,
        $thing, $exporter, $file, $line;
}

1;

