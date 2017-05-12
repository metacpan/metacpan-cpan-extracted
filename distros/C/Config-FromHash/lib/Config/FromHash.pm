use strict;
use warnings;
use 5.10.1;

package Config::FromHash;

our $VERSION = '0.0800'; # VERSION
# ABSTRACT: Read config files containing hashes

use File::Basename();
use Hash::Merge();
use Path::Tiny;


sub new {
    my($class, %args) = @_;

    $args{'data'} ||= {};
    $args{'sep'}  ||= qr{/};
    $args{'require_all_files'} ||= 0;
    $args{'config_files'} = [];

    if(exists $args{'filename'} && exists $args{'filenames'}) {
        die "Don't use both 'filename' and 'filenames'.";
    }
    if(exists $args{'environment'} && exists $args{'environments'}) {
        die "Don't use both 'environment' and 'environments'.";
    }

    $args{'filenames'} = $args{'filename'} if exists $args{'filename'};
    $args{'environments'} = $args{'environment'} if exists $args{'environment'};


    if(exists $args{'filenames'}) {
        if(ref $args{'filenames'} ne 'ARRAY') {
            $args{'filenames'} = [ $args{'filenames'} ];
        }
    }
    else {
        $args{'filenames'} = [];
    }

    if(exists $args{'environments'}) {
        if(ref $args{'environments'} ne 'ARRAY') {
            $args{'environments'} = [ $args{'environments'} ];
        }
    }
    else {
        $args{'environments'} = [ undef ];
    }

    my $self = bless \%args => $class;

    Hash::Merge::set_behavior('LEFT_PRECEDENT');

    if(scalar @{ $args{'filenames'} }) {

        foreach my $environment (reverse @{ $args{'environments'} }) {

            FILE:
            foreach my $config_file (reverse @{ $args{'filenames'} }) {
                my($filename, $directory, $extension) = File::Basename::fileparse($config_file, qr{\.[^.]+$});
                my $new_filename = $directory . $filename . (defined $environment ? ".$environment" : '') . $extension;

                if(!-e $new_filename) {
                    die "$new_filename does not exist" if $self->require_all_files;
                    next FILE;
                }

                push @{ $args{'config_files'} } => $new_filename;
                $args{'data'} = Hash::Merge::merge($self->parse($new_filename, $args{'data'}));

            }
        }
    }

    return $self;

}

sub data {
    return shift->{'data'};
}

sub get {
    my $self = shift;
    my $path = shift;

    if(!defined $path) {
        warn "No path defined - nothing to return";
        return;
    }

    my @parts = split $self->{'sep'} => $path;
    my $hash = $self->{'data'};

    foreach my $part (@parts) {
        if(ref $hash eq 'HASH') {
            $hash = $hash->{ $part };
        }
        else {
            die "Can't resolve path '$path' to '$part'";
        }
    }
    return $hash;
}

sub config_files {
    my $self = shift;
    return @{ $self->{'config_files'} };
}

sub parse {
    my $self = shift;
    my $file = shift;

    my $contents = path($file)->slurp_utf8;
    my($parsed, $error) = $self->eval($contents);

    die "Can't parse <$file>: $error" if $error;
    die "<$file> doesn't contain hash" if ref $parsed ne 'HASH';

    return $parsed;

}

sub eval {
    my $self = shift;
    my $contents = shift;

    return (eval $contents, $@);
}

