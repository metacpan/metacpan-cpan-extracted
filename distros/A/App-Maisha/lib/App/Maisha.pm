package App::Maisha;

use strict;
use warnings;

our $VERSION = '0.21';

#----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

App::Maisha - A command line social micro-blog networking tool.

=head1 SYNOPSIS

  use App::Maisha;
  my $maisha   = App::Maisha->new(config => $file)->run;

=head1 DESCRIPTION

This distribution provides the ability to micro-blog via social networking
websites and services, such as Identica and Twitter.

For further information regarding the commands and configuration, please see
the 'maisha' script included with this distribution.

=cut

#----------------------------------------------------------------------------
# Library Modules

use base qw(Class::Accessor::Fast);

use Carp qw(croak);
use Config::Any;
use App::Maisha::Shell;
use File::Basename;
use File::HomeDir;

#----------------------------------------------------------------------------
# Accessors

__PACKAGE__->mk_accessors($_) for qw(shell config);

#----------------------------------------------------------------------------
# Public API

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();
    my $config = $self->load_config(@_);
    $self->config($config);
    $self->setup();
    $self;
}

sub load_config {
    my ($self,%hash) = @_;
    my $config = $hash{config};

    if ($config && ! ref $config) {
        my $filename = $config;
        # In the future, we may support multiple configs, but for now
        # just load a single file via Config::Any
        my $list = Config::Any->load_files( { files => [ $filename ], use_ext => 1 } );
        ($config) = $list->[0]->{$filename};
    }

    croak("Could not load configuration file")  if(!$config);
    croak("Maisha expectes a config file that can be decoded to a HASH")    if(ref $config ne 'HASH');

    # some systems use a broken pager, so force the internal parser to be used
    $self->{pager} = $ENV{PAGER};
    $ENV{PAGER} = '';

    return $config;
}

sub setup {
    my $self   = shift;
    my $config = $self->config;
    my $shell  = $self->shell(App::Maisha::Shell->new);

    my $debug   = $config->{CONFIG}{debug}   || 0;
    my $history = $config->{CONFIG}{history} || '';

    my $tag = $config->{CONFIG}{tag};
    $tag ||= '[from maisha]';
    $tag   = '' if($tag eq '.');

    my $prompt = $config->{CONFIG}{prompt};
    $prompt ||= 'maisha>';
    $prompt =~ s/\s*$/ /;


    $shell->debug($debug);
    $shell->history($history);
    $shell->prompt_str($prompt);
    $shell->tag_str($tag);
    $shell->pager( defined $config->{CONFIG}{pager}  ? $config->{CONFIG}{pager}  : 1 );
    $shell->order( defined $config->{CONFIG}{order}  ? $config->{CONFIG}{order}  : 'descending');
    $shell->limit( defined $config->{CONFIG}{limit}  ? $config->{CONFIG}{limit}  : 0);
    $shell->chars( defined $config->{CONFIG}{chars}  ? $config->{CONFIG}{chars}  : 80);
    $shell->format(defined $config->{CONFIG}{format} ? $config->{CONFIG}{format} : '[%U] %M');

    my $home = File::HomeDir->my_home();

    # connect to the available sites
    for my $plugin (keys %$config) {
        next    if($plugin eq 'CONFIG');
        $config->{$plugin}{home} = $home;
        $self->shell->connect($plugin,$config->{$plugin});
    }

    # in some environments 'Wide Character' warnings are emited where unicode
    # strings are seen in status messages. This suppresses them.
    binmode STDOUT, ":encoding(UTF-8)";
}

sub run {
    my $self  = shift;
    my $shell = $self->shell;
    $shell->postcmd();
    $shell->cmdloop();

    $ENV{PAGER} = $self->{pager};
}

1;

__END__

=head1 METHODS

=head2 Constructor

=over 4

=item * new

=back

=head2 Process Methods

=over 4

=item * load_config

Loads the configuration file. See the 'maisha' script to see a fuller
description of the configuration options.

=item * setup

Prepares the interface and internal environment.

=item * run

Starts the command loop shell, and awaits your command.

=back

=head1 WEBSITES

=over 4

=item * Main Site: L<http://maisha.grango.org>

=item * Git Repo:  L<http://github.com/barbie/maisha/tree/master>

=item * RT Queue:  L<RT: http://rt.cpan.org/Public/Dist/Display.html?Name=App-Maisha>

=back

=head1 THANKS TO

My thanks go to the following people for suggestions and help when putting this
application together.

Dave Cross, Robert Rothenberg and Steffen Müller.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2014 by Barbie

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
