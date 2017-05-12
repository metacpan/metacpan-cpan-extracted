NAME

    Attribute::Params::Validate - Define validation through subroutine
    attributes

VERSION

    version 1.21

SYNOPSIS

      use Attribute::Params::Validate qw(:all);
    
      # takes named params (hash or hashref)
      # foo is mandatory, bar is optional
      sub foo : Validate( foo => 1, bar => 0 )
      {
          # insert code here
      }
    
      # takes positional params
      # first two are mandatory, third is optional
      sub bar : ValidatePos( 1, 1, 0 )
      {
          # insert code here
      }
    
      # for some reason Perl insists that the entire attribute be on one line
      sub foo2 : Validate( foo => { type => ARRAYREF }, bar => { can => [ 'print', 'flush', 'frobnicate' ] }, baz => { type => SCALAR, callbacks => { 'numbers only' => sub { shift() =~ /^\d+$/ }, 'less than 90' => sub { shift() < 90 } } } )
      {
          # insert code here
      }
    
      # note that this is marked as a method.  This is very important!
      sub baz : Validate( foo => { type => ARRAYREF }, bar => { isa => 'Frobnicator' } ) method
      {
          # insert code here
      }

DESCRIPTION

    This module is currently unmaintained. I do not recommend using it. It
    is a failed experiment. If you would like to take over maintenance of
    this module, please contact me at autarch@urth.org.

    The Attribute::Params::Validate module allows you to validate method or
    function call parameters just like Params::Validate does. However, this
    module allows you to specify your validation spec as an attribute,
    rather than by calling the validate routine.

    Please see Params::Validate for more information on how you can specify
    what validation is performed.

 EXPORT

    This module exports everything that Params::Validate does except for
    the validate and validate_pos subroutines.

 ATTRIBUTES

      * Validate

      This attribute corresponds to the validate subroutine in
      Params::Validate.

      * ValidatePos

      This attribute corresponds to the validate_pos subroutine in
      Params::Validate.

 OO

    If you are using this module to mark methods for validation, as opposed
    to subroutines, it is crucial that you mark these methods with the
    :method attribute, as well as the Validate or ValidatePos attribute.

    If you do not do this, then the object or class used in the method call
    will be passed to the validation routines, which is probably not what
    you want.

 CAVEATS

    You must put all the arguments to the Validate or ValidatePos attribute
    on a single line, or Perl will complain.

SUPPORT

    Please submit bugs and patches to the CPAN RT system at
    http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Attribute%3A%3AParams%3A%3AValidate
    or via email at bug-params-validate@rt.cpan.org.

SEE ALSO

    Params::Validate

AUTHOR

    Dave Rolsky <autarch@urth.org>

COPYRIGHT AND LICENSE

    This software is Copyright (c) 2015 by Dave Rolsky.

    This is free software, licensed under:

      The Artistic License 2.0 (GPL Compatible)

