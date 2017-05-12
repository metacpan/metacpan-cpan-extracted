package Beagle::Cmd::Command::init;
use Beagle::Util;

use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

has bare => (
    isa           => 'Bool',
    is            => 'rw',
    cmd_aliases   => 'b',
    documentation => 'bare git repo',
    traits        => ['Getopt'],
);

has force => (
    isa           => 'Bool',
    is            => 'rw',
    cmd_aliases   => 'f',
    documentation => 'remove the path if it exists already',
    traits        => ['Getopt'],
);

has type => (
    isa           => 'BeagleBackendType',
    is            => 'rw',
    documentation => 'type of the backend',
    traits        => ['Getopt'],
);

has name => (
    isa           => 'Str',
    is            => 'rw',
    cmd_aliases   => 'n',
    documentation => 'beagle name, will create it in $BEAGLE_KENNEL/roots directly',
    traits        => ['Getopt'],
);

has 'edit' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'use editor',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub command_names { qw/init initialize/ }

sub execute {
    my ( $self, $opt, $args ) = @_;

    die "can't specify --bare with --name" if $self->name && $self->bare;
    die "can't specify --root with --name"   if $self->name && @$args;
    die "need root" unless @$args || $self->name;

    my $type = $self->type;
    require File::Which;
    if ($type) {

        if ( $type eq 'git' && !File::Which::which('git') ) {
            die "no git found";
        }
    }
    else {
        if ( File::Which::which('git') ) {
            $type = 'git';
        }
        else {
            warn 'no git found, back to fs';
            $type = 'fs';
        }
    }

    die "name can't contain colon on windows"
      if is_windows() && $self->name && $self->name =~ /:/;

    my $root =
      rel2abs( $args->[0]
          || catdir( backends_root(), split /\//, $self->name ) );

    if ($root) {
        if ( -e $root ) {
            if ( $self->force ) {
                remove_tree($root);
            }
            else {
                die "$root already exists, use --force|-f to override";
            }
        }
    }
    make_path( encode( locale_fs => $root ) ) or die "failed to create $root";

    my $info;
    if ( $self->edit ) {
        require Beagle::Model::Info;
        my $template = encode_utf8 Beagle::Model::Info->new()->serialize;
        my $updated = edit_text($template);
        $info = Beagle::Model::Info->new_from_string( decode_utf8 $updated);
    }

    # $opt->{name} is not user name but beagle name
    create_backend(
        %$opt,
        type => $type,
        root => $root,
        info => $info,
        name => undef
    );

    if ( $self->name ) {
        my $all = roots();

        $all->{$self->name} = {
            local => $root,
            type  => $self->type,
        };

        set_roots($all);
        puts "initialized."
    }
    else {
        puts
"initialized, please run `beagle follow $root --type $type` to continue.";
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::init - initialize a beagle

=head1 SYNOPSIS

    $ beagle init --name foo          # create an internal beagle in the kennel
    $ beagle init /path/to/foo.git --bare

=head1 DESCRIPTION

Usually, you want to create an external git repo and then C<follow> it, using
C<--name> will create an internal git repo and you won't be able to C<push>
and C<pull> easily.

We support plain file system as backend via C<--type fs>, you don't want to do
this usually as it doesn't support version control at all.

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

