package App::Rcsync;
{
  $App::Rcsync::VERSION = '0.03';
}

# ABSTRACT: Sync configuration files across machines

use strict;
use warnings;

use File::HomeDir;
use Template;
use Config::General;
use File::Path     qw(make_path);
use Path::Class    qw(file dir);
use File::Copy     qw(copy);
use Ref::Explicit  qw(hashref);

use base qw(App::Cmd::Simple);

sub opt_spec
{
    return (
        [ "help|h",     "display usage information"      ],
        [ "config|c=s", "configuration file to use",
            { default => file( File::HomeDir->my_home, '.rcsync' ) }
        ],
        [ "all|a",      "sync all profiles"              ],
        [ "list|l",     "list all profiles"              ],
        [ "init|i",     "create configuration file"      ],
        [ "which|w",    "print path to profile template" ],
        [ "stdout|s",   "print to STDOUT"                ],
    );
}

sub validate_args
{
    my ($self, $opt, $args) = @_;

    if ( !$opt->{init} and ! -e $opt->{config} )
    {
        $self->usage_error("Configuration file " . $opt->{config} . " not found, aborting");
    }

    if ( !$opt->{help} and !$opt->{init} and !$opt->{all} and !$opt->{list} and !@$args )
    {
        $self->usage_error("Please specify profiles to sync");
    }
}

sub execute
{
    my ($self, $opt, $args) = @_;

    if ( $opt->{init} )
    {
        my $home = File::HomeDir->my_home;
        my $rcsync_home = dir $home, 'rcsync';

        if ( -e $opt->{config} )
        {
            print "Configuration file $$opt{config} already exists, will not overwrite\n";
            return;
        }

        make_path $rcsync_home unless -e $rcsync_home;

        my $sample_config = file ($rcsync_home, 'rcsync');

        if ( -e ( my $sample_config = file ($rcsync_home, 'rcsync') ) )
        {
            copy( $sample_config, $opt->{config} )
                or die "Failed to copy $sample_config to $$opt{config}: $!";
            print "Created configuration file $$opt{config} as copy of $sample_config";
        }
        else
        {
            my @children = $rcsync_home->children( no_hidden => 1 );
            @children = file ('sample.tt') unless @children;

            my @templates;

            foreach my $template (@children)
            {
                my $basename = $template->basename;
                $basename =~ s/\.\w+$//;

                push @templates, {
                    name        => $basename,
                    base_name   => $template->basename,
                    deploy_path => file ( $home, ".$basename" ),
                };
            }

            my $tt = Template->new or die Template->error;
            $tt->process(
                \_config_template(),
                { templates => \@templates, rcsync_home => $rcsync_home },
                $opt->{config}->stringify,
            ) or die $tt->error;

            print "Created sample configuration file $$opt{config}\n";
        }

        return;
    }
    elsif ($opt->{help})
    {
        print $self->app->usage->text;
    }

    my %config = Config::General->new( $opt->{config} )->getall;
    my @all_profiles = grep { ref $config{$_} eq 'HASH' } keys %config;

    my %profiles_config;
    @profiles_config{@all_profiles} = @config{@all_profiles};

    my @profiles = $opt->{all} ? @all_profiles : @$args;

    if ( $opt->{list} )
    {
        print "$_\n" for @all_profiles;
        return;
    }
    elsif ( $opt->{which} )
    {
        my $profile_name = $$args[0];
        if ( exists $profiles_config{$profile_name} )
        {
            print file($config{base_dir}, $profiles_config{$profile_name}{template})->absolute->stringify;
        }
        else
        {
            warn "No such profile '$profile_name'\n";
        }
        return;
    }


    my $tt = Template->new( INCLUDE_PATH => $config{base_dir} ) or die Template->error;

    foreach my $profile_name (@profiles)
    {
        if (!$profiles_config{$profile_name})
        {
            warn "No such profile '$profile_name'\n";
            next;
        }

        my $profile = $profiles_config{$profile_name};

        $tt->process(
            $profile->{template},
            $profile->{param},
            $opt->{stdout} ? \*STDOUT : $profile->{filename},
        ) or die $tt->error;

        if (!$opt->{stdout})
        {
            print "Successfully synced profile '$profile_name'\n";
        }
    }
}

sub _config_template
{
    return <<EoT
base_dir [% rcsync_home %]

[% FOREACH template IN templates %]<[% template.name %]>
    filename [% template.deploy_path %]
    template [% template.base_name %]
    <params>
        # enter parameters here
    </params>
</[% template.name %]>

[% END %]
EoT
}

1;
