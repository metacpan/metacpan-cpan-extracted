#
# This file is part of App-Cme
#
# This software is Copyright (c) 2014-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# ABSTRACT: Edit the configuration of an application with fuse

package App::Cme::Command::fusefs ;
$App::Cme::Command::fusefs::VERSION = '1.034';
use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

use Config::Model::ObjTreeScanner;

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->check_unknown_args($args);
    $self->process_args($opt,$args);

    my $has_fuse = eval { require Config::Model::FuseUI; 1; };

    die "could not load Config::Model::FuseUI. Is Fuse installed ?\n"
        unless $has_fuse;

    my $fd = $opt->{fuse_dir};
    die "Directory $fd does not exists\n" unless -d $fd;

    return;
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        [
            "fuse-dir=s" =>  "Directory where the virtual file system will be mounted",
            {required => 1}
        ],
        [ "dfuse!"     => "debug fuse problems" ],
        [ "dir-char=s" => "string to replace '/' in configuration parameter names"],
        [ "backup:s"  => "Create a backup of configuration files before saving." ],
        $class->cme_global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application] [file ] -fuse-dir xxx [ -dir-char x ] ";
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    my @extra;
    if (my $dc = $opt->{dir_char}) {
        push @extra, dir_char_mockup => $dc;
    }

    my $fuse_dir = $opt->{fuse_dir};
    print "Mounting config on $fuse_dir in background.\n",
        "Use command 'fusermount -u $fuse_dir' to unmount\n";

    my $ui = Config::Model::FuseUI->new(
        root       => $root,
        mountpoint => $fuse_dir,
        @extra,
    );


    # now fork
    my $pid = fork;

    if ( defined $pid and $pid == 0 ) {
        # child process, just run fuse and wait for exit
        $ui->run_loop( debug => $opt->{fuse_debug} );
        $self->save($inst,$opt);
    }

    # parent process simply exits
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cme::Command::fusefs - Edit the configuration of an application with fuse

=head1 VERSION

version 1.034

=head1 SYNOPSIS

=head1 DESCRIPTION

Map the configuration file content to a FUSE virtual file system on a
directory specified with option C<-fuse-dir>.  Modifications done in
the fuse file system are saved to the configuration file when
C<< fusermount -u <mounted_fuse_dir> >> is run.

=head1 Common options

See L<cme/"Global Options">.

=head1 options

=over

=item -fuse-dir

Mandatory. Directory where the virtual file system will be mounted.

=item -dfuse

Use this option to debug fuse problems.

=item -dir-char

Fuse will fail if an element name or key name contains '/'. You can specify a
substitution string to replace '/' in the fused dir. Default is C<< <slash> >>.

=back

=head1 SEE ALSO

L<cme>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2021 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
