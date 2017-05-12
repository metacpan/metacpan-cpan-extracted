package AnnoCPAN::Config;

$VERSION = '0.22';

use strict;
use warnings;

=head1 NAME

AnnoCPAN::Config - AnnoCPAN configuration module

=head1 SYNOPSIS

    use AnnoCPAN::Config '/path/to/config.pl';

    my $db_user = AnnoCPAN::Config->option('db_user');

=head1 DESCRIPTION

This module is used to access the values for the various configuration
variables. The configuration is stored in a simple Perl file (let's call
it config.pl), which consists of a hashref declaration. For example,

    # config.pl
    {
        # database configuration options
        dsn         =>'dbi:mysql:annocpan',
        db_user     => 'itub',
        db_passwd   => 'qwerty',

        # local CPAN mirror
        cpan_root   => '/home/itub/CPAN',

        # site display options
        recent_notes   => 25,
        min_similarity => 0.5,
        cache_html     => 1,
        pre_line_wrap  => 72,
        template_path  => '../tt',

        # default user preferences
        js          => 1,
        tol         => 60.0,
        style       => 'side',
        prefs       => [qw(js tol style)],

        # webspace parameters
        root_uri_abs => 'http://www.annocpan.org',
        root_uri_rel => '',
        img_root     => '/img',
    }

=head1 CONFIGURATION VARIABLES

=over

=item dsn

DBI Data Source Name.

=item db_user

User name for database authentication.

=item db_passwd

Password for database authentication.

=item cpan_root

The pathname of the local CPAN mirror.

=item secret

A secret string that is used for "signing" authentication key cookies.

=item recent_notes

The number of recent notes to show on the front page and on the "Recent Notes"
RSS feed.

=item min_similarity

The minimum similarity that is considerd acceptable when translating a note to
a different version of a document. Notes won't be assigned to a document
version when there are no paragraphs above this threshhold. Also note that
adding notes is about 2X faster when this value is not zero. About 0.5 is
recommended.

=item cache_html

True or false. Whether to cache the HTML rendered version of documents. This
improves performance significantly for large documents, but may cause confusion
during testing.

=item pre_line_wrap

Wrap lines longer than this value in verbatim sections in the POD. This is to 
avoid layout problems and horizontal scrolling. When a line is wrapped, a plus
sign is inserted at the beginning of the continuation line.

=item template_path

The relative path to the directory that holds the templates.

=back

=head1 METHODS

=over

=item AnnoCPAN::Config->option($name)

Returns the value for configuration variable $name.

=cut

our $Config;

sub import {
    shift->new(@_);
}

sub new {
    my ($class, $fname) = @_;
    return $Config if $Config;
    $fname ||= 'config.pl';
    $Config = do $fname or die "Config error: '$fname': $!";
    bless $Config, $class;
}

sub option {
    my ($self, $name) = @_;
    $self->new->{$name};
}

=back

=head1 CAVEATS

This module only reads the config file the first time it is 'use'd. Since 
many AnnoCPAN modules use AnnoCPAN::Config, if you are not using the 
default path for the config file (./config.pl) you should use AnnoCPAN::Config
before any other modules. For example,

    use AnnoCPAN::Config 'my_other_config.pl';
    use AnnoCPAN::Update;

And not

    use AnnoCPAN::Update;  # this loads the default config file
    use AnnoCPAN::Config 'my_other_config.pl'; # WON'T WORK!!!

=head1 SEE ALSO

L<AnnoCPAN::DBI>, L<AnnoCPAN::Control>

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

1;

