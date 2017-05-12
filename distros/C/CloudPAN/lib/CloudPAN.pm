package CloudPAN;
{
  $CloudPAN::VERSION = '1.131740';
}

#ABSTRACT: Never install pure Perl modules again

use warnings;
use strict;
use File::Spec;
use MetaCPAN::API::Tiny;
use Symbol;
use File::Temp;
use File::Path;

our $options = {};

sub import
{
    my ($pkg, $opt) = @_;
    return unless $opt;
    die 'Options hash passed to CloudPAN for configuration needs to be a HashRef'
        unless ref($opt) eq 'HASH';

    if(exists($opt->{persistence_location}))
    {
        my $loc = $opt->{persistence_location};

        File::Path::make_path($loc, {error => \my $err});

        if(@$err)
        {
            die '"persistence_location" must be a directory, readable, and writable by your effective uid/gid';
        }
        
        $options->{location} = $loc;
    }
    else
    {
        die 'Options hash must have "persistence_location" defined';
    }
}

sub fetch_from_metacpan
{
    my ($name) = @_;
    
    my $api = MetaCPAN::API::Tiny->new();

    my $content;

    eval
    {
        my $ret = $api->fetch('module/_search', q => qq|path:lib/$name AND status:latest|, size => 1, fields => 'author,release,path');
        
        die 'NoFetch'
            unless $ret &&
            exists($ret->{hits}) &&
            exists($ret->{hits}->{hits}) &&
            ref($ret->{hits}->{hits}) eq 'ARRAY' &&
            scalar(@{$ret->{hits}->{hits}}) &&
            exists($ret->{hits}->{hits}->[0]->{fields}) &&
            exists($ret->{hits}->{hits}->[0]->{fields}->{author}) &&
            exists($ret->{hits}->{hits}->[0]->{fields}->{release}) &&
            exists($ret->{hits}->{hits}->[0]->{fields}->{path});

        my $fields = $ret->{hits}->{hits}->[0]->{fields};

        my $req_url = join('/', $api->{base_url}, 'source', @{$fields}{qw/author release path/});
        
        my $response = $api->{ua}->get($req_url);
        
        die 'HTTP'
            unless $response->{success} &&
            length $response->{content};
        
        $content = $response->{content};
    }
    or do
    {
        if("$@" eq 'NoFetch')
        {
            die "MetaCPAN does not seem to know about your module: $name";
        }
        elsif("$@" eq 'HTTP')
        {
            die "There was a problem attempting to fetch the module contents from MetaCPAN for module: $name";
        }
    };

    return \$content;
}

BEGIN {

    push(@INC, sub {
        my ($self, $name) = @_;

        if (exists($options->{location}))
        {
            my $path = File::Spec->rel2abs($name, $options->{location});
            if (-e $path)
            {
                open(my $fh, '<', $path)
                    or die "Unable to open cached copy of module located at $path";

                return $fh;
            }
            else
            {
                my ($volume, $dir, $file) = File::Spec->splitpath($path);
                my $to_create_dir = File::Spec->catpath($volume, $dir, '');
                
                File::Path::make_path($to_create_dir, {error => \my $err});

                if(@$err)
                {
                    die "Failed to create necessary path within persistence_location: $to_create_dir";
                }

                my $content_ref = fetch_from_metacpan($name);
                open(my $fh, '+>', $path)
                    or die "Unable to write cached copy of module located at $path";

                print $fh $$content_ref;
                seek($fh, 0, 0);
                return $fh;
            }
        }
        else
        {
            my $content_ref = fetch_from_metacpan($name);
            my $fh = File::Temp::tempfile(UNLINK => 1);
            print $fh $$content_ref;
            seek($fh, 0, 0);
            return $fh;
        }
    });
}

1;

__END__

=pod

=head1 NAME

CloudPAN - Never install pure Perl modules again

=head1 VERSION

version 1.131740

=head1 SYNOPSIS

    use CloudPAN;
    
    {
        package Foo;
        use Moo;

        has bar => (is => 'rw');
        
        sub baz { $_[0]->bar }
    }
    print Foo->new(bar => 3)->baz . "\n";
    
    # 3

    ...

    # Or if you want to persist what you've downloaded:

    use CloudPAN { persistence_location => '/home/nicholas/cloudpan' };

=head1 DESCRIPTION

Ever wanted to load modules from the "cloud"? Love the concept of MetaCPAN and
want to exercise it? Then this module is for you. Simply use this module before
using any other module that doesn't require compilation (ie. XS modules) and
you're set. Note that this doesn't work on all modules (especially ones that
mess around with @INC too).

=head1 CLASS_METHODS

=head2 import

    (HashRef)

import takes a HashRef of options.

CloudPAN can either use temp files created with File::Temp, or it can persist
what you have previously downloaded from MetaCPAN. To enable persistence, pass
it the option 'persistence_location' with an absolute path to the directory
you'd like CloudPAN to store things.

=head1 CAVEATS

There is no real authentication that happens when accessing MetaCPAN. Someone could easily Man-In-The-Middle your connection and feed you bogus code to run. Seriously, don't use this in production code.

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
