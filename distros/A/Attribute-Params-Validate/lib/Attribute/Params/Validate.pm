package Attribute::Params::Validate;

use strict;
use warnings;

our $VERSION = '1.21';

use attributes;

use Attribute::Handlers 0.79;
use Exporter 5.60 qw( import );

# this will all be re-exported
use Params::Validate 1.21 qw(:all);

my %tags = (
    types => [
        qw( SCALAR ARRAYREF HASHREF CODEREF GLOB GLOBREF SCALARREF HANDLE UNDEF OBJECT )
    ],
);

our %EXPORT_TAGS = (
    'all' => [ qw( validation_options ), map { @{ $tags{$_} } } keys %tags ],
    %tags,
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} }, 'validation_options' );

sub UNIVERSAL::Validate : ATTR(CODE, INIT) {
    _wrap_sub( 'named', @_ );
}

sub UNIVERSAL::ValidatePos : ATTR(CODE, INIT) {
    _wrap_sub( 'positional', @_ );
}

## no critic (Subroutines::ProhibitManyArgs))
sub _wrap_sub {
    my ( $type, $package, $symbol, $referent, $attr, $params ) = @_;

    my @p = ref $params ? @{$params} : $params;

    my $subname = $package . '::' . *{$symbol}{NAME};

    my %attributes = map { $_ => 1 } attributes::get($referent);
    my $is_method = $attributes{method};

    {
        ## no critic (TestingAndDebugging::ProhibitNoStrict, TestingAndDebugging::ProhibitProlongedStrictureOverride)
        no warnings 'redefine';
        no strict 'refs';

        # An unholy mixture of closure and eval.  This is done so that
        # the code to automatically create the relevant scalars from
        # the hash of params can create the scalars in the proper
        # place lexically.

        my $code = <<"EOF";
sub
{
    package $package;
EOF

        $code .= "    my \$object = shift;\n" if $is_method;

        if ( $type eq 'named' ) {
            $params = {@p};
            $code .= "    Params::Validate::validate(\@_, \$params);\n";
        }
        else {
            $code .= "    Params::Validate::validate_pos(\@_, \@p);\n";
        }

        $code .= "    unshift \@_, \$object if \$object;\n" if $is_method;

        $code .= <<"EOF";
    \$referent->(\@_);
}
EOF

        ## no critic (BuiltinFunctions::ProhibitStringyEval)
        my $sub = eval $code;
        die $@ if $@;

        *{$subname} = $sub;
    }
}
## use critic

1;

# ABSTRACT: Define validation through subroutine attributes

__END__

=pod

=head1 NAME

Attribute::Params::Validate - Define validation through subroutine attributes

=head1 VERSION

version 1.21

=head1 SYNOPSIS

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

=head1 DESCRIPTION

B<This module is currently unmaintained. I do not recommend using it. It is a
failed experiment. If you would like to take over maintenance of this module,
please contact me at autarch@urth.org.>

The Attribute::Params::Validate module allows you to validate method
or function call parameters just like Params::Validate does.  However,
this module allows you to specify your validation spec as an
attribute, rather than by calling the C<validate> routine.

Please see Params::Validate for more information on how you can
specify what validation is performed.

=head2 EXPORT

This module exports everything that Params::Validate does except for
the C<validate> and C<validate_pos> subroutines.

=head2 ATTRIBUTES

=over 4

=item * Validate

This attribute corresponds to the C<validate> subroutine in
Params::Validate.

=item * ValidatePos

This attribute corresponds to the C<validate_pos> subroutine in
Params::Validate.

=back

=head2 OO

If you are using this module to mark B<methods> for validation, as
opposed to subroutines, it is crucial that you mark these methods with
the C<:method> attribute, as well as the C<Validate> or C<ValidatePos>
attribute.

If you do not do this, then the object or class used in the method
call will be passed to the validation routines, which is probably not
what you want.

=head2 CAVEATS

You B<must> put all the arguments to the C<Validate> or C<ValidatePos>
attribute on a single line, or Perl will complain.

=head1 SUPPORT

Please submit bugs and patches to the CPAN RT system at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Attribute%3A%3AParams%3A%3AValidate
or via email at bug-params-validate@rt.cpan.org.

=head1 SEE ALSO

Params::Validate

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
