#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2026 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Itself::BackendDetector 2.029;

# since this package is mostly targeted for dev environments
# let the detector detect models under development
use lib 'lib';
use v5.20;
use strict ;
use warnings ;
use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures/;

use Pod::POM ;
use Path::Tiny;

use base qw/Config::Model::Value/ ;

sub setup_enum_choice ($self, @args) {

    # using a hash to make sure that a backend is not listed twice. This may
    # happen in development environment where a backend is found in /usr/lib
    # and in ./lib (or ./blib)
    my %choices = map { ($_ => 1);} ref $args[0] ? @{$args[0]} : @args ;

    # find available backends in all @INC directories
    my $wanted = sub ($path, $) {
        # Get the backend file relative to Config/Model/Backend dir
        my ($n) = ($path =~ s!.*Backend/!!r);

        if ($path->is_file and $n =~ s/\.pm$// and $n !~ /Any$/) {
            $n =~ s!/!::!g ;
            $choices{$n} = 1 ;
        }
    } ;

    foreach my $inc (@INC) {
        my $path = path($inc)->child("Config/Model/Backend") ;
        $path->visit($wanted, { recurse => 1} ) if $path->is_dir;
    }

    $self->SUPER::setup_enum_choice(sort keys %choices) ;
    return;
}

sub set_help {
    my ($self,$args) = @_ ;

    my $help = delete $args->{help} || {} ;

    my $path = $INC{"Config/Model.pm"} ;
    $path =~ s!\.pm!/Backend! ;

    my $parser = Pod::POM->new();

    my $wanted = sub ($path, $) {
        return unless ($path->is_file);
        return if $path->basename eq "Any.pm" ;
        return if $path =~ /Role/;
        my $help_key = $path->stringify;
        $help_key =~ s/\.pm$//;
        $help_key =~ s!/!::!g ;
        my $perl_name = $help_key ;
        $help_key =~ s!.*Backend::!! ;
        $perl_name =~ s!.*Config!Config! ;

        my $pom = $parser->parse_file($path->stringify) || die $parser->error();

        foreach my $head1 ($pom->head1()) {
            if ($head1->title() eq 'NAME') {
                my $c = $head1->content();
                $c =~ s/.*?-\s*//;
                $c =~ s/\n//g;
                $help->{$help_key} = $c . " provided by L<$perl_name>";
                last;
            }
        }
    };

    path($path)->visit ($wanted, {recurse => 1} ) ;

    $self->{help} =  $help;
    return;
}

1;

# ABSTRACT:  Detect available read/write backends usable by config models

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Itself::BackendDetector - Detect available read/write backends usable by config models

=head1 VERSION

version 2.029

=head1 SYNOPSIS

 # this class should be referenced in a configuration model and
 # created only by Config::Model::Node

 my $model = Config::Model->new() ;

 $model ->create_config_class
  (
   name => "Test",
   'element'
   => [ 
       'backend' => { type => 'leaf',
                      class => 'Config::Model::Itself::BackendDetector' ,
                      value_type => 'enum',
                      # specify backends built in Config::Model
                      choice => [qw/cds_file perl_file ini_file custom/],

                      help => {
                               cds_file => "file ...",
                               ini_file => "Ini file ...",
                               perl_file => "file  perl",
                               custom => "Custom format",
                              }
                    }
      ],
  );

  my $root = $model->instance(root_class_name => 'Test') -> config_root ;

  my $backend = $root->fetch_element('backend') ;

  my @choices = $backend->get_choice ;

=head1 DESCRIPTION

This class is derived from L<Config::Model::Value>. It is designed to
be used in a 'enum' value where the choice (the available backends)
are the backend built in L<Config::Model> and all the plugin backends. The
plugin backends are all the C<Config::Model::Backend::*> classes.

This module will detect available plugin backend and query their pod
documentation to provide a contextual help for config-model graphical
editor.

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Node>, L<Config::Model::Value>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2007-2026 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
