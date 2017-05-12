package Beagle::Cmd::Command::mark;
use Beagle::Util;
use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

has import => (
    isa           => 'Str',
    is            => 'rw',
    accessor      => '_import',       # import sub is special in perl
    documentation => 'import path',
    traits        => ['Getopt'],
);

has export => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'export path',
    traits        => ['Getopt'],
);

has add => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    cmd_aliases   => 'a',
    documentation => 'add marks',
    traits        => ['Getopt'],
);

has set => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'set marks',
    traits        => ['Getopt'],
);

has delete => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    cmd_aliases   => 'd',
    documentation => 'delete marks',
    traits        => ['Getopt'],
);

has unset => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'delete marks',
    traits        => ['Getopt'],
);

has prune => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'prune orphans',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub command_names { qw/mark marks/ }

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $marks = marks;

    my $sub = 0;
    $sub++ if $self->_import;
    $sub++ if $self->export;
    $sub++ if $self->prune;

    die '--import, --export and --prune can not coexist with each other'
      if $sub > 1;

    die
'--import, --export or --prune can not coexist with --add, --delete, --set or --unset'
      if $sub && ( $self->add || $self->delete || $self->set || $self->unset );

    if ( $self->_import || $self->export ) {
        require JSON;
        my $path;
        if ( defined( $path = $self->export ) ) {
            my $converted = {};
            for my $id ( keys %$marks ) {
                if ( $marks->{$id} && %{ $marks->{$id} } ) {
                    $converted->{$id} = [ sort keys %{ $marks->{$id} } ];
                }
            }

            my $out = JSON::to_json( $converted, { utf8 => 1, pretty => 1 } );
            if ( $path ne '-' ) {
                write_file( $path, $out );
                puts 'exported.';
            }
            else {
                print $out;
            }
            return;
        }
        elsif ( defined( $path = $self->_import ) ) {
            my $in;
            if ( $path ne '-' ) {
                $in = decode( 'utf8', read_file($path) );
            }
            else {
                local $/;
                $in = decode( 'utf8' => <STDIN> );
            }
            my $converted = JSON::from_json($in);
            my $marks     = {};
            for my $id ( keys %$converted ) {
                if ( defined $converted->{$id} ) {
                    if ( ref $converted->{$id} ) {
                        if ( ref $converted->{$id} eq 'ARRAY' ) {
                            next unless @{ $converted->{$id} };
                            $marks->{$id} =
                              { map { $_ => 1 } @{ $converted->{$id} } };
                        }
                        elsif ( ref $converted->{$id} eq 'HASH' ) {
                            next unless %{ $converted->{$id} };
                            $marks->{$id} =
                              { map { $_ => 1 } keys %{ $converted->{$id} } };
                        }
                    }
                    else {
                        $marks->{$id} = { $converted->{$id} => 1 };
                    }
                }
            }
            set_marks($marks);
            puts 'imported.';
            return;
        }
    }
    elsif ( $self->prune ) {
        my $relation = relation();
        my $pruned;
        for my $id ( keys %$marks ) {
            next if $relation->{$id};
            delete $marks->{$id};
            $pruned = 1;
        }

        if ( $pruned ) {
            puts 'pruned.';
        }
        else {
            puts 'no orphans found.';
        }
        return;
    }
    else {

        my @ids;
        $args = $self->resolve_ids( $args );
        for my $i (@$args) {
            if ( length $i == 32 ) {
                push @ids, $i;
            }
            else {
                my @ret = resolve_entry( $i, handle => current_handle() || undef );
                unless (@ret) {
                    @ret = resolve_entry($i) or die_entry_not_found($i);
                }
                die_entry_ambiguous( $i, @ret ) unless @ret == 1;
                push @ids, $ret[0]->{id};
            }
        }

        if ( $self->add || $self->delete || $self->set || $self->unset ) {

            for my $id (@ids) {

                if ( $self->delete ) {
                    for my $mark ( @{ $self->delete } ) {
                        last unless $marks->{$id};
                        if ( exists $marks->{$id}{$mark} ) {
                            delete $marks->{$id}{$mark};
                        }
                        delete $marks->{$id} unless %{ $marks->{$id} };
                    }
                }

                if ( $self->unset ) {
                    if ( $marks->{$id} ) {
                        delete $marks->{$id};
                    }
                }

                if ( $self->set ) {
                    $marks->{$id} = {};
                    for my $mark ( @{ $self->set } ) {
                        $marks->{$id}{$mark} = 1;
                    }
                }

                if ( $self->add ) {
                    for my $mark ( @{ $self->add } ) {
                        if ( !$marks->{$id}{$mark} ) {
                            $marks->{$id}{$mark} = 1;
                        }
                    }
                }
            }

            if (@ids) {
                set_marks($marks);
                puts 'updated.';
            }
        }
        else {

            @ids = keys %$marks unless @ids;

            for my $id (@ids) {
                puts "$id ",
                  $marks->{$id}
                  ? ( join ', ', sort keys %{ $marks->{$id} } )
                  : '<not exist>';
            }
        }

    }
}

1;

__END__

=head1 NAME

Beagle::Cmd::Command::mark - manage entry marks

=head1 SYNOPSIS

    $ beagle mark                               # all the marks
    $ beagle marks                              # ditto
    $ beagle mark id1 id2                       # marks of id1 and id2
    $ beagle mark --set foo --set bar id1       # set "foo" and "bar" to id1
    $ beagle mark --unset id1                   # remove all marks of id1
    $ beagle mark --add foo --add bar id1       # add "foo" and "bar" to id1
    $ beagle mark --delete foo id1              # delete "foo" from id1
    $ beagle mark --prune                       # prune orphans

    $ beagle mark --import /path/to/foo.json
    $ beagle mark --export /path/to/foo.json

=head1 DESCRIPTION

C<marks> are stored in a file locally in kennel by default, so you can't expect
C<beagle push> could C<push> that too, that's why I added C<--export>/C<--import>
supports.

The file path can be customized via env C<BEAGLE_MARKS_PATH> or config
item C<marks_path>.

BTW, To make it available everywhere, you may want to store the file in places
like Dropbox, Ubuntu One, etc.

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

