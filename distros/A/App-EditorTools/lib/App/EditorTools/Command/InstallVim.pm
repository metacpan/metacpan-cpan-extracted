package App::EditorTools::Command::InstallVim;

# ABSTRACT: Installs vim bindings for App::EditorTools

use strict;
use warnings;
use parent 'App::EditorTools::CommandBase::Install';

#use App::EditorTools -command;
use File::HomeDir;
# use IPC::Cmd qw(run);

our $VERSION = '1.00';

sub command_names { 'install-vim' }

sub opt_spec {
    return (
        [ "local|l",  "Install the vim script local for the user (~/.vim/)" ],
        [ "dest|d=s", "Full path to install the vim script" ],
        [ "print|p",  "Print the vim script to STDOUT" ],
        [ "dryrun|n", "Print where the vim script would be installed" ],
        ## [ "global|g", "Install the vim script globally (/usr/share/vim)" ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->_confirm_one_opt($opt)
      or $self->usage_error(
        "Options --local, --global, --dest and --print cannot be combined");

    if ( !$opt->{dest} ) {
        if ( $opt->{global} ) {
            $self->usage_error("--global flag is not implemented");
            # $opt->{dest} = File::Spec->catfile( $self->_get_vimruntime,
            #     qw(ftplugin perl editortools.vim) );

        } elsif ( !$opt->{print} ) {
            $opt->{dest} = File::Spec->catfile(
                File::HomeDir->my_home,
                ( $^O eq 'MSWin32' ? 'vimfiles' : '.vim' ),
                qw(ftplugin perl editortools.vim)
            );
        }
    }

    return 1;
}

sub _script { File::Spec->catfile(qw(vim editortools.vim)) }

sub _intro {
    return <<"END_INTRO";
" App::EditorTools::Command::InstallVim generated script
" Version: $VERSION
END_INTRO
}

# sub _get_vimruntime {
#     my $self = shift;
#
#     my $file = 'appeditvim.tmp';
#     my $cmd  = qq{vim -c 'redir > $file' -c 'echomsg \$VIMRUNTIME' -c q};
#
#     run( command => $cmd, verbose => 0, )
#       or $self->usage_error("Error running vim to find global path");
#     my $dest = read_file $file
#       or $self->usage_error("Unable to find global vim path");
#     unlink $file;
#
#     $dest =~ s{[\n\r]}{}mg;
#     return $dest;
# }

# Pod if we add the global option
# =item --global
# Install the vim script globally. This will put the script in
# C</usr/share/vim/vim72/ftplugin/perl/editortools.vim> or a similar location
# for your operating system.


1;

__END__

=pod

=head1 NAME

App::EditorTools::Command::InstallVim - Installs vim bindings for App::EditorTools

=head1 VERSION

version 1.00

=head1 SYNOPSIS

    # Install the vim script to create binding to App::EditorTools with:
    editortools install-vim

=head1 DESCRIPTION

This will place the vim script contained in the share dir of this distribution
where vim expects it ( C<$HOME/.vim/ftplugin/perl/editortools.vim> for a local
install on a unix-like system)>).

=head1 OPTIONS

=over 4

=item --local

Install the vim script for the local user only. This will put the script in
C<$HOME/.vim/ftplugin/perl/editortools.vim> or a similar location for your
operating system. This is the default action.

=item --dest

Specify a full path (directory and filename) for the vim script.

=item --print

Print the vim script to STDOUT.

=item --dryrun

Don't do anything, just print what we would do.

=back

=head1 SEE ALSO

Also see L<PPIx::EditorTools>, L<Padre>, and L<PPI>.

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
