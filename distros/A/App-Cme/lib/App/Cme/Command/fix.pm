#
# This file is part of App-Cme
#
# This software is Copyright (c) 2014-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# ABSTRACT: Fix the configuration of an application

package App::Cme::Command::fix ;
$App::Cme::Command::fix::VERSION = '1.034';
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
        [ "from=s@"  => "fix only a subset of a configuration tree" ],
        [ "backup:s"  => "Create a backup of configuration files before saving." ],
        [ "filter=s" => "pattern to select the element name to be fixed"],
        $class->cme_global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application] [ file ]";
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    my @fix_from = $opt->{from} ? @{$opt->{from}} : ('') ;

    foreach my $path (@fix_from) {
        my $node_to_fix = $inst->config_root->grab($path);
        my $msg = "cme: running fix on ".$inst->name." configuration";
        $msg .= "from node ". $node_to_fix->name if $path;
        say $msg. "..." if $opt->{verbose};
        $node_to_fix->apply_fixes($opt->{fix_filter});
    }

    $self->save($inst,$opt) ;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cme::Command::fix - Fix the configuration of an application

=head1 VERSION

version 1.034

=head1 SYNOPSIS

  # fix dpkg (this example requires Config::Model::Dpkg)
  cme fix dpkg

=head1 DESCRIPTION

Checks the content of the configuration file of an application (and
show warnings if needed), update deprecated parameters (old value are
saved to new parameters) and fix warnings are fixed. The configuration
is saved if anything was changed. If no changes are done, the file is
not saved.

=head1 Common options

See L<cme/"Global Options">.

=head1 options

=over

=item from

Use option C<-from> to fix only a subset of a configuration tree. Example:

 cme fix dpkg -from 'control binary:foo Depends'

This option can be repeated:

 cme fix dpkg -from 'control binary:foo Depends' -from 'control source Build-Depends'

=item filter

Filter the leaf according to a pattern. The pattern is applied to the element name to be fixed
Example:

 cme fix dpkg -from control -filter Build # will fix all Build-Depends and Build-Depend-Indep

or 

 cme fix dpkg -filter Depend

=back

=head1 SEE ALSO

L<cme>, L<App::Cme::Command::migrate>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2021 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
