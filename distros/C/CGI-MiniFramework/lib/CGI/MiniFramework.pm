package CGI::MiniFramework;

use strict;
use warnings;

our $VERSION = '0.01';
our $MODE;
our $MODULE;
our $ERROR_MSG;

sub new {
    my($class,$self)=(shift,{@_});
    bless($self,$class);

    my ($module,$mode) = $self->get_path_info;

    $self->init($module,$mode);

    $self;
}

sub get_path_info {
    my $self = shift;

    my $path_info = $ENV{'PATH_INFO'};

    if ( ! $path_info ) {
        $path_info = '/';
    }

    $path_info = "/$path_info" if(index($path_info, '/') != 0);

    my ($module,$mode) = (split(/\//,$path_info))[1,2];

    if ( $module ) {
        ($module) = ($module =~ /^([A-Za-z][A-Za-z0-9_\-\:\']+)$/);
    }
    else {
        $mode = q{};
    }

    return ($module,$mode);
}

sub init {
    my $self   = shift;
    my $module = shift;
    my $mode   = shift;

    $self->mode($mode) if $mode;

    if ( $mode ) {
        $self->mode($mode);
    }
    elsif( $self->{'DEFAULT_MODE'} ) {
        $self->mode($self->{'DEFAULT_MODE'});
    }
    else {
        $self->mode('start');
    }

    if ( $module ) {
        $self->module($module);
    }
    elsif( $self->{'DEFAULT'} ) {
        $self->module($self->{'DEFAULT'});
    }
    else {
        $self->module(q{});
    }

    return;
}

sub run {
    my $self = shift;

    my $obj = $self->get_object;

    if ( ! $obj ) {
        die $self->error;
    }

    my $mode = $self->mode;

    my $do_mode = $obj->setup($mode);

    if ( ! $do_mode ) {
        my $class = ref($obj);
        die "There is no execution method in $class .";
    }

    $obj->pre_run if $obj->can("pre_run");

    my $output;
    eval {
        $output = $obj->$do_mode;
    };

    if ( $@ ) {
        $obj->error_mode if $obj->can("error_mode");
        die "The error occurs by your script.";
    }

    if ( ! $output ) {
        die "Output data doesn't exist.";
    }

    $obj->teardown if $obj->can("teardown");

    return $output;
}

sub get_object {
    my $self = shift;
    my $module = $self->module;

    if ( $self->{'PREFIX'} ) {
        $module = $self->{'PREFIX'}.'::'.$module;
    }

    eval "require $module"
     or $self->error($!) and return undef;

    my $obj;
    eval {
        $obj = $module->new;
    };
    if ( $@ ) {
        $self->error($@);
        return undef;
    }

    return $obj;
}

sub module {
    my $self = shift;
    if(@_) { $MODULE = shift }
    return $MODULE;
}

sub mode {
    my $self = shift;
    if(@_) { $MODE = shift }
    return $MODE;
}

sub error {
    my $self = shift;
    if(@_) { $ERROR_MSG = shift }
    return $ERROR_MSG;
}

1;
__END__

=head1 NAME

CGI::MiniFramework - CGI framework of a minimum composition.

=head1 VERSION

This documentation refers to CGI::MiniFramework version 0.01

=head1 SYNOPSIS

    ### In "webapp.cgi"...
    #! /usr/bin/perl
    
    use strict;
    use warnings;
    use CGI::MiniFramework;

    my $f = CGI::MiniFramework->new(
        PREFIX       => 'App',
        DEFAULT      => 'WebApp',
        DEFAULT_MODE => 'index',
    );
    print $f->run();

    ### Dispatch Module...
    package App::WebApp
    ....
    sub new {
        my($class,$self)=(shift,{@_});
        bless($self,$class);
        $self;
    }

    sub setup {
        my $self = shift;
        my $mode = shift;
        my %run_mode = (
            'index' => 'do_index',
        );
        return $run_mode{$mode};
    }

    sub do_index {
        return "Welcom CGI::MiniFramework !!";
    }
    1;

=head1 DESCRIPTION

CGI::MiniFramework is CGI framework of a minimum composition.
CGI::MiniFramework doesn't depend on other modules excluding strict and warning.
You copies it onto an arbitrary place if you want to use this. 
You ended the preparation to use this framework only by this. 

The easy one is easily done. 
Please do it difficult by another framework.

=head1 METHOD

=head2 new

=over 4

  my $f = CGI::MiniFramework->new(
      PREFIX       => 'App',
      DEFAULT      => 'Index',
      DEFAULT_MODE => 'index',
  );

Creates and returns new CGI::MiniFramework object.

=back

=head3 OPTIONS

PREFIX is a definite article applied to the name of the module.
DEFAULT is a name of the module used by default.
DEFAULT_MODE is a mode executed by default.

=head2 run

=over 4

  print $f->run();

The application is executed.
The return value of the method of the run must be output data. 

This method executes your script in the next order. 

The First ,setup method. You must are preparing setup method. This method should return run mode method. 
The Second ,pre_run method If you are preparing. It is possible to preprocess it by this pre_run method. 
The Third ,run mode method. This run mode method is your main process.
The Fourth ,teardown method If you are preparing. It is possible to postprocessing it by this teardown method. 
If error_mode method is set when it makes an error of your run mode method, it is executed. 

=back

=head2 init

=over 4

The module and the mode are set. 
If DEFAULT is defined, it is set. 
If DEFAULT_MODE is defined, it is set. 
If DEFAULT_MODE is not defined, C<start> becomes the mode of default. 

=back

=head2 get_object

=over 4

The object that becomes a target is made and it is returned. 

=back

=head2 module

=over 4

It is Getter/Setter of the $MODULE. 

=back

=head2 mode

=over 4

It is Getter/Setter of the $MODE. 

=back

=head2 error

=over 4

It is Getter/Setter of the $ERROR_MSG. 

=back

=head1 DEPENDENCIES

strict
warnings

However,If you don't want to use even it, you can exclude it. 
Though I don't think that it is good.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>)
Patches are welcome.

=head1 AUTHOR

Atsushi Kobayashi, E<lt>nekokak@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Atsushi Kobayashi (E<lt>nekokak at users.sourceforge.jpE<gt>). All rights reserved.

This library is free software; you can redistribute it and/or modify it
 under the same terms as Perl itself. See L<perlartistic>.

=cut
