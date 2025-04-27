#
# This file is part of App-Cme
#
# This software is Copyright (c) 2014-2022 by Dominique Dumont <ddumont@cpan.org>.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# ABSTRACT: Modify the configuration of an application

package App::Cme::Command::modify ;
$App::Cme::Command::modify::VERSION = '1.042';
use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

use Config::Model::ObjTreeScanner;
use Config::Model qw/initialize_log4perl/;

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->check_unknown_args($args);
    $self->process_args($opt,$args);
    $self->usage_error("No modification instructions given on command line")
        unless @$args or $opt->{save};
    return;
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( 
        [ "backup:s"  => "Create a backup of configuration files before saving." ],
        $class->cme_global_options,
    );
}

sub usage_desc {
    my ($self) = @_;
    my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
    return "$desc [application] [file ] instructions";
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}

sub execute {
    my ($self, $opt, $args) = @_;

    $opt->{_verbose} = 'Loader' if $opt->{verbose};

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    # needed to create write_back subs
    $root->dump_tree() if $opt->{save} and not @$args;

    $root->load("@$args");

    $root->deep_check; # consistency check

    $self->save($inst,$opt) ;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cme::Command::modify - Modify the configuration of an application

=head1 VERSION

version 1.042

=head1 SYNOPSIS

  # modify configuration with command line
  cme modify dpkg source 'format="(3.0) quilt"'

=head1 DESCRIPTION

Modify a configuration file with the values passed on the command line.
These command must follow the syntax defined in L<Config::Model::Loader>
(which is similar to the output of L<cme dump|"/dump"> command)

Example:

   cme modify dpkg 'source format="(3.0) quilt"'
   cme modify multistrap my_mstrap.conf 'sections:base source="http://ftp.fr.debian.org"'

Finding the right instructions to perform a modification may be
difficult when starting from scratch.

To get started, you can run C<cme dump --format cml> command to get
the content of your configuration in the syntax accepted by C<cme modify>:

 $ cme dump ssh -format cml
 Host:"*" -
 Host:"alioth.debian.org"
   User=dod -
 Host:"*.debian.org"
   IdentityFile:="~/.ssh/id_debian"
   User=dod -

Then you can use this output to create instruction for a modification:

 $  cme modify ssh 'Host:"*" User=dod'
 Changes applied to ssh configuration:
 - Host:"*" User has new value: 'dod'

=head1 Common options

See L<cme/"Global Options">.

=head1 options

=over

=item -save

Force a save even if no change was done. Useful to reformat the configuration file.

=item -verbose

Show effect of the modify instructions.

=back

=head1 Examples

=head2 Set identity file for a domain

 $ cme modify ssh 'Host:"*.work.com" IdentityFile:="~/.ssh/id_work"'

This example requires L<Config::Model::OpenSsh>.

=head2 Update Dpkg file

To set C<Architecture> parameter for all binary packages:

 $ cme modify dpkg-control 'binary:~".*" Architecture=any'

This achieves the same result but can be slower since all package
files are read:

 $ cme modify dpkg 'control binary:~".*" Architecture=any'

This Debian example requires C<libconfig-model-dpkg-perl>

=head1 Re-use your one-liners

These modification instructions can be re-used once they are stored in
a run script (See L<App::Cme::Command::run> for details).

The following one-liner:

 $ cme modify dpkg 'control binary:~".*" Architecture=any'

can be stored in C<~/.cme/scripts/set-arch-as-any>:

  app: dpkg-control
  load: binary:~".*" Architecture=any

and then run with:

  $ cme run set-arch-as-any

=head1 SEE ALSO

L<cme>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2022 by Dominique Dumont <ddumont@cpan.org>.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
