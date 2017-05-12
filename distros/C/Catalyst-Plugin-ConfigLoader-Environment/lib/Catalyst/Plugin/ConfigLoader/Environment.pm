package Catalyst::Plugin::ConfigLoader::Environment;

use warnings;
use strict;
use JSON::Any;
use MRO::Compat;
=head1 NAME

Catalyst::Plugin::ConfigLoader::Environment - Configure your
application with environment variables.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

Catalyst::Plugin::ConfigLoader::Environment reads environment
variables and sets up the configuration in your application
accordingly.

Here's how you use it:

    package MyApp;
    use Catalyst qw(... ConfigLoader::Environment ...);
    MyApp->setup;

Then, before you run your application, set some environment
variables:

    export MYAPP_foo='Hello, world!'
    export MYAPP_bar="foobar"
    perl script/myapp_server.pl

Inside your application, C<< $c->config->{foo} >> will be equal to
C<Hello, world!>, and C<< $c->config->{bar} >> will be equal to
C<foobar>.

=head2 Compatibility with ConfigLoader

You can use both ConfigLoader and this module in the same application.
If you specify C<ConfigLoader> before C<ConfigLoader::Environment> in
the import list to Catalyst, the environment will override any
configuration files that ConfigLoader may find.  This is the
recommended setup.

You can reverse the order in the import list if you want static config
files to override the environment, but that's not recommended.

=head1 DETAILS

Here's exactly how environment variables are translated into
configuration.

First, your application's name is converted to ALL CAPS, any colons
are converted to underscores (i.e. C<My::App> is translated to
C<MY_APP>), and a C<_> is appended.  Then, any environment variables
not starting with this prefix are discarded.

The prefix is then stripped, and the remaining variables are then
converted to elements in the C<config> hash as follows.

Variables starting with C<Model::>, C<View::>, or C<Controller::> and
then any character other than C<_> are treated as configuration
options for the corresponding component of your application.  The
prefix is saved as C<prefix> and everything after the first C<_> is
used as a key into the C<< $c->config->{"prefix"} >> hash.

Any other variables not starting with a special prefix are added
directly to the C<< $c->config >> hash.

=head1 EXAMPLES

Let's translate a YAML config file:

    ---
    name: MyApp
    title: This is My App!
    View::Foo:
      EXTENSION: tt
      EVAL_PERL: 1
    Model::Bar:
      root: "/etc"
    Model::DBIC:
      connect_info: [ "dbi:Pg:dbname=foo", "username", "password" ]

into environment variables that would setup the same configuration:

    MYAPP_name=MyApp
    MYAPP_title=This is My App!
    MYAPP_View__Foo_EXTENSION=tt
    MYAPP_View__Foo_EVAL_PERL=1
    MYAPP_Model__Bar_root=/etc
    MYAPP_Model__DBIC_connect_info=["dbi:Pg:dbname=foo", "username", "password"]

Double colons are converted into double underscores.  For
compatibility's sake, support for the 0.01-style use of
bourne-incompatible variable names is retained.

Values are JSON-decoded if they look like JSON arrays or objects
(i.e. if they're enclosed in []s or {}s). Taking advantage of that, we
can write the same example this way:

    MYAPP_name=MyApp
    MYAPP_title=This is My App!
    MYAPP_View__Foo={"EXTENSION":"tt","EVAL_PERL":1}
    MYAPP_Model__Bar={"root":"/etc"}
    MYAPP_Model__DBIC={"connect_info":["dbi:Pg:dbname=foo", "username", "password"]}

=head1 FUNCTIONS

=head2 setup

Overriding Catalyst' setup routine.

=cut

sub setup {
    my $c    = shift;
    my $prefix = Catalyst::Utils::class2env($c);
    my %env;
    for (keys %ENV) { 
        m/^${prefix}[_](.+)$/ and $env{$1} = $ENV{$_}; 
    }

    foreach my $var (keys %env) {
        my $val = $env{$var};

        # Decode JSON array/object 
        if ( $val =~ m{^\[.*\]$|^\{.*\}$} ) {
            $val = JSON::Any->jsonToObj($val);
        }

        # Special syntax Model__Foo is equivalent to Model::Foo
        if($var =~ /(Model|View|Controller)(?:::|__)([^_]+)(?:_(.+))?$/) {
            $var = "${1}::$2";

            # Special syntax Model__Foo_bar (or Model::Foo_bar) will
            # tweak just the 'bar' subparam for Model::Foo's
            # config. We can accomplish this using a hash that
            # specifies just 'bar' ($c->config will merge hashes).
            if ( defined $3 ) {
                $val = { $3 => $val };
            }
        }

        $c->config( $var => $val );
    }
    
    return $c->maybe::next::method(@_);
}


=head1 AUTHOR

Jonathan Rockway, C<< <jrockway at cpan.org> >>

=head1 CONTRIBUTORS

mugwump

Ryan D Johnson, C<< <ryan at innerfence.com> >>

Devin J. Austin C<< <dhoss@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-configloader-environment at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-ConfigLoader-Environment>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::ConfigLoader::Environment

You can also look for information at:

=over 4

=item * Catalyst Mailing List

L<mailto:catalyst@lists.rawmode.org>.

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-ConfigLoader-Environment>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jonathan Rockway, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

If you'd like to use it under a different license, that's probably OK.
Please contact the author.

=cut

1; # End of Catalyst::Plugin::ConfigLoader::Environment
