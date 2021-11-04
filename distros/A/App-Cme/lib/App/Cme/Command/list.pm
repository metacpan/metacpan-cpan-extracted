#
# This file is part of App-Cme
#
# This software is Copyright (c) 2014-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# ABSTRACT: List applications handled by cme

package App::Cme::Command::list ;
$App::Cme::Command::list::VERSION = '1.034';
use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;
use Config::Model::Lister;

sub description {
    return << "EOD"
Show a list all applications where a model is available. This list depends on
installed Config::Model modules. Applications are divided in 3 categories:
- system: for system wide applications (e.g. daemon like sshd)
- user: for user applications (e.g. ssh configuration)
- application: misc application like multistrap or Debian packaging
EOD
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        [ "dev!"               => "list includes a model under development"],
    );
}

my %help = (
    system => "system configuration files. Use sudo to run cme",
    user => "user configuration files",
    application => "miscellaneous application configuration",
);

sub execute {
    my ($self, $opt, $args) = @_;

    my ( $categories, $appli_info, $appli_map ) = Config::Model::Lister::available_models($opt->dev());
    foreach my $cat ( qw/system user application/ ) {
        my $names = $categories->{$cat} || [];
        next unless @$names;
        print $cat," ( ",$help{$cat}," ):\n  ", join( "\n  ", @$names ), "\n";
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cme::Command::list - List applications handled by cme

=head1 VERSION

version 1.034

=head1 SYNOPSIS

 cme list

=head1 DESCRIPTION

Show a list all applications where a model is available. This list depends on
installed Config::Model modules.

=head1 SEE ALSO

L<cme>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2021 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
