package Beagle::Cmd::Command::config;
use Beagle::Util;
use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

has force => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'force',
    cmd_aliases   => 'f',
    traits        => ['Getopt'],
);

has init => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'initialize config items',
    traits        => ['Getopt'],
);

has set => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'set config items',
    traits        => ['Getopt'],
);

has unset => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'delete config items',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub command_names { qw/config configs/ }

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $core = core_config();

    if ( $self->init ) {
        if ( keys %$core && !$self->force ) {
            die
              "default is initialized already, use --force|-f to overwrite.";
        }

        $core->{"default_command"} = 'shell';
        $core->{'cache'}           = 1;
        $core->{'devel'}           = 0;
        $core->{'web_admin'}       = 0;

        if ( $self->set ) {
            for my $item ( @{ $self->set } ) {
                my ( $name, $value ) = split /=/, $item, 2;
                $core->{$name} = $value;
            }
        }

        if ( $self->unset ) {
            for my $key ( @{ $self->unset } ) {
                delete $core->{$key};
            }
        }

        for my $key (qw/name email/) {
            next if $core->{"user_$key"};
            print "user $key: ";
            chomp( my $val = <STDIN> );
            $core->{"user_$key"} = $val;
        }

        set_core_config($core);

        # check if there are roots already
        my $old = detect_roots();
        set_roots($old);

        my $share = share_root();
        puts "initialized.";
        return if is_windows();
        puts
qq{to be more efficient, add "source $share/etc/bashrc" to your .bashrc.};
        puts
qq{if you use bash-completion, add "source $share/etc/completion.bashrc" to your .bashrc.};
        return;
    }
    elsif ( $self->set || $self->unset ) {
        my $updated;
        my @set;
        my @unset;
        if ( $self->set ) {
            for my $item ( @{ $self->set } ) {
                my ( $name, $value ) = split /=/, $item, 2;
                $core->{$name} = $value;
                push @set, $name;
            }
        }

        if ( $self->unset ) {
            for my $name ( @{ $self->unset } ) {
                delete $core->{$name};
                push @unset, $name;
            }
        }

        set_core_config($core) if @set || @unset;

        if (@set) {
            puts 'set ', join( ', ', @set ) . '.';
        }
        if (@unset) {
            puts 'unset ', join( ', ', @unset ) . '.';
        }
        return;
    }
    else {
        if (@$args) {
            for my $key (@$args) {
                if ( exists $core->{$key} ) {
                    my $value = $core->{$key};
                    $value = '' unless defined $value;
                    puts "$key: $value";
                }
                else {
                    puts "$key: <not exist>";
                }
            }
        }
        else {
            for my $key ( sort keys %$core ) {
                my $value = $core->{$key};
                $value = '' unless defined $value;
                puts "$key: $value";
            }
        }
    }
}

1;

__END__

=head1 NAME

Beagle::Cmd::Command::config - configure beagle

=head1 SYNOPSIS

    $ beagle config         # show all the configs
    $ beagle configs        # ditto
    $ beagle config --init
    $ beagle config --set cache=1 --set user_name=lisa
    $ beagle config cache user_name
    $ beagle config --unset cache --unset user_name

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

