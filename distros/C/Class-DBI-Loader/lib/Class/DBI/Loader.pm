package Class::DBI::Loader;

use strict;
use vars '$VERSION';

$VERSION = '0.34';

=head1 NAME

Class::DBI::Loader - Dynamic definition of Class::DBI sub classes.

=head1 SYNOPSIS

  use Class::DBI::Loader;

  my $loader = Class::DBI::Loader->new(
    dsn                     => "dbi:mysql:dbname",
    user                    => "root",
    password                => "",
    options                 => { RaiseError => 1, AutoCommit => 0 },
    namespace               => "Data",
    additional_classes      => qw/Class::DBI::AbstractSearch/, # or arrayref
    additional_base_classes => qw/My::Stuff/, # or arrayref
    left_base_classes       => qw/Class::DBI::Sweet/, # or arrayref
    constraint              => '^foo.*',
    relationships           => 1,
    options                 => { AutoCommit => 1 }, 
    inflect                 => { child => 'children' },
    require                 => 1
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

use with mod_perl

in your startup.pl

  # load all tables
  use Class::DBI::Loader;
  my $loader = Class::DBI::Loader->new(
    dsn       => "dbi:mysql:dbname",
    user      => "root",
    password  => "",
    namespace => "Data",
  );

in your web application.

  use strict;

  # you can use Data::Film directly
  my $film = Data::Film->retrieve($id);


=head1 DESCRIPTION

Class::DBI::Loader automate the definition of Class::DBI sub-classes.
scan table schemas and setup columns, primary key.

class names are defined by table names and namespace option.

 +-----------+-----------+-----------+
 |   table   | namespace | class     |
 +-----------+-----------+-----------+
 |   foo     | Data      | Data::Foo |
 |   foo_bar |           | FooBar    |
 +-----------+-----------+-----------+

Class::DBI::Loader supports MySQL, Postgres and SQLite.

See L<Class::DBI::Loader::Generic>.

=cut

sub new {
    my ( $class, %args ) = @_;
    my $dsn = $args{dsn};
    my ($driver) = $dsn =~ m/^dbi:(\w*?)(?:\((.*?)\))?:/i;
    $driver = 'SQLite' if $driver eq 'SQLite2';
    my $impl = "Class::DBI::Loader::" . $driver;
    eval qq/use $impl/;
    die qq/Couldn't require loader class "$impl", "$@"/ if $@;
    return $impl->new(%args);
}

=head1 METHODS

=head2 new %args

=over 4

=item additional_base_classes

List of additional base classes your table classes will use.

=item left_base_classes

List of additional base classes, that need to be leftmost, for
example L<Class::DBI::Sweet> (former L<Catalyst::Model::CDBI::Sweet>).

=item additional_classes

List of additional classes which your table classes will use.

=item constraint

Only load tables matching regex.

=item exclude

Exclude tables matching regex.

=item debug

Enable debug messages.

=item dsn

DBI Data Source Name.

=item namespace

Namespace under which your table classes will be initialized.

=item password

Password.

=item options

Optional hashref to specify DBI connect options

=item relationships

Try to automatically detect/setup has_a and has_many relationships.

=item inflect

An hashref, which contains exceptions to Lingua::EN::Inflect::PL().
Useful for foreign language column names.

=item user

Username.

=item require

Attempt to require the dynamically defined module, so that extensions
defined in files. By default errors from imported modules are suppressed.
When you want to debug, use require_warn.

=item require_warn

Warn of import errors when requiring modules.

=back

=head1 AUTHOR

Daisuke Maki C<dmaki@cpan.org>

=head1 AUTHOR EMERITUS

Sebastian Riedel, C<sri@oook.de>
IKEBE Tomohiro, C<ikebe@edge.co.jp>

=head1 THANK YOU

Adam Anderson, Andy Grundman, Autrijus Tang, Dan Kubb, David Naughton,
Randal Schwartz, Simon Flack and all the others who've helped.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>, L<Class::DBI::mysql>, L<Class::DBI::Pg>, L<Class::DBI::SQLite>,
L<Class::DBI::Loader::Generic>, L<Class::DBI::Loader::mysql>,
L<Class::DBI::Loader::Pg>, L<Class::DBI::Loader::SQLite>

=cut

1;
