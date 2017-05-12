use strict;
use warnings;

package DB::Skip;

# ABSTRACT: make the perl debugger skip statements in given packages or subs
our $VERSION = '1.132980'; # VERSION


{
    my $old_db;

    sub old_db {
        my ( $class, $ref ) = @_;
        $old_db = $ref if $ref;
        return $old_db;
    }
}

sub import {
    my ( $class, %opts ) = @_;

    $opts{$_} ||= [] for qw( pkgs subs );

    my @pkg_regex = grep { ref and ref eq "Regexp" } @{ $opts{pkgs} };
    my @sub_regex = grep { ref and ref eq "Regexp" } @{ $opts{subs} };

    my %pkg_skip = map { $_ => 1 } grep { !ref } @{ $opts{pkgs} };
    my %sub_skip = map { $_ => 1 } grep { !ref } @{ $opts{subs} };

    $class->old_db( \&DB::DB ) if !$class->old_db;

    my $new_DB = sub {
        my $lvl = 0;
        while ( my ( $pkg ) = caller( $lvl++ ) ) {
            return if $pkg eq "DB" or $pkg =~ /^DB::/;
        }

        my ( $pkg ) = caller;
        return if $pkg_skip{$pkg};

        my ( undef, undef, undef, $sub ) = caller( 1 );
        return if $sub and $sub_skip{$sub};

        for my $pkg_re ( @pkg_regex ) {
            next if !$pkg_re;
            return if $pkg =~ $pkg_re;
        }

        for my $sub_re ( @sub_regex ) {
            next if !$sub_re;
            return if $sub =~ $sub_re;
        }

        goto &{ $class->old_db };
    };

    {
        no warnings 'redefine';
        *DB::DB = $new_DB;
    }

    return;
}

1;

__END__
=pod

=head1 NAME

DB::Skip - make the perl debugger skip statements in given packages or subs

=head1 VERSION

version 1.132980

=head1 SYNOPSIS

    use DB::Skip pkgs => [ qw( Marp ), qr/^Mo/ ], subs => [qw( main::skip )];

    my $meep = skip();
    $meep = Marp::skip();
    $meep = Moop::skip();
    $meep = debug();
    exit;

    sub skip { 1 }
    sub debug { 4 }

    package Marp;
    sub skip { 2 }

    package Moop;
    sub skip { Meep::debug(); 3 }

    package Meep;
    sub debug { 3 }

The Perl debugger will skip over all the functions named skip(), since they are
excluded by the parameters passed to DB::Skip. However functions named debug()
will be treated as normal.

=head1 DESCRIPTION

The perl debugger is a wonderful tool and offers you many options to get to
where you want to be in your code. However sometimes you want to just cruise
through it.

This can be somewhat frustrating if you're using modules like Moo that insert a
lot of busywork functions that are necessary for execution, but obscure the
actual flow in the debugger.

Loading this module in your code will augment the debugger's main function with
one that silently ignores statements when their package or sub matches any of
the given parameters.

Note that this only concerns statements directly within the parameters.
Statements in subs called within ignored statements will still be picked up by
the debugger, as long as they do not match any of the exclusion parameters.

=head1 METHODS

=head2 import

    DB::Skip->import(
        pkgs => [ 'My::Mod', qr/^Mine/ ],
        subs => [ 'MyMod::sub', qr/::my_sub_/ ],
    );

This class method can be called either implicitly via use or directly. On first
invocation the original reference to the DB::DB sub-routine is stored in a class
singleton and later used to invoke the original debugger functionality for
statements that did not match the skip parameters.

It expects a hash as parameters, with two optional keys: pkgs and subs. The
value of the key pkgs is used to match for packages to be skipped, while the
value of the key subs is used to match for fully qualified sub names (i.e.
Package::subname) to be skipped.

Both of these expect an array reference as value, with the array containing
either strings or regexes. Strings are used to compare directly to the package
or sub name, by way of hash lookup. Regexes are iterated over and matched with
the package or sub name until a match is found and thus the statement skipped,
or no regexes are left.

Repeated calls of this method will remove the last set of parameters and install
a new one.

=head2 old_db

    my $old_db_sub_ref = DB::Skip->old_db;
    DB::Skip->old_db( \&DB::DB );

This class method is a minimal accessor to a class singleton, containing the
original DB function of the currently loaded debugger. The singleton is
initialized when import is called the first time, so you can retrieve the sub
reference at any point after that.

Alternatively you can also set it with this method at any given point, before or
after calling import. If you set the singleton before calling import, then
import not overwrite the one you set and use your reference instead. If you set
it after calling import, import will start using your code reference from that
point on forward.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=DB-Skip>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/wchristian/db-skip>

  git clone https://github.com/wchristian/db-skip.git

=head1 AUTHOR

Christian Walde <walde.christian@googlemail.com>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut

