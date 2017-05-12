package Apache::SiteConfig::Deploy;
use feature ':5.10';
use warnings;
use strict;
use File::Basename qw(dirname);
use File::Spec;
use File::Path qw(mkpath rmtree);
use Apache::SiteConfig::Template;

# TODO: support template variable for paths and meta data.

our $Single;

END {
    $Single->execute_task( @ARGV ) if @ARGV;
}

sub import {
    my ($class) = @_;
    $Single = $class->new;
    $Single->{args} = {};
    $Single->{tasks} = {};

    # built-in tasks
    $Single->{tasks}->{deploy} = sub { $Single->deploy( @_ ); };
    $Single->{tasks}->{update} = sub { $Single->update( @_ ); };
    $Single->{tasks}->{clean}  = sub { $Single->clean( @_ ); };

    # setup accessors to main::
    no strict 'refs';
    for my $key ( qw(su chown name domain domain_alias webroot source deploy task) ) {
        *{ 'main::' . $key } = sub { 
            ${ $class .'::'}{ $key }->( $Single , @_ );
        };
    }

    # Exporter->import( @_ );
    return 1;
}

sub new { bless {} , shift; }

sub execute_task {
    my ($self,$task_name,@args) = @_;
    my $task = $self->{tasks}->{ $task_name };
    if ( $task ) {
        $task->( $self , @args );
    } else {
        print "Task $task_name not found.\n";
    }
}

sub execute_command {
    my ($self,$cmd, $abort_on_failure) = @_;

    if( $self->{args}->{su} ) {
        $cmd = sprintf( 'sudo -u %s %s', $self->{args}->{su} , $cmd );
    }

    say $cmd;
    if( $abort_on_failure ) {
        system( $cmd ) == 0 or die $!;
    } else {
        system( $cmd );
    }
}

sub chown {
    my $self = shift;
    $self->{args}->{chown} = $_[0];
}

sub su {
    my $self = shift;
    $self->{args}->{su} = $_[0];
}

sub name ($) { 
    my $self = shift;
    $self->{args}->{name} = $_[0];
}

sub domain { 
    my $self = shift;
    $self->{args}->{domain} = $_[0]; 
}

sub domain_alias  { 
    my $self = shift;
    $self->{args}->{domain_alias} = $_[0]; 
}

sub source  { 
    my ($self,$type,$uri) = @_;
    $self->{args}->{source} ||= {};
    $self->{args}->{source}->{ $type } = $uri;
}

sub webroot {
    my ($self,$path) = @_;
    $self->{args}->{webroot} = $path;
}

sub task ($&) {
    my ($self,$name,$closure) = @_;
    $self->{tasks}->{ $name } = $closure;
}

sub preprocess_meta {
    my $self = shift;
    my $args = { %{ $self->{args} } };  # copy args
    $args->{sites_dir} ||= File::Spec->join( '/var/sites' );
    $args->{site_dir} ||= File::Spec->join( $args->{sites_dir} , $args->{name} );
    $args->{document_root} = File::Spec->join( 
            $args->{site_dir} , $args->{webroot} );

    $args->{log_dir} ||= 
            File::Spec->join( $args->{sites_dir} , $args->{name} , 'apache2' , 'logs' );
                # File::Spec->join( '/var/log/sites/' , $args->{name} , 'apache2' , 'logs' )

    $args->{access_log} ||= File::Spec->join( $args->{log_dir} , 'access.log' );
    $args->{error_log}  ||= File::Spec->join( $args->{log_dir} , 'error.log' );
    return $args;
}

sub prepare_paths {
    my ($self,$args) = @_;
    for my $path ( qw(sites_dir site_dir document_root) ) {
        next unless $args->{ $path };
        mkpath [ $args->{ $path } ] unless -e $args->{ $path };
    }
}

sub prepare_log_path {
    my ($self,$args) = @_;
    mkpath [ $args->{log_dir} ] unless -e $args->{log_dir};

}

sub clean {
    my $self = shift;
    my $args = $self->preprocess_meta;
    say "Cleanning up $args->{site_dir}";
    rmtree( $args->{site_dir} );
}

sub update {
    my $self = shift;
    my $args = $self->preprocess_meta;

    if( $args->{source} ) {
        chdir $args->{site_dir};

        if( $args->{source}->{git} ) {
            my $branch = $args->{source}->{branch} || 'master';
            $self->execute_command("git pull origin $branch") if $branch eq 'master';
        } 
        elsif ( $args->{source}->{hg} ) {
            $self->execute_command("hg pull -u");
        }
    }

}

