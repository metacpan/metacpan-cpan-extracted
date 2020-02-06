package Acme::CPANModules::OneLinerTools;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-06'; # DATE
our $DIST = 'Acme-CPANModules-OneLinerTools'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Modules to make your life easier when writing perl one-liners',
    description => <<'_',
_
    entries => [

        {
            module => 'L',
            description => <<'_',

One of the "module autoloader" modules, which happens to have a short name for
one-liner usage. So instead of having to type this:

    % perl -MOrg::Parser::Tiny -E'$doc = Org::Parser::Tiny->new->parse_file("/home/budi/todo.org"); ...'

you can now write:

    % perl -ML -E'$doc = Org::Parser::Tiny->new->parse_file("/home/budi/todo.org"); ...'

"Module autoloader" modules work using Perl's autoloading mechanism (read
`perlsub` for more details). By declaring a subroutine named `AUTOLOAD` in the
`UNIVERSAL` package, you setup a fallback mechanism when you call an undefined
subroutine. <pm:L>'s AUTOLOADER loads the module using <pm:Module::Load> then
try to invoke the undefined subroutine once again.

_
            tags => ['module'],
        },

        {
            module => 'lib::xi',
            description => <<'_',

This module can automatically install missing module during run-time using
`cpanm`. Convenient when running a Perl script (that comes without a proper
distribution or `cpanfile`) that uses several modules which you might not have.
The alternative to lib::xi is the "trial and error" method: repeatedly run the
Perl script to see which module it tries and fails to load.

lib::xi works by installing a hook in `@INC`.

_
            tags => ['module'],
            alternate_modules => [
                'Require::Hook::More', # the autoinstalling feature has not been implemented though
            ],
        },

        {
            module => 'Log::Any::App',
            description => <<'_',

A convenient way to display (consume) logs if your application uses
<pm:Log::Any> to produce logs.

_
            tags => ['logging'],
        },

        {
            module => 'Log::ger::App',
            description => <<'_',

A convenient way to display (consume) logs if your application uses
<pm:Log::ger> to produce logs.

_
            tags => ['logging'],
        },

        {
            module => 'DD::Dummy',
            description => <<'_',

My preference when dumping data structure when debugging Perl application is,
well, Perl format (unlike some others which prefer custom format like
<pm:Data::Printer>). The DD-Dummy distribution provides <pm:DD> module, which in
turn exports `dd` to dump your data structures for debugging using
<pm:Data::Dump>. Another good alternative is <pm:XXX> which by default uses YAML
output but can be changed with this environment variable setting:

    PERL_XXX_DUMPER=Data::Dump

_
            alternate_modules => ['XXX', 'Data::Printer'],
            tags => ['debugging'],
        },

        {
            module => 'Devel::Confess',
            description => <<'_',

Forces stack trace when your application warns or dies. Used with the perl's
`-d` flag:

    % perl -d:Confess ...
    % perl -d:Confess=dump ...

_
            tags => ['debugging'],
        },

        {
            module => 'DBIx::Conn::MySQL',
            description => <<'_',

Shortcut when connecting to MySQL database in your one-liner. Instead of:

    % perl -MDBI -E'my $dbh = DBI->connect("dbi:mysql:database=mydb", "someuser", "somepass"); $dbh->selectrow_array("query"); ...'

you can type:

    % perl -MDBIx::Conn::MySQL=mydb -E'$dbh->selectrow_array("query"); ...'

_
            tags => ['database', 'dbi'],
        },

        {
            module => 'DBIx::Conn::SQLite',
            description => <<'_',

Shortcut when connecting to MySQL database in your one-liner. Instead of:

    % perl -MDBI -E'my $dbh = DBI->connect("dbi:SQLite:dbname=mydb", "", ""); $dbh->selectrow_array("query"); ...'

you can type:

    % perl -MDBIx::Conn::SQLite=mydb -E'$dbh->selectrow_array("query"); ...'

_
            tags => ['database', 'dbi'],
        },

    ],
};

1;
# ABSTRACT: Modules to make your life easier when writing perl one-liners

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::OneLinerTools - Modules to make your life easier when writing perl one-liners

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::OneLinerTools (from Perl distribution Acme-CPANModules-OneLinerTools), released on 2020-02-06.

=head1 DESCRIPTION

Modules to make your life easier when writing perl one-liners.

=head1 INCLUDED MODULES

=over

=item * L<L>

One of the "module autoloader" modules, which happens to have a short name for
one-liner usage. So instead of having to type this:

 % perl -MOrg::Parser::Tiny -E'$doc = Org::Parser::Tiny->new->parse_file("/home/budi/todo.org"); ...'

you can now write:

 % perl -ML -E'$doc = Org::Parser::Tiny->new->parse_file("/home/budi/todo.org"); ...'

"Module autoloader" modules work using Perl's autoloading mechanism (read
C<perlsub> for more details). By declaring a subroutine named C<AUTOLOAD> in the
C<UNIVERSAL> package, you setup a fallback mechanism when you call an undefined
subroutine. L<L>'s AUTOLOADER loads the module using L<Module::Load> then
try to invoke the undefined subroutine once again.


=item * L<lib::xi>

This module can automatically install missing module during run-time using
C<cpanm>. Convenient when running a Perl script (that comes without a proper
distribution or C<cpanfile>) that uses several modules which you might not have.
The alternative to lib::xi is the "trial and error" method: repeatedly run the
Perl script to see which module it tries and fails to load.

lib::xi works by installing a hook in C<@INC>.


Alternate modules: L<Require::Hook::More>

=item * L<Log::Any::App>

A convenient way to display (consume) logs if your application uses
L<Log::Any> to produce logs.


=item * L<Log::ger::App>

A convenient way to display (consume) logs if your application uses
L<Log::ger> to produce logs.


=item * L<DD::Dummy>

My preference when dumping data structure when debugging Perl application is,
well, Perl format (unlike some others which prefer custom format like
L<Data::Printer>). The DD-Dummy distribution provides L<DD> module, which in
turn exports C<dd> to dump your data structures for debugging using
L<Data::Dump>. Another good alternative is L<XXX> which by default uses YAML
output but can be changed with this environment variable setting:

 PERL_XXX_DUMPER=Data::Dump


Alternate modules: L<XXX>, L<Data::Printer>

=item * L<Devel::Confess>

Forces stack trace when your application warns or dies. Used with the perl's
C<-d> flag:

 % perl -d:Confess ...
 % perl -d:Confess=dump ...


=item * L<DBIx::Conn::MySQL>

Shortcut when connecting to MySQL database in your one-liner. Instead of:

 % perl -MDBI -E'my $dbh = DBI->connect("dbi:mysql:database=mydb", "someuser", "somepass"); $dbh->selectrow_array("query"); ...'

you can type:

 % perl -MDBIx::Conn::MySQL=mydb -E'$dbh->selectrow_array("query"); ...'


=item * L<DBIx::Conn::SQLite>

Shortcut when connecting to MySQL database in your one-liner. Instead of:

 % perl -MDBI -E'my $dbh = DBI->connect("dbi:SQLite:dbname=mydb", "", ""); $dbh->selectrow_array("query"); ...'

you can type:

 % perl -MDBIx::Conn::SQLite=mydb -E'$dbh->selectrow_array("query"); ...'


=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries OneLinerTools | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=OneLinerTools -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-OneLinerTools>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-OneLinerTools>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-OneLinerTools>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules::OneLetter>

L<Acme::CPANModules::ModuleAutoloaders>

L<Acme::CPANModules::DebugDumping>

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
