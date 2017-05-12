use strict;
use warnings;

package Config::Role;
{
  $Config::Role::VERSION = '0.1.1';
}
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: Moose config attribute loaded from file in home dir

use File::HomeDir;
use Path::Class::Dir;
use Path::Class::File;
use Config::Any;
use MooseX::Types::Moose qw(ArrayRef HashRef Str Object);

use MooseX::Types -declare => [qw( Dir File ArrayRefOfFile )];
subtype Dir,
    as Object,
    where { $_->isa('Path::Class::Dir') };
coerce Dir,
    from Str,
    via { Path::Class::Dir->new($_) };
subtype File,
    as Object,
    where { $_->isa('Path::Class::File') };
coerce File,
    from Str,
    via { Path::Class::File->new($_) };
subtype ArrayRefOfFile,
    as ArrayRef[File];
coerce ArrayRefOfFile,
    from ArrayRef[Str],
    via { [ map { to_File($_) } @$_ ] };



has 'config_dir' => (
    is         => 'ro',
    isa        => Dir,
    coerce     => 1,
    lazy_build => 1,
);

sub _build_config_dir {
    my ($self) = @_;
    return Path::Class::Dir->new(File::HomeDir->my_data);
}


has 'config_file' => (
    is         => 'ro',
    isa        => File,
    coerce     => 1,
    lazy_build => 1,
);

sub _build_config_file {
    my ($self) = @_;
    my $config_filename = "";
    if ( $self->can('config_filename') ) {
        $config_filename = $self->config_filename;
    }
    else {
        # Method taken from Catalyst::Utils->appprefix()
        $config_filename = lc( $self->meta->name );
        $config_filename =~ s/::/_/g;
        $config_filename = ".${config_filename}.ini";
    }
    return $self->config_dir->file(
        $config_filename
    );
}


has 'config_files' => (
    is         => 'ro',
    isa        => ArrayRefOfFile,
    coerce     => 1,
    lazy_build => 1,
);
sub _build_config_files {
    my ($self) = @_;
    return [ $self->config_file ];
}


has 'config' => (
    is         => 'ro',
    isa        => HashRef,
    lazy_build => 1,
);

sub _build_config {
    my ($self) = @_;
    my $cfg = Config::Any->load_files({
        use_ext => 1,
        files   => $self->config_files,
    });
    foreach my $config_entry ( @{ $cfg } ) {
        my ($filename, $config) = %{ $config_entry };
        return $config;
    }
    return {};
}

1;



=pod

=encoding utf-8

=head1 NAME

Config::Role - Moose config attribute loaded from file in home dir

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

    package My::Class;
    use Moose;
    with 'Config::Role';

    # Read configuration from ~/.my_class.ini, available in $self->config
    # This is optional if you like this particular naming of the file
    has 'config_filename' => ( is => 'ro', isa => 'Str', lazy_build => 1 );
    sub _build_config_filename { '.my_class.ini' }

    # Fetch a value from the configuration, allow constructor override
    has 'username' => ( is => 'ro', isa => 'Str', lazy_build => 1 );
    sub _build_username { return (shift)->config->{'username'}; }

    sub make_request {
        my ($self) = @_;
        my $response = My::Class::Request->make(
            username => $self->username,
            ...
        );
        ...
    }

=head1 RATIONALE

This is the problem Config::Role was created to solve: Give me a config
attribute (hashref) which is read from a file in my home directory to give
other attributes default values, with configurability to choose the file's
location and name.

=head1 DESCRIPTION

Config::Role is a very basic role you can add to your Moose class that
allows it to take configuration data from a file located in your home
directory instead of always requiring parameters to be specified in the
constructor.

The synopsis shows how you can read the value of C<username> from the file
C<.my_class.ini> located in the home directory of the current user.  The
location of the file is determined by whatever C<< File::HomeDir->my_data >>
returns for your particular platform.

The config file is loaded by using L<Config::Any>'s C<load_files()> method.
It will load the files specified in the C<config_files> attribute.  By
default this is an array reference that contains the filename from the
C<config_file> attribute.  If you specify multiple files which both contain
the same configuration key, the value is loaded from the first file.  That
is, the most significant file should be first in the array.

The C<< Config::Any->load_files() >> flag C<use_ext> is set to a true value, so you
can use any configuration file format supported by L<Config::Any> by just
specifying the common filename extension for the format.

=head1 ATTRIBUTES

=head2 config_dir

The directory where the configuration file is located. A Path::Class::Dir
object.  Defaults to C<< File::HomeDir->my_data >>.  Allows coercion from
Str.

=head2 config_file

The filename the configuration is read from. A Path::Class::File object.
Allows coercion from Str.  Default is calculated based on the composing
class name.  If your composing class is called C<My::Class> it will be
C<.my_class.ini>.  Remember that if you sub-class the composing class, the
default will be the name of the sub-class, not the super-class.

=head2 config_files

The collection of filenames the configuration is read from. Array reference
of L<Path::Class::File> objects.  Allows coercion from an array reference of
strings.

=head2 config

A hash reference that holds the compiled configuration read from the
specified files.

=head1 METHODS

=head2 config_filename

Optional attribute or method on the composing class. Should return a string
with the name of the configuration file name.  See C<config_file> for
how the default is calculated if this method is not available.

=head1 COMPARISON TO L<MooseX::ConfigFromFile>

Config::Role doesn't require you to use anything else than C<< $class->new() >> to
actually get the benefit of automatic config loading.  Someone might see this as
negative, as it gives a minor performance penalty even if the config file is
not present.

Config::Role uses L<File::HomeDir> to default to a known location, so you
only need to specify the file name you use, not a full path.  This should
give better cross-platform compatibility, together with the use of
Path::Class for all file system manipulation.

Also, with Config::Role you must explicitly specify in the builder of an
attribute that you want to use values from the config file.
MooseX::ConfigFromFile seems to do that for you.  You also get the benefit
that the configuration file keys and the class attribute names does not need
to map 1-to-1 (someone will probably see that as a bad thing).

Otherwise they are pretty similar in terms of what they do.

=head1 TODO

=over 4

=item *

A nicely named sugar function could be exported to allow less boilerplate
in generating attributes that default to config values.

=back

=head1 SEMANTIC VERSIONING

This module uses semantic versioning concepts from L<http://semver.org/>.

=head1 SEE ALSO

=over 4

=item *

L<Moose>

=item *

L<File::HomeDir>

=item *

L<Config::Any>

=item *

L<Path::Class::File>

=item *

L<MooseX::ConfigFromFile>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Config::Role

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Config-Role>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Role>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annonations of Perl module documentation.

L<http://annocpan.org/dist/Config-Role>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Config-Role>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Config-Role>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Config-Role>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Config-Role>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual way to determine what Perls/platforms PASSed for a distribution.

L<http://matrix.cpantesters.org/?dist=Config-Role>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Config::Role>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-config-role at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Role>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/robinsmidsrod/Config-Role>

  git clone git://github.com/robinsmidsrod/Config-Role.git

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