sub deploy {
    my ($self) = @_;
    my $args = $self->preprocess_meta;
    $self->prepare_paths( $args );

    SKIP_SOURCE_CLONE:
    if( $args->{source} ) {

        if( $args->{source}->{git} ) {
            last SKIP_SOURCE_CLONE if -e File::Spec->join( $args->{site_dir} , '.git' );
            say "Cloning git repository from $args->{source}->{git} to $args->{site_dir}";

            $self->execute_command("git clone $args->{source}->{git} $args->{site_dir}",1);

            # if branch is specified, then check the branch out.
            my $branch = $args->{source}->{branch};
            $self->execute_command("git checkout -t origin/$branch",1) if $branch;

            # if tag is specified, then check the tag out.
            my $tag = $args->{source}->{tag};
            $self->execute_command("git checkout $tag -b $tag",1) if $tag;

        }
        elsif( $args->{source}->{hg} ) {
            last SKIP_SOURCE_CLONE if -e File::Spec->join( $args->{site_dir} , '.git' );

            say "Cloning hg repository from $args->{source}->{hg} to $args->{site_dir}";
            $self->execute_command("hg clone $args->{source}->{hg} $args->{site_dir}") == 0 or die($?);
        }

    }

    $self->prepare_log_path( $args );

    if( $args->{chown} ) {
        say "Changing owner to $args->{site_dir}";
        $self->execute_command( sprintf( 'chown -R %s: ' , $args->{site_dir} ) ,1);
    }
    


    # Default template
    my $template = Apache::SiteConfig::Template->new;  # apache site config template
    my $context = $template->build( 
        ServerName => $args->{domain},
        ServerAlias => $args->{domain_alias},
        DocumentRoot => $args->{document_root},
        CustomLog => $args->{access_log} , 
        ErrorLog => $args->{error_log} 
    );
    my $config_content = $context->to_string;

    # get site config directory
    my $apache_dir_debian = '/etc/apache2/sites-available';
    if( -e $apache_dir_debian ) {
        say "Apache Site Config Dir Found.";

        my $config_file = File::Spec->join( $apache_dir_debian , $args->{name} );

        if ( -e $config_file ) {
            say "$config_file exists, skipped.";
        } else {
            say "Writing site config to $config_file.";
            open my $fh , ">", $config_file;
            print $fh $config_content;
            close $fh;

            say "Enabling $args->{name}";
            system("a2ensite $args->{name}");

            say "Reloading apache";
            system("/etc/init.d/apache2 reload");
        }
    } 
    else {

        # try to find where apachectl is located.
        my $apachectl_bin = qx(which apachectl);
        chomp( $apachectl_bin );

        my $apache_dir = dirname(dirname( $apachectl_bin ));
        my $apache_conf_dir = File::Spec->join( $apache_dir , 'conf' );

        if( -e $apache_conf_dir ) {
            say "Found apache configuration directory: $apache_conf_dir";
            # prepare site config dir
            mkpath [ File::Spec->join( $apache_conf_dir , 'sites' ) ];

            my $httpd_conf = File::Spec->join( $apache_conf_dir , 'httpd.conf' );

            # write site config to apache conf dir
            my $config_file =  File::Spec->join( $apache_conf_dir , 'sites' , $args->{name} . '.conf' );
            say "Writing config file: $config_file";
            open my $fh , ">" , $config_file or die $!;
            print $fh $config_content;
            close $fh;

            say "Appending Include statement to $httpd_conf";
            open my $fh2 , ">>" , $httpd_conf or die $!;
            print $fh2 "###### Apache Site Configurations \n";
            print $fh2 "Include conf/sites/$args->{name}.conf\n";
            close $fh2;

        } else {
            # apachectl not found
            mkpath [ 'apache2' ];

            # TODO: run apache configtest here
            # /opt/local/apache2/bin/apachectl -t -f /path/to/config file
            my $config_file = File::Spec->join(  'apache2' , 'sites' , $args->{name} );  # apache config
            mkpath [ File::Spec->join('apache2','sites') ];

            say "Writing site config file: $config_file";
            open my $fh , ">", $config_file or die "Can not write config file $config_file: $!";
            print $fh $config_content;
            close $fh;
        }

    }


}


1;
__END__

=head1 NAME

Apache::SiteConfig::Deploy

=head1 SYNOPSIS

    use Apache::SiteConfig::Deploy;

    name   'projectA';

    domain 'foo.com';

    domain_alias 'foo.com';


    su 'www-data';
    chown 'www-data';

    source git => 'git@git.foo.com:projectA.git';

    source 
        git => 'git@git.foo.com:projectA.git',
        branch => 'master';

    source hg  => 'http://.........';


    # relative web document path of repository
    webroot 'webroot/';

    task deploy => sub {

    };

    task dist => sub {

    };



    Deploy->new( 
        name => 'projectA',
        sites_dir => '/var/sites',  # optional
        git => 'git@foo.com:projectA.git',
        domain => 'foo.com',
        webroot => 'webroot/',
    );

=cut