sub require_all_files {
    return shift->{'require_all_files'};
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Config::FromHash - Read config files containing hashes



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.10.1-brightgreen.svg" alt="Requires Perl 5.10.1" /> <a href="https://travis-ci.org/Csson/config-fromhash"><img src="https://api.travis-ci.org/Csson/config-fromhash.svg?branch=master" alt="Travis status" /></a></p>

=end HTML


=begin markdown

![Requires Perl 5.10.1](https://img.shields.io/badge/perl-5.10.1-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/config-fromhash.svg?branch=master)](https://travis-ci.org/Csson/config-fromhash)

=end markdown

=head1 VERSION

Version 0.0800, released 2015-10-27.

=head1 SYNOPSIS

    # in config file
    {
        thing => 'something',
        things => ['lots', 'of', 'things'],
        deep => {
            ocean => 'submarine',
        },
    }

    # somewhere else
    use Config::FromHash;

    my $config = Config::FromHash->new(filename => 'path/to/theconfig.conf', data => { deep => { ocean => 'thing' });

    # prints 'submarine'
    print $config->get('deep/ocean');

=head1 DESCRIPTION

Config::FromHash is yet another config file handler. This one reads config files that contain a Perl hash.

The following options are available

    my $config = Config::FromHash->new(
        filename => 'path/to/config.file',
        filenames => ['path/to/highest_priority_config.file', 'path/to/might_be_overwritten.file'],
        environment => 'production',
        environments => ['production', 'standard'],
        data => { default => { data => ['structure'] } },
        require_all_files => 1,
    );

B<C<data>>

Optional. If it exists its value is used as the default settings and will be overwritten if the same setting exists in a config file.

B<C<filename> or C<filenames>>

Optional. C<filenames> is an alias for C<filename>. It reads better to use C<filenames> if you have many config files.

Files are parsed left to right. That is, as soon as a setting is found in a file (while reading left to right) that setting
is not overwritten.

B<C<environment> or C<environments>>

Optional. C<environments> is an alias for C<environment> It reads better to use C<environment> if you have many environments.

If this is set its value is inserted into all config file names, just before the final dot.

Environments are read left to right. All files from each environment is read before moving on to the next environment. See Examples below.

An environment can be C<undef>.

B<C<require_all_files>>

Default: C<0>

If set to a true value Config::FromHash will C<die> if any config file doesn't exist. Otherwise it will silently skip such files.

B<C<sep>>

Default: C<qr{/}>

The separator used to split the argument to C<get()>:

    my $config = Config::FromHash->new(sep => qr{\.}, data => { some => { nested => { data => { is => 'deep' }}}});

    # prints 'deep'
    print $config->get('some.nested.data.is');

=head1 METHODS

B<C<$self-E<gt>get($path)>>

Returns the value that exists at C<$path>. C<$path> is translated into hash keys, and is separated by C</>.

B<C<$self-E<gt>data>>

Returns the entire hash B<after> all config files have been read.

B<C<$self-E<gt>config_files>>

Returns a list of parsed config files. Mostly useful as a debuging tool, especially if C<require_all_files> is false, and the contents of C<$self-E<gt>data> doesn't match expectations.

=head1 EXAMPLES

     my $config = Config::FromHash->new(
        filename => '/path/to/config.file',
        data => { some => 'setting' },
    };

Will read

    /path/to/config.file

And any setting that exists in C<data> that has not yet been set will be set.

    my $config = Config::FromHash->new(
        filenames => ['/path/to/highest_priority_config.file', '/path/to/might_be_overwritten.file'],
        environments => ['production', 'standard', undef],
        data => { default => { data => ['structure'] } },
    );

The following files are read (with decreasing priority)

    /path/to/highest_priority_config.production.file
    /path/to/might_be_overwritten.production.file
    /path/to/highest_priority_config.standard.file
    /path/to/might_be_overwritten.standard.file
    /path/to/highest_priority_config.file
    /path/to/might_be_overwritten.file

And then any setting that exists in C<data> that has not yet been set will be set.

    my $config->new(data => { hello => 'world', can => { find => ['array', 'refs'] });

    # $hash becomes { hello => 'world', can => { find => ['array', 'refs'] }
    my $hash = $config->data;

    # prints 'refs';
    print $config->get('can/find')->[1];

=head1 SOURCE

L<https://github.com/Csson/config-fromhash>

=head1 HOMEPAGE

L<https://metacpan.org/release/Config-FromHash>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson <info@code301.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
