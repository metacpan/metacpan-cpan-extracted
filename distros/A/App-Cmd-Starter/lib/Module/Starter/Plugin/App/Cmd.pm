package Module::Starter::Plugin::App::Cmd;

use 5.010;
use strict;
use warnings;
use parent 'Module::Starter::Simple';
use ExtUtils::Command qw( rm_rf mkpath touch );
use File::Spec ();

# Patch Module::Starter::Simple to call create_script() after create_modules()
use Class::Monkey qw/Module::Starter::Simple/;

after 'create_modules' => sub {
    my $self = shift;
    
    $self->create_script;
}, 'Module::Starter::Simple';

our $VERSION = '0.02';


=head1 NAME

Module::Starter::Plugin::App::Cmd 

=head1 SYNOPSIS

Guts for L<App::Cmd::Starter>.

=cut

#-------------------------------------------------------------------------------

sub postprocess_config {
    my $self = shift;
    
    die "Script name must be specified\n" unless $self->{script};
    die "At least one command must be specified\n" unless $self->{commands};
}


#-------------------------------------------------------------------------------

sub pre_create_distro {
    my $self = shift;
    
    $self->{main_module} = @{$self->{modules}}[0];
    
    push @{$self->{modules}}, $self->{main_module} . "::Command";
    
    foreach my $command (split /,/,$self->{commands}) {
        push @{$self->{modules}}, $self->{main_module} . "::Command::" . ucfirst $command;
    }
}


#-------------------------------------------------------------------------------

sub module_guts {
    my ($self, $module, $rtname) = @_;
    
    my $main_module = $self->{main_module};
    
    given ($module) {
        when ($main_module) {
            $self->main_module_guts($module, $rtname);
        }
        when ("$main_module"."::Command") {
            $self->command_pm_guts($module);
        }
        when (/($main_module\b::Command)::(\w+)/) {
            $self->command_module_guts($module, $1, lc $2);
        }
        default {
            $self->SUPER::module_guts($module, $rtname);
        }
    }
}


#-------------------------------------------------------------------------------

sub main_module_guts {
    my $self   = shift;
    my $module = shift;
    my $rtname = shift;

    # Sub-templates
    my $header  = $self->_module_header($module, $rtname);
    my $bugs    = $self->_module_bugs($module, $rtname);
    my $support = $self->_module_support($module, $rtname);
    my $license = $self->_module_license($module, $rtname);
    
    my $script  = $self->{script};
    my $env_var = uc($script =~ s/-/_/gr) . '_CONFIG';

    my $content = <<"HERE";
$header

use 5.010;
use App::Cmd::Setup -app;
use Config::General qw/ParseConfig/;
use File::HomeDir;
use File::Spec::Functions qw/catfile/;

sub config {
    state \$config = {ParseConfig(config_file())};
    return \$config;
}
 
sub config_file {
    my \@files = (
        \$ENV{$env_var},
        catfile(File::HomeDir->my_home, '.$script'),
        '/usr/local/etc/$script',
        '/etc/$script',
    );
     
    foreach my \$file (grep {defined \$_} \@files) {
        return \$file if -r \$file;
    }
}

\=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use $module;

    my \$foo = $module->new();
    ...

\=head1 AUTHOR

$self->{author}, C<< <$self->{email_obfuscated}> >>

$bugs

$support

$license

\=cut

1; # End of $module
HERE
    return $content;
}


#-------------------------------------------------------------------------------

sub command_pm_guts {
    my ($self, $module) = @_;
    
    return <<EOT;
package $module;

use App::Cmd::Setup -command;

sub opt_spec {
    my ( \$class, \$app ) = \@_;
    
    # Example options
    #
    # return (
    #     [ 'name=s' => "Name", {default => \$SUPER::config->{name} || undef} ],
    # );
    return ();
}

sub validate_args {
    my ( \$self, \$opt, \$args ) = \@_;
    
    # Example validation
    # 
    # \$self->usage_message('Your error here') unless (\$some_condition);
}

1;
EOT
}


#-------------------------------------------------------------------------------

sub command_module_guts {
    my ($self, $module, $base, $command) = @_;
    
    return <<EOT;
package $module;

use strict;
use warnings;
use parent '$base';

# Documentation

sub abstract {
    return "Abstract for the $command command";
}
 
sub usage_desc {
    return "%c $command %o";
}
 
sub description {
    return "Description for the $command command\\nOptions:";
}


# Command specific options
 
sub opt_spec {
    my (\$class, \$app) = \@_;
     
    return (
        # Example options
        #
        # [ "familiar" => "Use an informal greeting", {default => \$SUPER::config->{familiar} || undef} ],
        
        \$class->SUPER::opt_spec,  # Include global options
    );
}


# The command itself

sub execute {
    my (\$self, \$opt, \$args) = \@_;
    
    # require 'My::Dependency';
    # Tip: Using 'require' instead of 'use' will save memory and make startup faster

    # Command code goes here
}

1;
EOT
}


#-------------------------------------------------------------------------------

sub create_script {
    my $self = shift;
    
    my $script_dir = File::Spec->catdir($self->{basedir}, 'script');
    unless (-d $script_dir) {
        local @ARGV = $script_dir;
        mkpath @ARGV;
        $self->progress("Created $script_dir");
    }
    
    my $script_file = File::Spec->catfile($script_dir, $self->{script});
    $self->create_file($script_file, <<EOT);
#! /usr/bin/env perl

use $self->{main_module};
$self->{main_module}->run;
EOT
    $self->progress("Created $script_file");
}


#-------------------------------------------------------------------------------

sub post_create_distro {
    my $self = shift;
}


#-------------------------------------------------------------------------------

=head1 AUTHOR

Jon Allen (JJ), C<< <jj at jonallen.info> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-starter-plugin-app-cmd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Starter-Plugin-App-Cmd>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Starter::Plugin::App::Cmd


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Starter-Plugin-App-Cmd>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Starter-Plugin-App-Cmd>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Starter-Plugin-App-Cmd>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Starter-Plugin-App-Cmd/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jon Allen (JJ).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Module::Starter::Plugin::App::Cmd
