package CGI::Ex::Recipes;
use utf8;
use warnings;
use strict;
use Carp qw(croak);
use Data::Dumper;
use base qw(CGI::Ex::App);
use CGI::Ex::Die register => 1;
use CGI::Ex::Dump qw(debug dex_warn ctrace dex_trace);
use CGI::Ex::Recipes::DBIx qw(
    dbh
    sql
    create_tables
    categories
    recipes
);

our $VERSION = '0.08';

sub ext_conf {
    my $self = shift;
    $self->{'ext_conf'} = shift if @_ == 1;
    return $self->{'ext_conf'} || 'conf';
}

#overwritten the new (in 2.18)implementation of 'conf' so
# the application can find its, given  Recipes.conf
sub conf {
    my $self = shift;
    $self->{'conf'} = pop if @_ == 1;
    return $self->{'conf'} ||= do {
    my $conf = $self->conf_obj->read($self->conf_file, {no_warn_on_fail => 1}) || croak $@;
#my $conf = $self->conf_file;
#$conf = ($self->conf_obj->read($conf, {no_warn_on_fail => 1}) || $self->conf_die_on_fail ? croak $@ : {}) if ! $conf;
        my $hash = $self->conf_validation;
        if ($hash && scalar keys %$hash) {
            my $err_obj = $self->val_obj->validate($conf, $hash);
            die $err_obj if $err_obj;
        }
        $conf;
    }
}
 
sub load_conf { 1 }

sub base_dir_abs {$_[0]->{'base_dir_abs'} || ['./']}

sub allow_morph {
    my ( $self, $step ) = @_;
    return $self->conf->{allow_morph}->{$step};
}

#...but rather override the path_info_map hook for a particular step.
sub path_info_map {
    my ($self) = @_;
    my $step = $self->form->{ $self->step_key } || $self->conf->{default_step};
    return $self->conf->{path_info_map}{$step} || do {
        my $step = $self->form->{ $self->step_key } || $self->conf->{default_step};
        return '' if $step eq $self->conf->{default_step};
        [ 
            [ 
                qr{^/$step/(\d+)}, 'id' 
            ] 
        ];
    }
}

#Will be run natively for all subclasses
sub skip { shift->form->{'id'} ? 0 : 1 }

#ADDING AUTHENTICATION TO THE ENTIRE APPLICATION
sub get_pass_by_user {
    my $self = shift;
    my $user = shift;
    return $self->conf->{users}{$user};
}

#ADDING AUTHENTICATION TO INDIVIDUAL STEPS
sub require_auth { 
    my ($self, $step) = @_;  
    #allow configuration first
    return $self->conf->{require_auth}{$step} || 0;
}

#get authentication arguments from configuration if there is such
sub auth_args { 
    my $self = shift;
    {
        $self->conf->{template_args},
        $self->conf->{auth_args}
    };
}

sub hash_base {
    my $self = shift;
    my $hash = $self->SUPER::hash_base(@_);
    $hash->{'app'} = $self;
    #require Scalar::Util; 
    Scalar::Util::weaken($hash->{'app'});
    return $hash;
}


sub post_navigate {
    my $self = shift;
    # show what happened
    if (values %{$self->{'debug'}}) {
        debug $self->dump_history if $self->conf->{debug}{dump_history};
        debug $self->conf if $self->conf->{debug}{conf};
        debug \%ENV if $self->conf->{debug}{ENV};
        debug $self->cookies if $self->conf->{debug}{cookies};
        debug $self->form if $self->conf->{debug}{form};
        debug \%INC if $self->conf->{debug}{INChash};
        debug \@INC if $self->conf->{debug}{INCarray};
        debug $self->{_package} if $self->conf->{debug}{_package};
        debug [sort keys %{$self->{_cache}}] if $self->conf->{debug}{_cache};
    }
    #or do other usefull things.
}

sub pre_navigate { 
    #efectively logout
    require CGI::Ex::Auth;
    $_[0]->CGI::Ex::Auth::delete_cookie({'key'=>'cea_user'}) 
        if $_[0]->form->{'logout'};
    return 0;
}

sub pre_step {
    $_[0]->step_args;
    #run other things here
    return 0;
}

# hook/method - returns parsed arguments from C<$self->form->{step_info}> 
#for the curent step
# initially called in pre_step
sub step_args {
    return $_[0]->form->{step_args} || do {
        if($_[0]->form->{step_info}){
            my @step_args = split /\//,$_[0]->form->{step_info};
            for( my $i = 0 ; $i < @step_args; $i = $i+2 ){
                $_[0]->form->{step_args}{$step_args[$i]} = $step_args[$i+1] || '';
            }
        }
        return $_[0]->form->{step_args} || {};
    }
}

#Returns the cache object.
sub cache {
    my $self = shift;
    return $self->{cache} || do {
        require CGI::Ex::Recipes::Cache;
        $self->{cache} = CGI::Ex::Recipes::Cache->new({ cache_hash =>{}, dbh => $self->dbh });
    };
}


#========================== UTIL ==============================
#Utility funcions - may be moved to an Util class if needed
sub strftmime {
    my $self = shift;
    require POSIX;
    POSIX::strftime(shift,localtime( shift||time ) );
}
sub now {time};
1; # End of CGI::Ex::Recipes


__END__

=encoding utf8

=head1 NAME

CGI::Ex::Recipes - A usage example for CGI::Ex::App!

=head1 SYNOPSIS

You may find in index.cgi the following:

    use CGI::Ex::Recipes;
    CGI::Ex::Recipes->new({
        conf_file => './conf/Recipes.conf',
    })->navigate;
    ...

