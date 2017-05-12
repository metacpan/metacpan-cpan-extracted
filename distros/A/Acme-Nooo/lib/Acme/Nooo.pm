package Acme::Nooo;

our $VERSION = '0.02';

sub import
{
    my $nooo = shift;
    my ($class, @stubs) = @_;
    my $obj;
    if (ref $class eq 'ARRAY') {
        my @args;
        ($class, @args) = @$class;
        eval "use $class";
        $obj = new $class @args;
    } elsif (!ref $class) {
        eval "use $class";
        $obj = new $class;
    } else {
        $obj = $class;
    }
    my $pack = caller;
    # my $obj = ($nooo eq 'Acme::Nooo') ? new $class @_ : $class;
    @stubs = keys %{"$class\::"} unless @stubs;
    for (@stubs) {
        if (UNIVERSAL::can($obj, $_)) {
            my $subname = $_;
            *{"$pack\::$subname"} = sub { $obj->$subname(@_); };
        }
    }
    ## A bit too evil
    # eval {
    #     for (keys %$obj) {
    #         ${"$class\::$_"} = $obj->{$_};
    #     }
    # };
}

# our %AUTO;

# sub autoload
# {
#     $AUTOLOAD =~ s/.*:://;
#     my $pack = caller;
#     for (@{$AUTO{$pack}}) {
#         if (UNIVERSAL::can($_, $AUTOLOAD)) {
#             return $_->$AUTOLOAD(@_);
#         }
#     }
#     die "$AUTOLOAD: Nooooo can do...";
# }

# sub import
# {
#     shift;
#     my $obj = shift;
#     my $pack = caller;
#     *{"$pack\::AUTOLOAD"} = \&autoload
#         unless \&{"$pack\::AUTOLOAD"} eq \&autoload;
#     push @{$AUTO{$pack}}, $obj;
# }

1;

__END__

=head1 NAME

Acme::Nooo - But I don't B<care> if "It Has Objects"!

=head1 SYNOPSIS

  ## Before:
  use SquareRoutEr;
  my $obj = SquareRoutEr->new;
  $obj->sqrt(4); # => 2

  ## After:
  use Acme::Nooo 'SquareRoutEr';
  sqrt(4); # => 2

  ## Before:
  use AnyRoutEr;
  $obj = AnyRoutEr->new(pow => 3);
  $obj->root(8); # => 2

  ## After:
  use Acme::Nooo ['AnyRoutEr', 'pow', 3];
  root(8); # => 2

=head1 DESCRIPTION

Tired of "object-fetishist" modules that force you to create a handle
object when a simple procedural interface would have been sufficient?
C<Acme::Nooo> will import functions into the current namespace to
de-objectify abominable interfaces.

  use Acme::Nooo MODULE;

or

  use Acme::Nooo [MODULE NEW-ARGS];

exports all functions in Module as methods on an object or class
created via

  use MODULE;
  $obj = new MODULE NEW-ARGS...

For finer-grained control,

  use Acme::Nooo [MODULE NEW-ARGS], NAMES

exports only the functions named in C<NAMES>.

=head1 EXPORT

It depends.  C<Acme::Nooo> exports other modules' functions.

=head1 SEE ALSO

Names withheld to protect the innocent.

=head1 AUTHOR

Sean O'Rourke, E<lt>seano@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Sean O'Rourke.  All rights reserved, some wrongs
reversed.  This module is distributed under the same terms as Perl
itself.  Let me know if you actually find it useful.

=cut
