#
# This file is part of App-Cme
#
# This software is Copyright (c) 2014-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# ABSTRACT: Dump the configuration of an application

package App::Cme::Command::dump ;
$App::Cme::Command::dump::VERSION = '1.034';
use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

use Config::Model::ObjTreeScanner;
use YAML;
use JSON;
use Data::Dumper;

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->check_unknown_args($args);
    $opt->{quiet} = 1; # don't want to mess up yaml output
    $self->process_args($opt,$args);
    return;
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        [
            "dumptype=s" => "Dump all values (full) or only customized values",
            {
                regex => qr/^(?:full|custom|non_upstream_default)$/,
                default => 'custom'
            }
        ],
        [
            "format=s" => "dump using specified format (yaml json perl cml)",
            {
                regex => qr/^(?:json|ya?ml|perl|cml|cds)$/i,
                default => 'yaml'
            },
        ],
        $class->cme_global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application]  [ config_file ] [ -dumptype full|custom ] [ path ]";
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    my $target_node = $root->grab(step => "@$args", type => 'node');

    my $dump_string;
    my $format = $opt->{format};
    my $mode = $opt->{dumptype} || 'custom';

    if ($format =~ /cml|cds/i) {
        $dump_string = $target_node->dump_tree( mode => $mode );
    }
    else {
        my $perl_data = $target_node->dump_as_data(
            ordered_hash_as_list => 0,
            mode => $mode
        );
        $dump_string
            = $format =~ /ya?ml/i ? Dump($perl_data)
            : $format =~ /json/i  ? encode_json($perl_data)
            :                       Dumper($perl_data) ; # Perl data structure
    }
    print $dump_string ;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cme::Command::dump - Dump the configuration of an application

=head1 VERSION

version 1.034

=head1 SYNOPSIS

  # dump ~/.ssh/config in cme syntax
  # (this example requires Config::Model::OpenSsh)
  $ cme dump -format cml ssh
  Host:"*" -
  Host:"*.debian.org"
    User=dod -

=head1 DESCRIPTION

Dump configuration content on STDOUT with YAML format.

By default, dump only custom values, i.e. different from application
built-in values or model default values. You can use the C<-dumptype> option for
other types of dump:

 -dumptype [ full | custom | non_upstream_default ]

Choose to dump every values (full), or only customized values (default)

C<non_upstream_default> is like C<full> mode, but value identical with
application default are omitted. But this should seldom happen.

By default, dump in yaml format. This can be changed in C<json>,
C<perl>, C<cml> (aka L<Config::Model::Loader> format, C<cds> is also
accepted) with C<-format> option.

=head1 Common options

See L<cme/"Global Options">.

=head1 SEE ALSO

L<cme>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2021 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
