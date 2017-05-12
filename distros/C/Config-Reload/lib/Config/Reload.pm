package Config::Reload;
{
  $Config::Reload::VERSION = '0.21';
}
#ABSTRACT: Load config files, reload when files changed.

use v5.10;
use strict;

use Config::ZOMG '1.000000';

use Moo;
use Sub::Quote 'quote_sub';
use Digest::MD5 qw(md5_hex);
use Try::Tiny;

use parent 'Exporter';
our @EXPORT_OK = qw(files_hash);


has wait    => (
    is      => 'rw',
    default => quote_sub q{ 60 },
);


has checked => ( is => 'rw' );
has loaded  => ( is => 'rw' );
has error   => ( is => 'rw' );

has _md5    => ( is => 'rw' ); # caches $self->md5($self->found)
has _zomg   => ( is => 'rw', handles => [qw(find found)] );
has _config => ( is => 'rw' );

sub BUILD {
    my ($self, $given) = @_;

    # don't pass to Config::ZOMG
    delete $given->{$_} for qw(wait error checked);

    $self->_zomg( Config::ZOMG->new($given) );
}

sub load {
    my $self = shift;
    my $zomg = $self->_zomg;

    if ($self->_config) {
        if (time < $self->checked + $self->wait) {
            return $self->_config;
        }
        if ($self->_md5 eq files_hash( $zomg->find )) {
            $self->checked(time);
            return $self->_config;
        } else {
            $self->_config(undef);
        }
    }

    $self->checked(time);

    try {
        $self->error(undef);
        $self->_config( $zomg->reload ); # may die on error
        $self->loaded(time);
        $self->_md5( files_hash( $self->found ) );
    } catch {
        $self->error($_);
        $self->loaded(undef);
        $self->_md5( files_hash() );
        $self->_config( { } );
    };

    return $self->_config;
}


sub files_hash {
    md5_hex( map { my @s = stat($_); ($_, $s[9], $s[7]) } sort @_ );
}


1;

__END__

=pod

=head1 NAME

Config::Reload - Load config files, reload when files changed.

=head1 VERSION

version 0.21

=head1 SYNOPSIS

    my $config = Config::Reload->new(
        wait => 60,     # check at most every minute (default)
        ...             # passed to Config::ZOMG, e.g. file => $filename
    );

    my $config = $config->load;

    sleep(60);

    $config = $config->load;   # reloaded

=head1 DESCRIPTION

This Perl package loads config files via L<Config::ZOMG> which is based on
L<Config::Any>. Configuration is reloaded on file changes (based on file names
and last modification time).

This package is highly experimental and not fully covered by unit tests!

=head1 METHODS

=head2 new

Returns a new C<Config::Reload> object.  All arguments but C<wait>, C<error>
and C<checked> are passed to the constructor of L<Config::ZOMG>.

=head2 load

Get the configuration, possibly (re)loading configuration files. Always returns
a hash reference, on error this C< { } >.

=head2 wait

Get or set the number of seconds to wait between checking. Set to 60 (one
minute) by default.

=head2 checked

Returns a timestamp of last time files had been checked.

=head2 loaded

Returns a timestamp of last time files had been loaded. Returns C<undef> before
first loading and on error.

=head2 found

Returns a list of files that configuration has been loaded from.

=head2 find

Returns a list of files that configuration will be loaded from on next check.
Files will be reloaded only if C<files_hash> value of of C<find> differs from
the value of C<found>:

    use Config::Reload qw(files_hash);

    files_hash( $config->find ) ne files_hash( $config->found )

=head2 error

Returns an error message if loading failed. As long as an error is set, the
C<load> method returns an empty hash reference until the next attempt to reload
(typically the time span defind with C<wait>).  One can manually unset the
error with C<< $c->error(undef) >> to force reloading.

=head1 FUNCTIONS

=head2 files_hash( @files )

Returns a hexadecimal MD5 value based on names, -sizes and modification times
of a list of files. Internally used to compare C<find> and C<found>.

This function can be exported on request.

=encoding utf8

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
