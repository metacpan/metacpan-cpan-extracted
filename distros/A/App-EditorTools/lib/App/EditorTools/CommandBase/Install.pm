package App::EditorTools::CommandBase::Install;

# ABSTRACT: Base class for installing bindings for editors

use strict;
use warnings;

use File::Basename;
use File::Path qw(mkpath);
use File::Slurp;
use File::ShareDir qw(dist_file);
use App::Cmd::Setup -command;

our $VERSION = '1.00';

sub execute {
    my ( $self, $opt, $arg ) = @_;

    print STDERR "Installing script to:\n";
    print STDERR $opt->{dest} || 'STDOUT';
    print STDERR "\n";

    return if $opt->{dryrun};

    if ( $opt->{dest} ) {
        $self->_mkdir( $opt->{dest} );

        # TODO: overwriting?
        open my $fh, ">", $opt->{dest}
          or die "Unable to write to $opt->{dest}: $!";
        $opt->{dest} = $fh;
    }

    $self->_print( $opt->{dest} || *STDOUT );
    return;
}

sub _print {
    my ( $self, $fh ) = @_;

    return print $fh $self->_get_script( $self->_script );
}

sub _get_script {
    my ( $self, $script ) = @_;

    my $file = File::Spec->catfile( dirname( $INC{'App/EditorTools.pm'} ),
            qw( .. .. share ), $script );

    $file = dist_file( 'App-EditorTools', $script )
        unless -r $file;

    return $self->_intro . read_file($file);
}

sub _mkdir {
    my ( $self, $path ) = @_;

    my $dir = dirname $path;

    unless ( -d $dir ) {
        mkpath($dir)
          || die "Unable to create directory $dir: $!\n";
    }

    return 1;
}

sub _count {
    my (@a) = @_;

    my $total = 0;
    for my $a (@a) {
        $total += 1 if defined $a;
    }

    return $total;
}

sub _confirm_one_opt {
    my ( $self, $opt ) = @_;

    my %hash = %$opt;
    return grep( { defined $_ } @hash{qw{dest local global print}} ) <= 1;
}

1;

__END__

=pod

=head1 NAME

App::EditorTools::CommandBase::Install - Base class for installing bindings for editors

=head1 VERSION

version 1.00

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
