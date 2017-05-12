package App::Dependencio;
use base qw(App::Cmd::Simple);
use strict;
use warnings;
use File::Find;
use Cwd;
use Data::Printer;
use Term::ANSIColor;
use List::MoreUtils qw(uniq);
use Module::Extract::Use;

our $VERSION = '0.09';
my @mods_list = ();
my @mods_not_found = ();

sub opt_spec {
    return (
        [ "testdirs|t",  "Exclude dir named t (tests)" ],
        [ "verbose|v",  "Verbose output"],
        [ "cpanm|c",  "Automatic cpanm install missing modules"],
        # [ "cpanfile|f",  "outputs a list of modules to a cpanfile file"], #TODO
        [ "help|h",  "This help menu. (i am dependencio version $VERSION)"],
    );
}



sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->usage_error("Bad command") if @$args;
    $self->usage if $opt->{help};
}



sub execute {
    my ($self, $opt, $args) = @_;
    our $opts = $opt;
    $self->checkDeps;
}



sub checkDeps{
    my ($self, $opt) = @_;
    our $cwd  = getcwd();
    my @dirs = ();
    our $opts;
    push (@dirs,$cwd);

    print STDOUT colored ['bright_blue'], "Searching modules dependencies recursively from $cwd \n";
    find(\&_openFiles, @dirs);

    #p(@mods_not_found);
    foreach my $mod_not_found (uniq(@mods_not_found)){
        print STDOUT colored ['bright_red'], "module $mod_not_found not found\n";
        system "cpanm $mod_not_found" if $opts->{cpanm};

    }

    exit -1 if @mods_not_found or print STDOUT colored ['bright_green'], "success! all dependencies met...\n";
}



sub _openFiles{
    our $opts;
    our $cwd;
    my $dir = $cwd.'/t';
    my $tests = 1;
    if( $dir eq $File::Find::dir and $opts->{testdirs} ){ $tests = 0; };

    #only open file types to search module declarations (.pm and .pl)
    if(-f && m/\.(pm|pl)$/ and $tests == 1){
        print STDOUT "* checking dependecies on $File::Find::name\n" if $opts->{verbose};
        my $file = $File::Find::name;

        my $extractor = Module::Extract::Use->new;
        @mods_list = $extractor->get_modules($file);

        foreach my $module  (@mods_list) {
            if($module =~ /\p{Uppercase}/){ #do not eval things like "warnings","strict",etc (at least one uppercase)
                my $path = $module. ".pm";
                $path =~ s{::}{/}g;
                eval {require $path } or
                do {
                   my $error = $@;
                   push( @mods_not_found, $module) unless grep{$_ eq $module} @mods_not_found;
                }
            }

        }
    }
}
1;



__END__

=head1 NAME

Dependencio - Simple utility to find perl modules dependencies recursively in your project.


=head1 SYNOPSIS
cd yourawesemeproject
now run...
dependencio

this will read recursively into your project evaluating all the modules, if they are not installed, dependecio will warn you.
if you run 'dependencio -c', automagically will try to install the missing modules via cpanm


=head1 DESCRIPTION

This module aims to autodetect all the module dependencies recursively in a project.
To be used as standalone application to be part of your continous integration to deploy.
Could be added the execution of Dependencio as a post hook git, jenkins, etc.



=head2 EXPORT

checkDeps


=head1 AUTHOR

dani remeseiro, E<lt>jipipayo at cpan dot org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by dani remeseiro
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

