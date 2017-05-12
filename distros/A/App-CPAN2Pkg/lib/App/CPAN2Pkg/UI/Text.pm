#
# This file is part of App-CPAN2Pkg
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::CPAN2Pkg::UI::Text;
# ABSTRACT: text interface for cpan2pkg
$App::CPAN2Pkg::UI::Text::VERSION = '3.004';
use DateTime;
use List::Util qw{ first };
use Moose;
use MooseX::Has::Sugar;
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use POE;
use Readonly;
use Term::ANSIColor qw{ :constants };

Readonly my $K  => $poe_kernel;


# -- attributes

# keep track of module outpus
has _outputs => ( ro, isa => 'HashRef', default=>sub {{}} );


# -- initialization

#
# START()
#
# called as poe session initialization.
#
sub START {
    my $self = shift;
#    $poe_kernel->alias_set('main');
    POE::Kernel->alias_set('main');
}


# -- public logging events

{


    event log_out => sub {
        my ($self, $modname, $line) = @_[OBJECT, ARG0 .. $#_ ];
        $self->_outputs->{$modname} .= "$line\n";
    };
    event log_err => sub {
        my ($self, $modname, $line) = @_[OBJECT, ARG0 .. $#_ ];
        $self->_outputs->{$modname} .= "$line\n";
    };
    event log_comment => sub {
        my ($self, $module, $line) = @_[OBJECT, ARG0 .. $#_ ];
        my $timestamp = DateTime->now(time_zone=>"local")->hms;
        $line =~ s/\n$//;
        print "$timestamp [$module] $line\n";
    };
    event log_result => sub {
        my ($self, $module, $result) = @_[OBJECT, ARG0 .. $#_ ];
        my $timestamp = DateTime->now(time_zone=>"local")->hms;
        local $Term::ANSIColor::AUTORESET = 1;
        print BLUE "$timestamp [$module] => $result\n"; 
    };
    event log_step => sub {
        my ($self, $module, $step) = @_[OBJECT, ARG0 .. $#_ ];
        my $timestamp = DateTime->now(time_zone=>"local")->hms;
        local $Term::ANSIColor::AUTORESET = 1;
        print BOLD "$timestamp [$module] ** $step\n"; 
    };
}


event module_state => sub {
    my ($self, $module) = @_[OBJECT, ARG0 .. $#_ ];
    my $app       = App::CPAN2Pkg->instance;
    my $modname   = $module->name;
    my $timestamp = DateTime->now(time_zone=>"local")->hms;

    if ( $module->local->status    eq "error" or
         $module->upstream->status eq "error" ) {
        local $Term::ANSIColor::AUTORESET = 1;
        print RED "$timestamp [$modname] error encountered\n";
        print "$timestamp [$modname] output follows:\n";
        print $self->_outputs->{$modname};
        print RED "$timestamp [$modname] aborting\n";
        $app->forget_module( $modname );
    }

    if ( $module->local->status    eq "available" and
         $module->upstream->status eq "available" ) {
        local $Term::ANSIColor::AUTORESET = 1;
        print GREEN "$timestamp [$modname] success\n";
        $app->forget_module( $modname );
    }

    {
        local $Term::ANSIColor::AUTORESET = 1;
        my $nb   = $app->nb_modules;
        my @mods = $app->all_modules;
        print YELLOW "$timestamp cpan2pkg - $nb modules remaining: @mods\n";
        exit if $nb == 0;
    }

    $self->_outputs->{$modname} = "";
};

# -- public events


event new_module => sub {
    my ($self, $module) = @_[OBJECT, ARG0];
    my $modname = $module->name;
};


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

App::CPAN2Pkg::UI::Text - text interface for cpan2pkg

=head1 VERSION

version 3.004

=head1 DESCRIPTION

This class implements a text interface for cpan2pkg. It's basic and
doesn't allow any interaction, however it will track the various modules
being built, their status. No details will be printed, unless in case of
failure. Useful when you only have a shell at hand.

=head1 EVENTS

=head2 log_out

=head2 log_err

=head2 log_comment

=head2 log_result

=head2 log_step

    log_XXX( $module, $line )

Log a C<$line> of output / stderr / comment / result / step in
C<$module> tab.

=head2 module_state

    module_state( $module )

Sent from the controller when a module has changed status (either
local or upstream).

=head2 new_module

    new_module( $module )

Received from the controller when a new module needs to be investigated.
Said module will be followed by a L<App::CPAN2Pkg::Worker> session.

=for Pod::Coverage START

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
