package Caller::Easy;
use 5.014004;
use strict;
use warnings;
use Carp;

our $VERSION = "0.02";

use overload '""' => sub{ $_[0]->package() }, fallback => 1;

use Moose;

has 'depth'         => ( is => 'ro',                                isa => 'Maybe[Num]' );
has 'package'       => ( is => 'ro', writer => '_set_package',      isa => 'Str' );
has 'filename'      => ( is => 'ro', writer => '_set_filename',     isa => 'Str' );
has 'line'          => ( is => 'ro', writer => '_set_line',         isa => 'Num' );
has 'subroutine'    => ( is => 'ro', writer => '_set_subroutine',   isa => 'Str' );
has 'hasargs'       => ( is => 'ro', writer => '_set_hasargs',      isa => 'Bool' );
has 'wantarray'     => ( is => 'ro', writer => '_set_wantarray',    isa => 'Bool' );
has 'evaltext'      => ( is => 'ro', writer => '_set_evaltext',     isa => 'Str' );
has 'is_require'    => ( is => 'ro', writer => '_set_is_require',   isa => 'Bool' );
has 'hints'         => ( is => 'ro', writer => '_set_hints',        isa => 'Num' );
has 'bitmask'       => ( is => 'ro', writer => '_set_bitmask',      isa => 'Str' );
has 'hinthash'      => ( is => 'ro', writer => '_set_hinthash',     isa => 'Maybe[HashRef]' );
has 'args'          => ( is => 'ro', writer => '_set_args',         isa => 'Maybe[ArrayRef]' );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if( @_ == 1 ) {
        return $class->$orig( depth => $_[0] ) if $_[0] =~ /^\d+$/;
        croak 'Unvalid depth was assigned';
    }elsif( @_ > 2 ) {
        croak 'Too many arguments for caller';
    }elsif( @_ == 2 and not exists $_{depth} ) {
        croak 'Unvalid arguments for caller';
    }else{
        return $class->$orig(@_);
    }
};

sub BUILD {
    my $self = shift;
    my $depth = $self->depth();

    my (
        $package, $filename, $line,
        $subroutine, $hasargs, $wantarray, $evaltext,
        $is_require, $hints, $bitmask, $hinthash
    );


    if( defined $depth and $depth =~ /^\d+$/ ) {
        package DB {
            our @args;
            my $i = 1;
            do {
                ( $package, $filename, $line ) = CORE::caller($i++);
            } while( $package =~ /^Test::/ or $package =~ /^Caller::Easy/ );

            (
                undef, undef, undef,
                $subroutine, $hasargs, $wantarray, $evaltext,
                $is_require, $hints, $bitmask, $hinthash
            ) = CORE::caller( $depth + $i++ );
        }
    }else{
        my $i = 1;
        do {
            ( $package, $filename, $line ) = CORE::caller($i++);
        } while( $package =~ /^Test::/ or $package =~ /^Caller::Easy/ );

        $self->_set_package($package)   if $package;
        $self->_set_filename($filename) if $filename;
        $self->_set_line($line)         if $line;

        return $self unless wantarray;
        return ( $package, $filename, $line );
    }

    $self->_set_package($package)           if $package;
    $self->_set_filename($filename)         if $filename;
    $self->_set_line($line)                 if $line;
    $self->_set_subroutine($subroutine)     if $subroutine;
    $self->_set_hasargs($hasargs)           if defined $hasargs;
    $self->_set_wantarray($wantarray)       if defined $wantarray;
    $self->_set_evaltext($evaltext)         if $evaltext;
    $self->_set_is_require($is_require)     if defined $is_require;
    $self->_set_hints($hints)               if $hints;
    $self->_set_bitmask($bitmask)           if $bitmask;
    $self->_set_hinthash($hinthash)         if $hinthash;
    $self->_set_args(\@DB::args);

    return $self unless wantarray;
    return (
        $package, $filename, $line,
        $subroutine, $hasargs, $wantarray, $evaltext,
        $is_require, $hints, $bitmask, $hinthash
    );
}

__PACKAGE__->meta->make_immutable;
no Moose;

sub caller {
    __PACKAGE__->new(@_);
}

sub import {
    my $packagename = CORE::caller;
    no strict 'refs';
    *{"$packagename\::caller"} = \&caller;
}

1;
__END__

=encoding utf-8

=head1 NAME

Caller::Easy - less stress to remind returned list from CORE::caller()

=head1 SYNOPSIS

 use Caller::Easy; # Module name is temporal

 # the way up to now
 sub foo {
    my $subname = (caller(0))[3];
 }

 # with OO
 sub foo {
    my $subname = Caller::Easy->new(0)->subroutine();
 }

 # like a function imported
 sub foo {
    my $subname = caller(0)->subroutine();
 }

All the above will return 'main::foo'

Now you can choise the way you much prefer

=head1 DESCRIPTION

Caller::Easy is the easiest way for using functions of C<CORE::caller()>

it produces the easier way to get some info from C<caller()> with no having to care about namespace.

=head2 Constructor and initialization

=head3 new()

You can set no argument then it returns the object reference in scalar context.

In list context, you can get just only ( $package, $filename, $line ).

if you set depth(level) like C<new(1)>, you can get more info from caller
( $package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext,
$is_require, $hints, $bitmask, $hinthash )
directly with same term for C<CORE::caller()>

To be strictly, you can set C<depth> parameter like C<new( depth =E<gt> 1 )>
but we can forget it, just set the natural number you want to set.

=head2 Methods (All of them is read-only)

=head3 caller()

It is implemented to be alias of C<new()> but it doesn't matter.

this method is imported to your packages automatically when you C<use Caller::Easy;>

So you can use much freely this method like if there is no module imported.

=head3 package()

You can get package name instead of C<(caller(n))[0]>

=head3 filename()

You can get file name instead of C<(caller(n))[1]>

=head3 line()

You can get the line called instead of C<(caller(n))[2]>

=head3 subroutine()

You can get the name of subroutine instead of C<(caller(n))[3]>

=head3 hasargs(), wantarray(), evaltext(), is_require(), hints(), bitmask(), hinthash()

Please read L<CORE::caller|http://perldoc.perl.org/functions/caller.html>

B<Don't ask me>

=head3 args()

You can get the arguments of targeted subroutine instead of C<@DB::args>

This method is the B<unique> point of this module.

=head3 depth()

You can get what you set.

=head1 TODO

=over

=item using Moose is a bottle-neck

I made this module in a few days with Moose because it's the easiest way.
It will be too heavy for some environments.

To abolish Moose is a TODO if this module will be popular.

=item rewite the tests

I don't know well about L<CORE::caller|http://perldoc.perl.org/functions/caller.html>!

Why I have written this module is
Just only I can't remember what I wanna get with something number from caller()
without some reference.

So some of tests may not be appropriate.

=item rename the module

I have to find the name that deserve it.

=item rewite the POD

I know well that my English is awful.

=back

=head1 SEE ALSO

=over

=item L<CORE::caller|http://perldoc.perl.org/functions/caller.html>

If you are confused with this module, Please read this carefully.

=item L<Perl6::Caller|http://search.cpan.org/~ovid/Perl6-Caller/lib/Perl6/Caller.pm>

One of better implements for using something like this module.

The reason why I reinvent the wheel is that this module has no github repository.

=item L<Safe::Caller|https://github.com/stsc/Safe-Caller>

The newest implement for using something like this module.

It has github repository but usage is limited.

=back

=head1 LICENSE

Copyright (C) Yuki Yoshida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida E<lt>worthmine@gmail.comE<gt>

=cut
