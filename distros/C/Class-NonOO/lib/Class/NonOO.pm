package Class::NonOO;

# ABSTRACT: Use methods as functions with an implicit singleton

use v5.10.1;

use strict;
use warnings;

use Exporter qw/ import /;
use List::MoreUtils qw/ uniq /;
use Package::Stash;
use Scalar::Util qw/ blessed /;

{
    use version;
    $Class::NonOO::VERSION = version->declare('v0.4.1');
}

# RECOMMEND PREREQ: Package::Stash::XS 0

=head1 NAME

Class::NonOO - Use methods as functions with an implicit singleton

=for readme plugin version

=head1 SYNOPSYS

In a module:

  package MyModule;

  use Class::NonOO;

  ...

  sub my_method {
     my ($self, @args) = @_;
     ...
  }

  as_function
    export => [ 'my_method' ], # methods to export
    args   => [ ];             # constructor args

The module can be be used with a function calling style:

  use MyModule;

  ...

  my_method(@args);

=begin :readme

=head1 INSTALLATION

See
L<How to install CPAN modules|http://www.cpan.org/modules/INSTALL.html>.

=for readme plugin requires heading-level=2 title="Required Modules"

=for readme plugin changes

=end :readme

=head1 DESCRIPTION

This module allows you to turn a class into a module that exports
methods as functions that use an implicit singleton.  This allows you
to provide a "hybrid" object-oriented/functional interface.

=head1 EXPORTS

=cut

our @EXPORT = qw/ as_function _Class_NonOO_instance /;

sub _Class_NonOO_instance {
    my $class = shift;
    my $user  = shift;
    state $symbol = '%_DEFAULT_SINGLETONS';
    my $stash = Package::Stash->new($class);
    my $instances = $stash->get_or_add_symbol($symbol);
    return $instances->{$user} //= $class->new(@_);
}

=head2 C<as_function>

  as_function
    export      => [ ... ], # @EXPORT
    export_ok   => [ ... ], # @EXPORT_OK (optional)
    export_tags => { ... }, # %EXPORT_TAGS (optional)
    args        => [ ... ], # constructor args (optional)
    global      => 0;       # no global state (default)

This wraps methods in a function that checks the first argument. If
the argument is an instance of the class, then it assumes it is a
normal method call.  Otherwise it assumes it is a function call, and
it calls the method with the singleton instance.

If the C<export> option is omitted, it will default to the contents of
the C<@EXPORT> variable. The same holds for the C<export_ok> and
C<export_tags> options and the C<@EXPORT_OK> and C<%EXPORT_TAGS>
variables, respectively.

Note that this will not work properly on methods that take an instance
of the class as the first argument.

By default, there is no global state. That means that there is a
different implicit singleton for each namespace.  This offers some
protection when the state is changed in one module, so that it does
not affect the state in another module.

If you want to enable global state, you can set C<global> to a true
value.  This is not recommended for CPAN modules.

You might work around this by using something like

  local %MyClass::_DEFAULT_SINGLETONS;

but this is not recommended.  If you need to modify state and share it
across modules, you should be passing around individual objects
instead of singletons.

=cut

sub as_function {
    my %opts = @_;

    my ($caller) = caller;
    my $stash = Package::Stash->new($caller);

    my $export      = $stash->get_or_add_symbol('@EXPORT');
    my $export_ok   = $stash->get_or_add_symbol('@EXPORT_OK');
    my $export_tags = $stash->get_or_add_symbol('%EXPORT_TAGS');

    my $global      = $opts{global} // 0;
    my @args        = @{ $opts{args}        // [] };
    my @export      = @{ $opts{export}      // $export };
    my @export_ok   = @{ $opts{export_ok}   // $export_ok };
    my %export_tags = %{ $opts{export_tags} // $export_tags };

    my %in_export_ok = map { $_ => 1 } @{$export_ok};

    foreach
      my $name ( uniq @export, @export_ok, map { @$_ } values %export_tags )
    {

        $stash->add_symbol( '&import', \&Exporter::import );

        my $symbol = '&' . $name;
        if ( my $method = $stash->get_symbol($symbol) ) {

            my $new = sub {
                if ( blessed( $_[0] ) && $_[0]->isa($caller) ) {
                    return $method->(@_);
                }
                else {
                    my $user = $global ? 'default' : caller;
                    my $self = $caller->_Class_NonOO_instance( $user, @args );
                    return $self->$method(@_);
                }
            };
            $stash->add_symbol( $symbol, $new );

            push @{$export_ok}, $name unless $in_export_ok{$name};
        }
        else {
            die "No method named ${name}";
        }
    }

    push @{$export}, $_ for @export;

    $export_tags->{all} = $export_ok;
}


=head1 SEE ALSO

L<Class::Exporter> is a similar module.

=head1 AUTHOR

Robert Rothenberg, C<< <rrwo at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2016 Robert Rothenberg.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=for readme stop

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=for readme continue

=cut

1;
