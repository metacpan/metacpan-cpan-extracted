package CGI::Application::Plugin::Cache::File;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Cache::File;

require Exporter;

@ISA       = qw(Exporter AutoLoader);
@EXPORT    = qw(cache_config cache);
@EXPORT_OK = qw();

$VERSION = '0.4';

sub cache {
    my $self = shift;
    return ($self->{__CACHE_FILE_OBJ} or die "No Cache::File object available - did you run cache_config()?\n");
}

sub cache_config {
    my $self = shift;
    return ($self->{__CACHE_FILE_OBJ} = Cache::File->new( @_ ) or die "There was a problem creating a Cache::File instance: $!\n");
}

1;

__END__

=head1 NAME

CGI::Application::Plugin::Cache::File - Caching support using L<Cache::File>

=head1 SYNOPSIS

    use CGI::Application::Plugin::Cache::File;

    #in sub cgiapp_init

    $self->cache_config(
        cache_root      => '/tmp/cache',
        default_expires => '600 seconds'
    );

    #in some runmode

    $self->cache->set('foo','bar');
    my $cached = $self->cache->get('foo');

=head1 DESCRIPTION

CGI::Application::Plugin::Cache::File makes it easy to use cached data and be able to
share it with different processes.

=head1 METHODS

=head2 cache_config

This creates the Cache::File instance within CGI::Application. Any arguments are passed on to
Cache::File's constructor method. See L<Cache::File#PROPERTIES> for details.

If successful, this function returns the Cache::File instance created.

=head2 cache

This returns the Cache::File instance within CGI::Application. You can call
any Cache::File instance method on it. See L<Cache::File> for details.

=head1 SEE ALSO

L<CGI::Application>, L<Cache::File>, perl(1)

=head1 AUTHOR

Job van Achterberg <jkva@cpan.org>

=head1 LICENSE

Copyright (C) 2009 Job van Achterberg <jkva@cpan.org>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

