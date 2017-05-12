package App::Kit;

## no critic (RequireUseStrict) - Moo does strict and warnings
use Moo;

our $VERSION = '0.62';

sub import {
    strict->import;
    warnings->import;

    unless ( defined $_[1] && $_[1] eq '-no-try' ) {    # Yoda was right: there *is* -no-try!
        require Try::Tiny;

        # Try::Tiny->import();  # not like pragma in import, so:
        require Import::Into;
        my $caller = caller();
        Try::Tiny->import::into($caller);
    }
}

# tidyoff
with 'Role::Multiton', # Would like to do ::New but that falls apart once you decide to extend() See rt 89239. For now we TODO the multiton-via-new tests
    'App::Kit::Role::Log',
    'App::Kit::Role::Locale',
    'App::Kit::Role::HTTP',
    'App::Kit::Role::NS',
    'App::Kit::Role::FS',
    'App::Kit::Role::Str',
    'App::Kit::Role::CType',
    'App::Kit::Role::Detect',
    'App::Kit::Role::DB',
    'App::Kit::Role::Ex';
# tidyon

1;

__END__

=encoding utf-8

=head1 NAME

App::Kit - A Lazy Façade to simplify your code/life

=head1 VERSION

This document describes App::Kit version 0.62

=head1 SYNOPSIS

Use directly in your code:

    ## no critic (RequireUseStrict) - App::Kit does strict and warnings
    use App::Kit;
    my $app = App::Kit->multiton; # now your script and all the modules that make it up have access to the same logging, localization, and a host of other fetaures without loading anything for them and not requiring special voo doo to load/initialize.

Or roll your own to use instead:

    package My::App;

    ## no critic (RequireUseStrict) - Moo does strict and warnings
    use Moo;
    extends 'App::Kit';

    with '…'; # add a new role
    has 'newthing' => ( … ); # add a new attr
    has '+app_kit_thingy' => ( … ); # customize an existing role/attr/method
    sub newmeth { … } # add a new method
    …

=head1 DESCRIPTION

A Lazy Façade to simplify your code/life. How?

Ever see this sort of thing in a growing code base:

    package My::Thing;
    
    use strict;
    use warnings;
    
    use My::Logger;
    my $logger;
    
    sub foo {
        my ($x, $y, $z) = @_;
        if ($x) {
            $logger ||= MyLogger->new;
            $logger->info("X is truly $x");
        }
        …
    }

but if that module (or script) had access to your App::Kit object:

    package My::Thing;

    ## no critic (RequireUseStrict) - MyApp does strict and warnings
    use MyApp;
    my $app = MyApp->multiton; # ok to do this here because it is really really cheap

    sub foo {
        my ($x, $y, $z) = @_;
        if ($x) {
            $app->log->info("X is truly $x");
        }
        …
    }

Multiply that by hundreds of scripts and modules and vars and tests and wrappers. ick

Some specifics:

=head2 one class/one object to consistently and simply manage some of the complexities of a large code base

Don’t pass around globals, a zillion args, have a bunch of was-this-loaded, do-we-have-that, etc.

Just create the object and use it everywhere. Done, it all works the same with no boiler plate required besides Foo->instance and use it when you need.

=head2 only what you need, when you need it

Only load and instantiate the things your code actually does, with no effort.

Reuse them throughout the code base, again, with no effort!

=head2 use default objects or set your own

The defaults will work and as your project expands you can customize if needed without needing to refactor your code. 

For example, once you sprint the localization setup, you can change your class’s locale() to use your object.

=head2 easy mocking (for your tests!)

By default the lazy façade methods are readonly (technically 'rwp' so the class can fiddle with them internally if it needs to).

You can change make them readwrite via either of 2 mechanisms before the class is built via use().

Either:

    use App::Kit::Util::RW; # must be loaded before App::Kit is use()d
    use App::Kit;

or

    BEGIN { $ENV{'App-Kit-Util-RW'} = 1; };  # must be set before App::Kit is use()d
    use App::Kit;

then:

    $app->log($test_logger); # e.g. say $test_logger stores what level and msg are called/given
    … something that should call $app->log->info('This is a terrible info msg.') …
    … test that $test_logger saw the expected levels and msgs …

