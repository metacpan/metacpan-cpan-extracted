package Beagle::Wrapper::git;
use Beagle::Util;
use Any::Moose;
has 'root' => (
    isa     => 'Str',
    is      => 'rw',
    trigger => sub {
        my $self  = shift;
        my $value = shift;
        $self->encoded_root( encode( locale_fs => $value ) );
    },
);

has 'encoded_root' => (
    isa => 'Str',
    is  => 'rw',
);

has 'verbose' => (
    isa     => 'Bool',
    is      => 'rw',
    default => 0,
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

our $AUTOLOAD;

sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.+:://;
    return if $method eq 'DESTROY';
    $method =~ s!_!-!g;

    return $self->_run( $method, @_ );
}

sub has_changes_indexed {
    my $self   = shift;
    my $status = $self->status;
    return $status =~ qr/changes to be committed/i;
}

sub has_changes_unindexed {
    my $self   = shift;
    my $status = $self->status;
    return $status =~ qr/changed but not updated/i;
}

sub _run {
    my $self = shift;
    my ( $out, $err ) = ('') x 2;

    require Cwd;
    my $cwd = Cwd::getcwd();
    chdir $self->encoded_root if $self->encoded_root;

    require IO::Handle;
    my $stdout = IO::Handle->new;
    $stdout->fdopen( 1, 'w' );
    local *STDOUT = $stdout;

    my $stderr = IO::Handle->new;
    $stderr->fdopen( 2, 'w' );
    local *STDERR = $stderr;

    my $is_message;
    my @args;
    for my $item (@_) {
        if ($is_message) {
            push @args, encode_utf8 $item;
            $is_message = 0;
        }
        elsif ( $item eq '-m' || $item eq '--message' ) {
            $is_message = 1;
            push @args, $item;
        }
        else {
            push @args, encode( locale => $item );
        }
    }

    unshift @args, $ENV{BEAGLE_GIT_PATH} || 'git';
    require IPC::Run3;
    if ( $self->verbose ) {
        IPC::Run3::run3( [@args], undef );
    }
    else {
        IPC::Run3::run3( [@args], undef, \$out, \$err );
    }

    my $ret;
    if ($?) {

        # verbose already shows the err
        warn qq{failed to run "@args": exit code is }
          . ( $? >> 8 )
          . ", err is $err\n"
          unless $self->verbose;
    }
    else {
        $ret = 1;
    }
    $out = length $out ? $out : $err;

    $out = '' unless defined $out;
    $err = '' unless defined $err;

    chdir $cwd;
    return wantarray ? ( $ret, $out, $err ) : $out;
}

1;

__END__


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

