package App1;

=head1 NAME

App1 - base class for use in app1.pl

=cut

use strict;
use warnings;
use base qw(CGI::Ex::App);
use FindBin qw($Bin);
use CGI::Ex::Dump qw(debug);

###----------------------------------------------------------------###

# preload these so that their load times don't affect the dump_history times
use CGI;
use Template::Alloy qw(Parse Play Compile);

sub post_navigate {
    my $self = shift;
    debug $self->dump_history
        if ! $self->{'no_history'};
}

###----------------------------------------------------------------###

sub load_conf       { 1 }
sub conf_file       { "$Bin/app1.yaml" }
sub conf_validation { {path => {required => 1, max_values => 100}} }

sub allow_morph     { 1 }

sub name_module     { "" } # allow content files to be in /tt/ directory directly
sub template_path   { "$Bin/tt" }
sub template_args   { {COMPILE_DIR => "/tmp/tt/app1.cache"} }

# if we want automatic javascript validation, and we have overridden the path,
# we need to give the script a way to find the validate.js
sub js_uri_path { (my $path = $ENV{'SCRIPT_NAME'}) =~ s|[^/]+$|js.pl|; $path }

# setting this instructs the flow to continue until a step does not have data
sub validate_when_data { 1 }

1;
