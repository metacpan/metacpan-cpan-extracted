#
# This file is part of App-Cme
#
# This software is Copyright (c) 2014-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# ABSTRACT: Check the configuration of an application

package App::Cme::Command::check ;
$App::Cme::Command::check::VERSION = '1.034';
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
        [ "strict!" => "cme will exit 1 if warnings are found during check" ],
        $class->cme_global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application]  [ config_file ]";
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);
    my $check =  $opt->{force_load} ? 'no' : 'yes' ;
    say "Loading data..." if $opt->{verbose};

    Config::Model::ObjTreeScanner->new(
        leaf_cb => sub { },
        check => $check,
    )->scan_node( undef, $root );

    say "Checking data.." if $opt->{verbose};
    $root->dump_tree( mode => 'full' ); # light check (value per value)
    $root->deep_check; # consistency check
    say "Check done." if $opt->{verbose};

    my $ouch = $inst->has_warning;

    if ( $ouch ) {
        my $app = $inst->application;
        warn "you can try 'cme fix $app' to fix the warnings shown above\n";
        die "Found $ouch warnings in strict mode\n" if $opt->{strict};
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cme::Command::check - Check the configuration of an application

=head1 VERSION

version 1.034

=head1 SYNOPSIS

 # standard usage
 cme check popcon

 # read data from arbitrary file (with Config::Model::Dpkg)
 cme check dpkg-copyright path/to/file

=head1 DESCRIPTION

Checks the content of the configuration file of an application. Prints warnings
and errors on STDOUT.

Example:

 cme check fstab

Some applications allows one to override the default configuration file.
For instance, with Debian copyright model, you can run cme on a different file:

  cme check dpkg-copyright foobar

or directly check copyright data on STDIN:

  curl http://metadata.ftp-master.debian.org/changelogs/main/f/frozen-bubble/unstable_copyright \
  | cme check dpkg-copyright -

=head1 Common options

See L<cme/"Global Options">.

=head1 options

=over

=item -strict

When set, cme exits 1 if warnings are found. By default, C<cme> exits
0 when warnings are found.

=back

=head1 EXIT CODE

cme exits 0 when no errors are found. Exit 1 otherwise.

If C<-strict> option is set, cme exits 1 when warnings are found.

=head1 SEE ALSO

L<cme>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2021 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
