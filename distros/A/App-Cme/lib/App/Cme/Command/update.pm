#
# This file is part of App-Cme
#
# This software is Copyright (c) 2014-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# ABSTRACT: Update the configuration of an application

package App::Cme::Command::update ;
$App::Cme::Command::update::VERSION = '1.034';
use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

use Config::Model::ObjTreeScanner;

use Config::Model;

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->check_unknown_args($args);
    $self->process_args($opt,$args);
    return;
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( 
        [ "edit!"     => "Run editor after update is done" ],
        [ "backup:s"  => "Create a backup of configuration files before saving." ],
        $class->cme_global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application] [file ]";
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my ( $inst) = $self->instance($opt,$args);

    say "Updating data..." unless $opt->{quiet};

    my @msgs = $inst->update(quiet => $opt->{quiet});

    if (@msgs and not $opt->{quiet}) {
        say "Update done";
    }
    elsif (not $opt->{quiet}) {
        say "Command done, but ".$opt->{_application}
            . " model has no provision for update";
    }

    if ($opt->{edit}) {
        say join("\n", grep {defined $_} @msgs );
        $self->run_tk_ui ( $inst, $opt);
    }
    else {
        $self->save($inst,$opt) ;
        say join("\n", grep {defined $_} @msgs );
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cme::Command::update - Update the configuration of an application

=head1 VERSION

version 1.034

=head1 SYNOPSIS

   cme update <application>
   # example: cme update dpkg-copyright

=head1 DESCRIPTION

Update a configuration file. The update is done scanning external
resource.

For instance, C<cme update dpkg-copyright> command can be used to
update a specific Debian package file (C<debian/copyright>). This is
done by scanning the headers of source files.

Currently, only dpkg-copyright application currently supports updates.

The configuration data (i.e. the content of C<debian/copyright> in
this example) is mapped to a tree structure inside L<cme>. You can:

=over 4

=item *

view this structure in YAML format by running C<cme dump dpkg-copyright>

=item *

view this structure in Config::Model's format (aka C<cml>) by running
C<cme dump -format cml dpkg-copyright>. This format is documented in
L<Config::Model::Loader>.

=item *

get a graphical view with C<cme edit dpkg-copyright>.

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
