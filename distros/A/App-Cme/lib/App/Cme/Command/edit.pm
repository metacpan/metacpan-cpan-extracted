#
# This file is part of App-Cme
#
# This software is Copyright (c) 2014-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# ABSTRACT: Edit the configuration of an application

package App::Cme::Command::edit ;
$App::Cme::Command::edit::VERSION = '1.034';
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
    return;
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        [ "ui|if=s"     => "user interface type. Either tk, curses, shell" ],
        [ "backup:s"  => "Create a backup of configuration files before saving." ],
        [ "open-item=s" => "open a specific item of the configuration" ],
        $class->cme_global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application] [ file ] [ -ui tk|curses|shell ] [ -open-item xxx ] ";
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}
sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    my $has_tk =  eval { require Config::Model::TkUI; 1; };

    my $has_curses = eval { require Config::Model::CursesUI; 1; };

    my $ui_type = $opt->{ui};

    if ( not defined $ui_type ) {
        if ($has_tk) {
            $ui_type = 'tk';
        }
        elsif ($has_curses) {
            warn "You should install Config::Model::TkUI for a ", "more friendly user interface\n";
            $ui_type = 'curses';
        }
        else {
            warn "You should install Config::Model::TkUI or ",
                "Config::Model::CursesUI ",
                "for a more friendly user interface\n";
            $ui_type = 'shell';
        }
    }

    $root->deep_check;

    if ( $ui_type eq 'shell' ) {
        require Config::Model::TermUI;
        $self->run_shell_ui('Config::Model::TermUI', $inst) ;
    }
    elsif ( $ui_type eq 'curses' ) {
        die "cannot run curses interface: ",
            "Config::Model::CursesUI is not installed, please use shell or simple UI\n"
            unless $has_curses;
        my $err_file = '/tmp/cme-error.log';

        print "In case of error, check $err_file\n";

        open( my $fh, ">", $err_file ) || die "Can't open $err_file: $!\n";
        open(STDERR, ">&", $fh)|| die "Can't open STDERR:$!\n";

        my $dialog = Config::Model::CursesUI->new();

        # engage in user interaction
        $dialog->start($model);

        close($fh);
    }
    elsif ( $ui_type eq 'tk' ) {
        die "cannot run Tk interface: Config::Model::TkUI is not installed, please use curses or shell or simple ui\n"
            unless $has_tk;
        $self ->run_tk_ui ( $inst, $opt);
    }
    else {
        die "Unsupported user interface: $ui_type\n";
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cme::Command::edit - Edit the configuration of an application

=head1 VERSION

version 1.034

=head1 SYNOPSIS

  # edit dpkg config with GUI (requires Config::Model::Dpkg)
  cme edit dpkg 

  # force usage of simple shell like interface
  cme edit dpkg-copyright --ui shell

  # edit /etc/sshd_config (requires Config::Model::OpenSsh)
  sudo cme edit sshd

  # edit ~/.ssh/config (requires Config::Model::OpenSsh)
  cme edit ssh

  # edit a file (file name specification is mandatory here)
  cme edit multistrap my.conf

=head1 DESCRIPTION

Edit a configuration. By default, a Tk GUI will be opened if C<Config::Model::TkUI> is
installed. You can choose another user interface with the C<-ui> option:

=over

=item *

C<tk>: provides a Tk graphical interface (If C<Config::Model::TkUI> is
installed).

=item *

C<curses>: provides a curses user interface (If
L<Config::Model::CursesUI> is installed).

=item *

C<shell>: provides a shell like interface.  See L<Config::Model::TermUI>
for details. This is equivalent to running C<cme shell> command.

=back

=head1 Common options

See L<cme/"Global Options">.

=head1 options

=over

=item -open-item

Open a specific item of the configuration when opening the editor

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
