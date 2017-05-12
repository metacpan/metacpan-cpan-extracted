#!/usr/bin/perl -w
use strict;

#
# FormMagick (c) 2000 Kirrily Robert <skud@infotrope.net>
# This software is distributed under the GNU General Public License; see
# the file COPYING for details.
#
# $Id: Sub.pm,v 1.5 2001/10/26 17:23:47 ryanking Exp $
#

=pod

=head1 NAME

CGI::FormMagick::Sub - Call subs by name.

=head1 SYNOPSIS

    use CGI::FormMagick::Sub;
    my %sub = (
        package => $some_package_name,
        sub => $some_sub_name,
        args => \@array_of_args,
        comma_delimited_args => $string_of_comma_delimited_args,
    );

    CGI::FormMagick::Sub::exists(%sub) or return undef;
    return CGI::FormMagick::Sub::call(%sub);

=head1 DESCRIPTION

(Intended for internal use only.)

Used for calling subs whose names are dynamically generated.

=head1 STATIC METHODS

=head2 exists(...)

exists() takes a hash with keys "package" and "sub".  Returns true if
the sub exists, false otherwise.

=head2 call(...)

call() takes a hash with keys "package" and "sub", and optional "args" and
"comma_delimited_args".  The "comma_delimited_args" are split up and
pushed into the array of args to be sent to the sub when called.  Returns
the return of the called sub itself.

If the sub doesn't exist, it will return undef.  If $^W is true, it will
also complain.

=cut

package CGI::FormMagick::Sub;

use Carp;

=begin testing
BEGIN {
    use_ok 'CGI::FormMagick::Sub';
}

{
    package main;
    sub f {
        return 'Ok'
    }
}

{
    package ArbitraryPackage;
    sub hey {
        return 'You found me.';
    }

    sub with_arg {
        return $_[0] x 2;
    }

    sub with_args {
        my $results = '';
        $results .= $_ for (reverse @_);
        return $results;
    }
}

{
    package Ness::ted;

    sub attack {
        return 'PK Fire!'; # (Sorry -- Smash Bros. reference. =))
    }
}

foreach my $expectations (
    {
        expected => 'Ok',
        call_with => {
            package => 'main',
            sub => 'f'
        }
    }, {
        expected => 'You found me.',
        call_with => {
            package => 'ArbitraryPackage',
            sub => 'hey'
        }
    }, {
        expected => 'PK Fire!',
        call_with => {
            package => 'Ness::ted',
            sub => 'attack'
        }
    }, {
        expected => 'RepeatRepeat',
        call_with => {
            package => 'ArbitraryPackage',
            sub => 'with_arg',
            args => [ 'Repeat' ],
        }
    }, {
        expected => 'Backwards',
        call_with => {
            package => 'ArbitraryPackage',
            sub => 'with_args',
            args => [ qw(wards Back) ]
        }
    }, {
        expected => 'abc',
        call_with => {
            package => 'ArbitraryPackage',
            sub => 'with_args',
            args => [ qw(c b a) ]
        }
    }, {
        expected => 'abc',
        call_with => {
            package => 'ArbitraryPackage',
            sub => 'with_args',
            comma_delimited_args => 'c,b,a'
        }
    }

#    We could do parsing for this, but we'll defer it until it's needed.
#    , {
#        expected => 'OneTwoThree',
#        call_with => {
#            package => 'ArbitraryPackage',
#            sub => 'with_args',
#            comma_delimited_args => '"Thr,ee","Two","One"'
#        }
#    }

) {
    my $expected = $expectations->{expected};
    my %call_with = %{$expectations->{call_with}};
    my ($package, $sub) = @call_with{qw(package sub)};

    my $description = "$package\::$sub";

    if (exists $call_with{args}) {
        $description .= "('" . join("', '", @{$call_with{args}}) . "')";
    } else {
        $description .= '()';
    }

    my $actual = CGI::FormMagick::Sub::call(%call_with);

    is($actual, $expected, $description);
}

=end testing

=cut

sub call {
    my %params = @_;
    my $package = $params{package} || '';
    my $sub_name = $params{sub};
    my @args = exists $params{args} ? @{$params{args}} : ();

    if (defined $params{comma_delimited_args}) {
        push @args, split /,\s*/, $params{comma_delimited_args};
    }

    my $sub = get_sub($package, $sub_name);

    if (defined $sub) {
        return $sub->(@args);
    } else {
        carp "FormMagick: Couldn't call '$package\:\:$sub_name'" if $^W;
        return undef;
    }
}

=begin testing

foreach my $expectations (
    { expected => 1, sub => 'f' },
    { expected => 0, sub => 'shouldnt_exist' },
    { expected => 0, sub => 'shouldnt exist' },
) {
    my ($expected, $sub) = @{$expectations}{qw(expected sub)};
    my $actual = CGI::FormMagick::Sub::exists(
        package => 'main',
        sub => $sub
    );

    my $should = 'should' . ($expected ? '' : "n't");
    my $description = "sub $sub $should exist.";

    is($expected, $actual, $description);
}

=end testing

=cut

sub exists {
    my %params = @_;
    my ($package, $sub) = @params{qw(package sub)};

    return defined get_sub($package, $sub) ? 1 : 0;
}

sub get_sub {
    my ($package, $sub) = @_;
    no strict 'refs'; # Into the Evil Cavern... mwahahahahaaaaaa
    my $package_symbols = *{$package . '::'}{HASH};
    return $package_symbols->{$sub};
}

return 1;
