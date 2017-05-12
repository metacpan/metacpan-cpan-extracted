package B::Tap;
use 5.014000;
use strict;
use warnings;

our $VERSION = "0.15";

use parent qw(Exporter);

our @EXPORT = qw(tap);
our @EXPORT_OK = qw(G_ARRAY G_VOID G_SCALAR);
our %EXPORT_TAGS = (
    'all' => [@EXPORT, @EXPORT_OK],
);

use Carp ();

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub tap {
    my ($op, $root_op, $buf) = @_;
    Carp::croak("Third argument should be ArrayRef") unless ref $buf eq 'ARRAY';
    _tap($$op, $$root_op, $buf);
}

# tweaks for custom ops.
{
    sub B::Deparse::pp_b_tap_tap {
        my ($self, $op) = @_;
        $self->deparse($op->first);
    };
    sub B::Deparse::pp_b_tap_push_sv {
        '';
    }
}

1;
__END__

=for stopwords optree newbie deparse deparsing

=encoding utf-8

=head1 NAME

B::Tap - Inject tapping node to optree

=head1 SYNOPSIS

    use B;
    use B::Tap;
    use B::Tools;

    sub foo { 63 }

    my $code = sub { foo() + 5900 };
    my $cv = B::svref_2object($code);

    my ($entersub) = op_grep { $_->name eq 'entersub' } $cv->ROOT;
    tap($$entersub, ${$cv->ROOT}, \my @buf);

    $code->();

=head1 DESCRIPTION

B::Tap is tapping library for B tree. C<tap> function injects custom ops for fetching result of the node.

The implementation works, but it's not beautiful code. I'm newbie about the B world, Patches welcome.

B<WARNINGS: This module is in a alpha state. Any API will change without notice.>

=head1 FUNCTIONS

=over 4

=item tap($op, $root_op, \@buf)

Tapping the result value of C<$op>. You need pass the C<$root_op> for rewriting tree structure. Tapped result value was stored to C<\@buf>. C<\@buf> must be arrayref.

B::Tap push the current stack to C<\@buf>. First element for each value is C<GIMME_V>. Second element is the value of stacks.

=item G_SCALAR

=item G_ARRAY

=item G_VOID

These functions are not exportable by default. If you want to use these functions, specify the import arguments like:

    use B::Tap ':all';

Or

    use B::Tap qw(G_SCALAR G_ARRAY G_VOID);

=back

=head1 FAQ

=over 4

=item Why this module required 5.14+?

Under 5.14, Perl5's custom op support is incomplete. B::Deparse can't deparse the code using custom ops.

I seem this library without deparsing is useless.

But if you want to use this with 5.8, it may works.

=back

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

