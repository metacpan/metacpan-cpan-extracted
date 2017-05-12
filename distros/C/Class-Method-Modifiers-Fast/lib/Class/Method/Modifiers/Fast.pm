package Class::Method::Modifiers::Fast;
use strict;
use warnings;
use Data::Util;
our $VERSION = '0.041';

use base 'Exporter';
our @EXPORT      = qw(before after around);
our @EXPORT_OK   = (@EXPORT, 'install_modifier');
our %EXPORT_TAGS = (
    moose => [qw(before after around)],
    all   => \@EXPORT_OK,
);

use Carp 'confess';

sub _install_modifier; # -w
*_install_modifier = \&install_modifier;

sub install_modifier {
    my $into     = shift;
    my $type     = shift;
    my $modifier = pop;
    my @names    = @_;

    foreach my $name (@names) {
        my $method = Data::Util::get_code_ref( $into, $name );

        if ( !$method || !Data::Util::subroutine_modifier($method) ) {

            unless ($method) {
                $method = $into->can($name)
                    or confess
                    "The method '$name' is not found in the inheritance hierarchy for class $into";
            }
            $method = Data::Util::modify_subroutine( $method,
                $type => [$modifier] );

            no warnings 'redefine';
            Data::Util::install_subroutine( $into, $name => $method );
        }
        else {
            Data::Util::subroutine_modifier( $method, $type => $modifier );
        }
    }
    return;
}

sub before {
    _install_modifier( scalar(caller), 'before', @_ );
}

sub after {
    _install_modifier( scalar(caller), 'after', @_ );
}

sub around {
    _install_modifier( scalar(caller), 'around', @_ );
}

1;

__END__

=head1 NAME

Class::Method::Modifiers::Fast - provides Moose-like method modifiers

=head1 SYNOPSIS

    package Child;
    use parent 'Parent';
    use Class::Method::Modifiers::Fast;

    sub new_method { }

    before 'old_method' => sub {
        carp "old_method is deprecated, use new_method";
    };

    around 'other_method' => sub {
        my $orig = shift;
        my $ret = $orig->(@_);
        return $ret =~ /\d/ ? $ret : lc $ret;
    };

=head1 DESCRIPTION

Method modifiers are a powerful feature from the CLOS (Common Lisp Object
System) world.

C<Class::Method::Modifiers::Fast> provides three modifiers: C<before>, C<around>, 
and C<after>. C<before> and C<after> are run just before and after the method they
modify, but can not really affect that original method. C<around> is run in
place of the original method, with a hook to easily call that original method.
See the C<MODIFIERS> section for more details on how the particular modifiers
work.

=head1 MODIFIERS

=head2 before method(s) => sub { ... }

C<before> is called before the method it is modifying. Its return value is
totally ignored. It receives the same C<@_> as the the method it is modifying
would have received. You can modify the C<@_> the original method will receive
by changing C<$_[0]> and friends (or by changing anything inside a reference).
This is a feature!

=head2 after method(s) => sub { ... }

C<after> is called after the method it is modifying. Its return value is
totally ignored. It receives the same C<@_> as the the method it is modifying
received, mostly. The original method can modify C<@_> (such as by changing
C<$_[0]> or references) and C<after> will see the modified version. If you
don't like this behavior, specify both a C<before> and C<after>, and copy the
C<@_> during C<before> for C<after> to use.

=head2 around method(s) => sub { ... }

C<around> is called instead of the method it is modifying. The method you're
overriding is passed in as the first argument (called C<$orig> by convention).
Watch out for contextual return values of C<$orig>.

You can use C<around> to:

=over 4

=item Pass C<$orig> a different C<@_>

    around 'method' => sub {
        my $orig = shift;
        my $self = shift;
        $orig->($self, reverse @_);
    };

=item Munge the return value of C<$orig>

    around 'method' => sub {
        my $orig = shift;
        ucfirst $orig->(@_);
    };

=item Avoid calling C<$orig> -- conditionally

    around 'method' => sub {
        my $orig = shift;
        return $orig->(@_) if time() % 2;
        return "no dice, captain";
    };

=back

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>
gfx

=head1 SEE ALSO

L<Class::Method::Modifiers>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
