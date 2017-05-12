package CGI::FormBuilder::Source::Perl;

use strict;
use warnings;

our $VERSION = '0.01';

use File::Slurp;

=head1 NAME

CGI::FormBuilder::Source::Perl - read FormBuilder config from Perl syntax files

=head1 SYNOPSIS

    my $form = CGI::FormBuilder->new(
        source => {
            type   => 'Perl',
            source => '/path/to/form_config.pl',
        }
    );

=head1 DESCRIPTION

This module allows you to specify the config for a L<CGI::FormBuilder> object
using Perl syntax. The contents of the config file will be C<eval>ed and the
hash ref returned will be used as the config for the object.

=cut

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %opt   = @_;
    return bless \%opt, $class;
}

sub parse {
    my $self = shift;
    my $file = shift || $self->{source};

    my $content = read_file($file);
    my $config  = eval $content;
    die "ERROR in C:FB:Source::Perl config file '$file': $@" if $@;

    # FIXME - add caching and smarter checking

    return wantarray ? %$config : $config;
}

=head1 SEE ALSO

L<CGI::FormBuilder>, L<CGI::FormBuilder::Source::File>,

=head1 AUTHOR

Copyright (c) 2008 Edmund von der Burg <evdb@ecclestoad.co.uk>. All Rights
Reserved.

Based on the module L<CGI::FormBuilder::Source>

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut

1;
