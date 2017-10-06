#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Itself::BackendDetector ;
$Config::Model::Itself::BackendDetector::VERSION = '2.012';
# since this package is mostly targeted for dev environments
# let the detector detect models under development
use lib 'lib';

use Pod::POM ;
use File::Find ;

use base qw/Config::Model::Value/ ;

use strict ;
use warnings ;

sub setup_enum_choice {
    my $self = shift ;

    # using a hash to make sure that a backend is not listed twice. This may
    # happen in development environment where a backend in found in /usr/lib
    # and in ./lib (or ./blib)
    my %choices = map { ($_ => 1);} ref $_[0] ? @{$_[0]} : @_ ;

    # find available backends in all @INC directories
    my $wanted = sub { 
        my $n = $File::Find::name ;
        if (-f $_ and $n =~ s/\.pm$// and $n !~ /Any$/) {
	    $n =~ s!.*Backend/!! ;
	    $n =~ s!/!::!g ;
	    $choices{$n} = 1 ;
        }
    } ;

    foreach my $inc (@INC) {
        my $path = "$inc/Config/Model/Backend" ;
        find ($wanted, $path ) if -d $path;
    }

    $self->SUPER::setup_enum_choice(sort keys %choices) ;
}

sub set_help {
    my ($self,$args) = @_ ;

    my $help = delete $args->{help} || {} ;

    my $path = $INC{"Config/Model.pm"} ;
    $path =~ s!\.pm!/Backend! ;

    my $parser = Pod::POM->new();

    my $wanted = sub { 
        my $n = $File::Find::name ;

        return unless (-f $n and $n !~ /Any\.pm$/) ;
        my $file = $n ;
        $n =~ s/\.pm$//;
        $n =~ s!/!::!g ;
        my $perl_name = $n ;
        $n =~ s!.*Backend::!! ;
        $perl_name =~ s!.*Config!Config! ;

        my $pom = $parser->parse_file($file)|| die $parser->error();

        foreach my $head1 ($pom->head1()) {
            if ($head1->title() eq 'NAME') {
                my $c = $head1->content();
                $c =~ s/.*?-\s*//;
                $c =~ s/\n//g;
                $help->{$n} = $c . " provided by L<$perl_name>";
                last;
            }
        }
    };

    find ($wanted, $path ) ;

    $self->{help} =  $help;
}

1;

# ABSTRACT:  Detect available read/write backends usable by config models

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Itself::BackendDetector - Detect available read/write backends usable by config models

=head1 VERSION

version 2.012

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

This software is Copyright (c) 2007-2017 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