=head1 DESCRIPTION

This small but relatively complete application was inspired by the examples 
given by Paul in his documentation. I decided to go further and experiment with 
the recomendations and features which the framework provides. 
You are encouraged to play with it and use it as a starting point  for far more 
complex and customized applications.

Currently an SQLite database is used, but it should be easy to switch to whatever database you like.
With very little change this application should be able to use MySQL as a backend.

If you need another databse you should know how to adapt the application.

=head1 REQUIREMENTS

Below are listed only packages which are not available in the standart Perl 5.8 distribution.

    CGI::Ex
    DBI
    DBD::SQLite
    SQL::Abstract
    YAML

DBI and DBD::SQLite come with ActivePerl.

=head1 INSTALL

    1. CPAN
        
    2. svn checkout https://bcc.svn.sourceforge.net:443/svnroot/bcc/trunk/recipes
    into some viewable by the server dir with option AllowOverride All

=head1 MOD_PERL

As of VERSION 0.6 this application should run out of the box under mod_perl 2.
You just need to have "AllowOverride All" configuration option set for the directory
where the application is installed.
In the C<conf> directory of the installed application you will find an example httpd.conf.

See also index.pl and perl/bin/startup.pl.
Modify these files to meet your needs.

=head1 METHODS

Below are mentioned only methods which are overridden or not provided by CGI::Ex::App.
Some of them or their modified variants, or parts of them will probably find 
their way up to the base module. Some of them did it already.
This way they will become obsolete, but that is the point.

Others will stay here since they provide some specific for the application functionality.
Writing more specific methods will meen you make your own application, 
reflecting your own buziness logic.
This is good, because CGI::Ex::Recipes has done his job, by providing a codebase and 
starting point for you.

You are wellcome to give feedback if you think some functionality is enough 
common to go up straight to CGI::Ex::App.

Bellow are described  overriten methods and methods defined in this package.  

=head2 load_conf

Returns  the value of C<$self-E<gt>{load_conf}> or 1(TRUE) by default.

=head2 pre_step

Returns 0 after executing C<$self-E<gt>step_args()>.

=head2 allow_morph

Blindly returns the current value of allow_morph key in Recipes.conf,
which should be interpreted as TRUE or FALSE.

=head2 path_info_map

This is just our example implementation, following recomendations in L<CGI::Ex::App|CGI::Ex::App>.

=head2 skip

Ran at the beginning of the loop before prepare, info_complete, and finalize are called. 
If it returns true, nav_loop moves on to the next step (the current step is skipped).

In our case we bind it to the presence of the C<id> parameter from the HTTP request. 
So if there is an C<id> parameter it returns 0, otherwise 1.

=head2 get_pass_by_user

Returns the password for the given user. See the get_pass_by_user method of CGI::Ex::Auth 
for more information. Installed as a hook to the authentication object during the 
get_valid_auth method.

We get the password from the configuration file, which is enough for 
this demo, but you can do and SQL query for that purpose if you store
your users' info in the database.

=head2 require_auth

Returns 0 or 1 depending on configuration for individual steps.
This way we make only some steps to require authentication.

=head2 auth_args

Get authentication arguments from configuration if there is such
and returns a hashref. The template_args are merged in also.

=head2 hash_base

The extra work done here is that we use L<Scalar::Util|Scalar::Util> to C<weaken> 
the reference to the main application which we pass for use from within the templates and 
template plugins. Without doing this we may have problems under persistent environments, such as 
mod_perl. This is very handy when you need to dynamically generate HTML or 
use the attached DBI object. 
See L<CGI::Ex::Recipes::Template::Menu|CGI::Ex::Recipes::Template::Menu>, L<CGI::Ex::App|CGI::Ex::App>.

=head2 base_dir_abs

See also L<CGI::Ex::App|CGI::Ex::App>.

=head2 conf

Currently we use the old C<CGI::Ex::App::conf()>, 
so the configuration file is found as it was before CGI::Ex 2.18. 
See also L<CGI::Ex::App|CGI::Ex::App>.

=head2 ext_conf

We prefer C<conf> file extension as default over C<pl>.
See also L<CGI::Ex::App|CGI::Ex::App>.

=head2 pre_navigate

We have naive code here for logging out a user.
See also L<CGI::Ex::App|CGI::Ex::App>.

=head2 post_navigate

Currently I placed here a set of C<debug> statements for fun.
See also L<CGI::Ex::App|CGI::Ex::App>.


=head2 step_args

hook/method - returns parsed arguments from C<$self->form->{step_info}> 
for the curent step.
Initially called in pre_step.
Not in L<CGI::Ex::App|CGI::Ex::App>.

=head2 cache

Returns the cache object. See L<CGI::Ex::Recipes::Cache|CGI::Ex::Recipes::Cache>.
Not in L<CGI::Ex::App|CGI::Ex::App>.

=head1 UTILITY METHODS

These may go in another module - created specifically for this purpose.
And ofcource there are plenty of modules providing beter implementation.

=head2 strftmime

=head2 now

=head1 AUTHOR

Красимир Беров, C<< <k.berov at gmail.com> >>

=head1 BUGS

Probably many.

Please report any bugs or feature requests to k.berov@gmail.com by putting "CGI::Ex::Recipes" 
in the Subject line

=head1 ACKNOWLEDGEMENTS

    Larry Wall - for Perl
    
    Paul Seamons - for all his modules and especially for CGI::Ex didtro
    
    Anyone wich published anything on CPAN

=head1 COPYRIGHT & LICENSE

Copyright 2007-2012 Красимир Беров, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