The former might be desirable if you want to keep ENV clean, the latter for when you want to do/skip certain tests based on if it is true or not:

    App-Kit-Util-RW=1 prove -w t

=head1 INTERFACE

=head2 auto imports

=head3 strict and warnings enabled automatically

=head3 try/catch/finally imported automatically (unless you say not to)

L<Try::Tiny> is enabled automatically unless you pass import() “-no-try” flag (Yoda was right: there *is* -no-try!):

    use App::Kit '-no-try';

same goes for your App::Kit based object:

    use My::App '-no-try';

=head2 constructors: multiton support

=head3 new()

Since the idea of this class is to share the objects it makes more sense to use multiton()/instance() in your code.

Returns a new object every time. Takes no arguments currently.

=head3 multiton()

Returns the same object on subsequent calls using the same arguments. Since, there are currently no arguments it is essentially a singleton.

See L<Role::Multiton> for more details.

=head3 instance()

Alias to multiton(). If you ever plan on modifying the constructor to another type (weirdo) you may want to use this in your code instead of multiton().

See L<Role::Multiton> for more details.

=head2 Lazy façade methods

Each method returns a lazy loaded/instantiated object that implements the actual functionality.

=head3 $app->log

Lazy façade to a logging object via L<App::Kit::Role::Log>.

=head3 $app->locale

Lazy façade to a maketext() object via L<App::Kit::Role::Locale>. 

Has all the methods any L<Locale::Maketext::Utils> based object would have.

Localize your code now without needing an entire subsystem in place just yet!

=head3 $app->detect

Lazy façade to a context detection object via L<App::Kit::Role::Detect>.

=head3 $app->ctype

Lazy façade to a ctype utility object via L<App::Kit::Role::CType>.

=head3 $app->str

Lazy façade to a string utility object via L<App::Kit::Role::Str>.

=head3 $app->ns

Lazy façade to a name space utility object via L<App::Kit::Role::NS>.

=head3 $app->http

Lazy façade to an HTTP client object via L<App::Kit::Role::HTTP>.

=head3 $app->fs

Lazy façade to a file system utility object via L<App::Kit::Role::FS>.

=head3 $app->db

Lazy façade to a database utility object via L<App::Kit::Role::DB>.

=head3 $app->ex

Lazy façade to a system execution utility object via L<App::Kit::Role::Ex>.

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

All errors or warnings would come from perl, L<Moo>, or the façade object in question.

=head1 CONFIGURATION AND ENVIRONMENT

App::Kit requires no configuration files or environment variables.

If, however, the façade object in question does it will be documented specifically under it.

=head1 DEPENDENCIES

L<Moo> et al.

If you don't pass in -no-try: L<Try::Tiny>  and L<Import::Into>

Other modules would be documented above under each façade object that brings them in.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-kit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

=over 4

=item 1. More Lazy façade methods

=over 4 

=item * App::Kit::Role::Crypt 

    # $app->crypt->encrypt($str, $cipher) $app->xcrypt->decrypt($str, $cipher) ->rand_data

=item * App::Kit::Role::Cache

    # e.g Chi if it drops a few pounds by eating less Moose

=item * App::Kit::Role::In

    # i.e. HTTP or ARGV == $app->in->param('name')

=item * App::Kit::Role::Out

    # e.g.TT/classes/ANSI

=item * return obj/exception

=back

=item 2. Encapsulate tests that commonly do:

    Class::Unload->unload('…');
    ok(!exists $INC{'….pm'}, 'Sanity: … not loaded before');
    is $app->?->…, '…', '?() …'
    ok(exists $INC{'….pm'}, '… lazy loaded on initial ?()');

=item 3. easy to implement modes

for example:

=over 4

=item * root_safe: make certain methods die if called by root under some circumstance

(e.g. root calling file system utilities on paths owned by a user, forces them to drop privileges)

=item * owner_mode: process is running as owner of script

=item * chdir_safe: make chdir fatal

=back

=item 4. local()-type stash to get/set/has/del arbitrary data/objects to share w/ the rest of the consumers

=back

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
