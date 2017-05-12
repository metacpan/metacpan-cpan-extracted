use 5.006;
use strict;
use warnings;

package Call::From;

our $VERSION   = '0.001000';
our $AUTHORITY = 'cpan:KENTNL';

use Exporter qw();
*import = \&Exporter::import;

our @EXPORT_OK = qw( call_method_from call_function_from $_call_from );

our $_call_from = sub {
    $_[0]->${ \call_method_from( [ _to_caller( $_[1] ) ] ) }( @_[ 2 .. $#_ ] );
};

sub _to_caller {
    my ( $ctx, $offset ) = @_;

    # +1 because this function is internal, and we dont
    # want Call::From
    $offset = 1 unless defined $offset;

    # Numeric special case first because caller is different
    if ( defined $ctx and not ref $ctx and $ctx =~ /^-?\d+$/ ) {

        my (@call) = caller( $ctx + $offset );
        return @call[ 0 .. 2 ];
    }

    my (@call) = caller($offset);

    # _to_caller() returns the calling context of call_method_from
    return @call[ 0 .. 2 ] if not defined $ctx;

    # _to_caller($name) as with (), but with <package> replaced.
    return ( $ctx, $call[1], $call[2] ) if not ref $ctx;

    # _to_caller([ pkg, (file,( line)) ]) fills the fields that are missing
    return (
        $ctx->[0] || $call[0],    # pkg
        $ctx->[1] || $call[1],    # file
        $ctx->[2] || $call[2],    # line
    );

}

sub _to_fun {
    return $_[0] if 'CODE' eq ref $_[0];

    if ( defined $_[0]
        and my ( $package, $function ) = $_[0] =~ /\A(.*?)::([^:]+)\z/ )
    {
        # q[::Foo]->can() is invalid before 5.18
        # so map it to q[main::Foo]
        $package = 'main' if not defined $package or not length $package;
        if ( my $sub = "$package"->can($function) ) {
            return $sub;
        }
        die "Can't resolve function <$function> in package <$package>";
    }
    my $arg = defined $_[0] ? qq["$_[0]"] : q[undef];
    die "Can't automatically determine package and function from $arg";
}

sub _gen_sub {
    my ( $package, $file, $line, $code ) = @_;
    my $sub_code =
        qq[package $package;\n]
      . qq[#line $line "$file"\n] . 'sub {'
      . $code . '};';
    local $@ = undef;
    my $sub = eval $sub_code;
    $@ or return $sub;
    die "Can't compile trampoline for $package: $@\n code => $sub_code";
}

my $method_trampoline_cache   = {};
my $function_trampoline_cache = {};

sub call_method_from {
    my @caller = _to_caller( $_[0] );
    return ( $method_trampoline_cache->{ join qq[\0], @caller } ||=
          _gen_sub( @caller, q[ $_[0]->${\$_[1]}( @_[2..$#_ ] ) ] ) );
}

sub call_function_from {
    my @caller = _to_caller( $_[0] );
    return (
        $function_trampoline_cache->{ join qq[\0], @caller } ||= _gen_sub(
            @caller, __PACKAGE__ . q[::_to_fun($_[0])->( @_[1..$#_ ] ) ],
        )
    );
}

1;

__END__

=head1 NAME

Call::From - Call functions/methods with a fake caller()

=head1 SYNOPSIS

  use Call::From qw( call_method_from );

  my $proxy = call_method_from('Fake::Namespace');

  Some::Class->$proxy( method_name => @args ); # Some::Class->method_name( @args ) with caller() faked.

=head1 DESCRIPTION

Call::From contains a collection of short utility functions to ease calling
functions and methods from faked calling contexts without requiring arcane
knowledge of Perl eval tricks.

=head1 EXPORTS

The following functions and variables are exportable on request.

=head2 C<call_method_from>

  my $function = call_method_from( CONTEXT_SPEC );
  $invocant->$function( method_name => @args );

Alternatively:

  $invocant->${ \call_method_from( CONTEXT_SPEC ) }( method_name => @args );

=head2 C<call_function_from>

  my $function = call_function_from( CONTEXT_SPEC );
  $function->( "Class::Name::function" , @args );

Alternatively:

  my $function = call_function_from( CONTEXT_SPEC );
  $function->( Class::Name->can('function') , @args );

Or

  call_function_from( CONTEXT_SPEC )->( "Class::Name::function", @args );

=head2 C<$_call_from>

  $invocant->$_call_from( CONTEXT_SPEC, method_name => @args );

=head1 SPECIFYING A CALLING CONTEXT

Calling contexts can be specified in a number of ways.

=head2 Numeric Call Levels

In functions like C<import>, you're most likely wanting to chain caller
meta-data from whoever is calling C<import>

So for instance:

  package Bar;
  sub import {
    my $proxy = call_method_from(1);
    vars->$proxy( import => 'world');
  }
  package Foo;
  Bar->import();

Would trick `vars` to seeing `Foo` as being the calling C<package>, with the line
of the C<< Bar->import() >> call being the C<file> and C<line> of the apparent
caller in C<vars::import>

This syntax is essentially shorthand for

  call_method_from([ caller(1) ])

=head2 Package Name Caller

Strings describing the name of the calling package allows you to conveniently
call functions from arbitrary name-spaces for C<import> reasons, while
preserving the C<file> and C<line> context in C<Carp> stack traces.

  package Bar;
  sub import {
    vars->${\call_method_from('Quux')}( import => 'world');
  }
  package Foo;
  Bar->import();

This example would call C<< vars->import('world') >> from inside the C<Quux>
package, while C<file> and C<line> data would still indicate an origin inside
C<Bar> ( on the line that C<call_method_from> was called on )

This syntax is essentially shorthand for:

  call_method_from([ $package, __FILE__, __LINE__ ])

=head2 ArrayRef of Caller Info

Array References in the form

  [ $package, $file, $line ]

Can be passed as a C<CALLING CONTEXT>. All fields are optional and will be
supplemented with the contents of the calling context when missing.

Subsequently:

  call_method_from([])
    == call_method_from()
    == call_method_from([__PACKAGE__, __FILE__, __LINE__])

  call_method_from(['Package'])
    == call_method_from('Package')
    == call_method_from(['Package', __FILE__, __LINE__])

  call_method_from(['Package','file'])
    == call_method_from(['Package','file', __LINE__])

=head1 SEE ALSO

The following modules are similar in some way to C<Call::From>

=over 4

=item * L<< C<Import::Into>|Import::Into >>

C<Import::Into> is really inspiration that this module borrowed from. It contains the elegant
trick of using C<eval> to compile a kind of C<trampoline> or L<< C<thunk>|https://en.wikipedia.org/wiki/Thunk >>
which contained the magical C<eval> spice that allows this behavior to work.

As such, this module had a big help from the authors and maintainers of C<Import::Into> in mimicking
and generalizing its utility in contexts other than C<import>

If C<Import::Into> did not exist, you could use this module in its place:

    require Module;
    Module->${\call_method_from( $Into_Package )}( import => @IMPORT_ARGS );

However, it does exist, and should you need such a functionality, it is recommended instead of this module.

=item * L<< C<Scope::Upper>|Scope::Upper >>

This module is similar to C<Scope::Upper> in that it can be used to "hide" who C<caller> is from
a calling context.

However, C<Scope::Upper> is more fancy, and uses Perl Guts in order to be able to actually hide
the entire stack frame, regardless of how many frames up you look with C<caller($N_FRAME)>.

C<Call::From> is much simpler in that it can only I<add> stack frames to the caller, and then,
it adds redundant frames in performing its task.

This is sufficient for fooling something that only uses a simple C<caller()> call, but is insufficient
if you need to hide entire call chains. In fact, I personally see it as a feature that you can still see
the true caller history in a full stack-trace, because the last place you want to be fooled is when you're debugging
whether or not you've been fooled.

But its worth pointing out that at the time of this writing, changes are pending in Perl 5 to L<< rework the entire
stack system|http://www.nntp.perl.org/group/perl.perl5.porters/2016/01/msg233631.html >>.

This change L<< may break C<Scope::Upper>|http://www.nntp.perl.org/group/perl.perl5.porters/2016/01/msg233633.html >>
in ways that might not be fixable.

In the event this happens, C<Call::From> might be a suitable alternative if you only need to spoof a stack frame
and don't care that the full stack is still there.

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
