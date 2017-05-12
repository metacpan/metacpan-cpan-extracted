#!/usr/bin/env perl

#####################################################################################
#
# Copyright (c) 2012, Alexander Todorov <atodorov()otb.bg>. See POD section.
#
#####################################################################################

package App::Difio::OpenShift;
our $VERSION = '2.00';
our $NAME = "difio-openshift-perl";

use App::Difio::OpenShift::Parser;
@ISA = qw(App::Difio::OpenShift::Parser);

use strict;
use warnings;

use JSON;
use LWP::UserAgent;

my $data = {
    'user_id'    => $ENV{'DIFIO_USER_ID'},
    'app_name'   => $ENV{'OPENSHIFT_GEAR_NAME'},
    'app_uuid'   => $ENV{'OPENSHIFT_GEAR_UUID'},
    'app_type'   => $ENV{'OPENSHIFT_GEAR_TYPE'},
    'app_url'    => "http://$ENV{'OPENSHIFT_GEAR_DNS'}",
    'app_vendor' => 0,   # Red Hat OpenShift
    'pkg_type'   => 400, # Perl / CPAN
    'installed'  => [],
};

my $pod_parsed = "";
my $parser = App::Difio::OpenShift::Parser->new();
$parser->output_string( \$pod_parsed );
$parser->parse_file("$ENV{'OPENSHIFT_GEAR_DIR'}/perl5lib/lib/perl5/x86_64-linux-thread-multi/perllocal.pod");

my @installed;
foreach my $nv (split(/\n/, $pod_parsed)) {
    my @name_ver = split(/ /, $nv);
    push(@installed, {'n' => $name_ver[0], 'v' => $name_ver[1]});
}


$data->{'installed'} = [ @installed ];

my $json_data = to_json($data); # , { pretty => 1 });

my $ua = new LWP::UserAgent(('agent' => "$NAME/$VERSION"));

# will URL Encode by default
my $response = $ua->post('https://difio-otb.rhcloud.com/application/register/', { json_data => $json_data});

if (! $response->is_success) {
    die $response->status_line;
}

my $content = from_json($response->decoded_content);
print "Difio: $content->{'message'}\n";

exit $content->{'exit_code'};


1;
__END__

=head1 NAME

App::Difio::OpenShift - Difio registration agent for OpenShift / Perl applications

=head1 SYNOPSIS

To register your OpenShift Perl application to Difio do the following:

1) Create a Perl application on OpenShift:

    rhc-create-app -a myapp -t perl-5.10

2) Add a dependency in your deplist.txt file

    cd ./myapp/
    echo "App::Difio::OpenShift" >> deplist.txt

3) Set your userID in the ./data/DIFIO_SETTINGS file

    echo "export DIFIO_USER_ID=YourUserID"  > ./data/DIFIO_SETTINGS

4) Enable the registration script in .openshift/action_hooks/post_deploy

    source $OPENSHIFT_REPO_DIR/data/DIFIO_SETTINGS
    export PERL5LIB=$OPENSHIFT_GEAR_DIR/perl5lib/lib/perl5/
    $OPENSHIFT_GEAR_DIR/perl5lib/lib/perl5/App/Difio/OpenShift.pm

5) Commit your changes

    git add .
    git commit -m "enable Difio registration"

6) Then push your application to OpenShift

    git push

That's it, you can now check your application statistics at
http://www.dif.io


=head1 DESCRIPTION

This module compiles a list of locally installed Perl distributions and sends it to
http://www.dif.io where you check your application statistic and available updates.

=head1 AUTHOR

Alexander Todorov, E<lt>atodorov()dif.ioE<gt>

=head1 COPYRIGHT AND LICENSE

 Copyright (c) 2012, Alexander Todorov <atodorov()dif.io>

 This module is free software and is published under the same terms as Perl itself.

=cut
