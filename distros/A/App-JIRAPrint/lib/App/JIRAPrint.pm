package App::JIRAPrint;
# ABSTRACT: Print JIRA Tickets on Postit sheets
$App::JIRAPrint::VERSION = '0.003';
use Moose;
use Log::Any qw/$log/;

use WWW::Shorten 'TinyURL', ':short';

=head1 NAME

App::JIRAPrint - Print JIRA Tickets on PostIt sheets

=head1 INSTALLATION

On system perl:

  cpan -i App::JIRAPrint

Or in your favourite cpan minus place:

  cpanm App::JIRAPrint

=head1 SYNOPSIS

  jiraprint --help

=head1 BUILDING

=for HTML <a href="https://travis-ci.org/jeteve/App-JIRAPrint"><img src="https://travis-ci.org/jeteve/App-JIRAPrint.svg?branch=master"></a>

=cut

use autodie qw/:all/;
use Cwd;
use Data::Dumper;
use File::Spec;
use Hash::Merge;
use JIRA::REST;
use LaTeX::Encode;
use Template;

BEGIN{
    # The test compatible File::Share
    eval{ require File::Share; File::Share->import('dist_dir'); };
    if( $@ ){
        # The production only File::ShareDir
        require File::ShareDir;
        File::ShareDir->import('dist_dir');
    }
};


# Config stuff.
has 'config' => ( is => 'ro', isa => 'HashRef', lazy_build => 1);
has 'config_files' => ( is => 'ro' , isa => 'ArrayRef[Str]' , lazy_build => 1);

has 'shared_directory' => ( is => 'ro', isa => 'Str', lazy_build => 1);
has 'template_file' => ( is => 'ro', isa => 'Str', lazy_build => 1);


# Operation properties
has 'url' => ( is => 'ro', isa => 'Str', lazy_build => 1 );
has 'username' => ( is => 'ro', isa => 'Str' , lazy_build => 1);
has 'password' => ( is => 'ro', isa => 'Str' , lazy_build => 1);

has 'project' => ( is => 'ro', isa => 'Str' , lazy_build => 1 );
has 'sprint'  => ( is => 'ro', isa => 'Str' , lazy_build => 1 );
has 'maxissues' => ( is => 'ro', isa => 'Int' , lazy_build => 1);

has 'jql' => ( is => 'ro', isa => 'Str', lazy_build => 1);
has 'fields' => ( is => 'ro', isa => 'ArrayRef[Str]', lazy_build => 1 );

# Objects
has 'jira' => ( is => 'ro', isa => 'JIRA::REST', lazy_build => 1);

has 'tt' => ( is => 'ro', isa => 'Template', lazy_build => 1);

sub _build_jira{
    my ($self) = @_;
    $log->info("Accessing JIRA At ".$self->url()." as '".$self->username()."' (+password)");
    return JIRA::REST->new( $self->url() , $self->username() , $self->password() );
}

sub _build_fields{
    my ($self) = @_;
    return $self->config()->{fields} // [ qw/key status summary assignee issuetype/ ];
}

sub _build_maxissues{
    my ($self) = @_;
    return $self->config()->{maxissues} // 100;
}

sub _build_url{
    my ($self) = @_;
    return $self->config()->{url} // die "Missing url ".$self->config_place()."\n";
}

sub _build_username{
    my ($self) = @_;
    return $self->config()->{username} // die "Missing username ".$self->config_place()."\n";
}

sub _build_password{
    my ($self) = @_;
    return $self->config()->{password} // die "Missing password ".$self->config_place()."\n";
}

sub _build_project{
    my ($self) = @_;
    return $self->config()->{project} // die "Missing project ".$self->config_place()."\n";
}

sub _build_sprint{
    my ($self) = @_;
    return $self->config()->{sprint} // die "Missing sprint ".$self->config_place()."\n";
}

sub _build_jql{
    my ($self) = @_;
    return $self->config()->{jql} //
        'project = "'.$self->project().'" and Sprint = "'.$self->sprint().'" ORDER BY status, assignee, created'
}

sub _build_template_file{
    my ($self) = @_;
    return $self->config()->{template_file} //
        File::Spec->catfile( $self->shared_directory() , 'std_tickets.tex.tt' );
}

sub config_place{
    my ($self) = @_;
    if( $self->has_config_files() && @{ $self->config_files() } ){
        return 'in config files: '.join(', ', @{$self->config_files()} );
    }
    return 'in memory config';
}

sub _build_config{
    my ($self) = @_;
    my $config = {};
    my $merge = Hash::Merge->new( 'RIGHT_PRECEDENT' );
    foreach my $config_file ( @{$self->config_files} ){
        $log->info("Loading $config_file");
        my $file_config =  do $config_file ;
        unless( $file_config ){
            $log->warn("Cannot read $config_file");
            $file_config = {};
        }
        $config = $merge->merge( $config, $file_config );
    }
    return $config;
}

sub _build_config_files{
    my ($self) = @_;
    my @candidates = (
        File::Spec->catfile( '/' , 'etc' , 'jiraprint.conf' ),
        File::Spec->catfile( $ENV{HOME} , '.jiraprint.conf' ),
        File::Spec->catfile( getcwd() , '.jiraprint.conf' ),
      );
    my @files = ();
    foreach my $candidate ( @candidates ){
        $log->debug("Looking for $candidate");
        if( -r $candidate ){
            $log->info("Found config file '$candidate'");
            push @files , $candidate;
        }
    }
    unless( @files ){
        $log->warn("Cannot find any config files amongst ".join(', ' , @candidates ).". Relying only on command line switches");
    }
    return \@files;
}

sub _build_shared_directory{
    my ($self) = @_;
    my $file_based_dir = File::Spec->rel2abs(__FILE__);
    $file_based_dir =~ s|lib/App/JIRAPrint.+||;
    $file_based_dir .= 'share/';
    if( -d $file_based_dir ){
        my $real_sharedir = Cwd::realpath($file_based_dir);
        unless( $real_sharedir ){
            confess("Could not build Cwd::realpath from '$file_based_dir'");
        }
        $real_sharedir .= '/';

        $log->debug("Will use file based shared directory '$real_sharedir'");
        return $real_sharedir;
    }

    my $dist_based_dir = Cwd::realpath(dist_dir('App-JIRAPrint'));

    my $real_sharedir = Cwd::realpath($dist_based_dir);
    unless( $real_sharedir ){
        confess("Could not build Cwd::realpath from '$dist_based_dir'");
    }

    $real_sharedir .= '/';

    $log->debug("Will use  directory ".$real_sharedir);
    return $real_sharedir;
}

sub _build_tt{
    my ($self) = @_;
    return Template->new({
        STRICT => 1,
        FILTERS => {
            tex => sub{
                my ($text) = @_;
                return LaTeX::Encode::latex_encode($text);
            }
        }
    });
}


=head2 process_template

Processes $this->template_file() with the $this->fetch_issues() and return a string

=cut

sub process_template{
    my ($self) = @_;
    my $stash = $self->fetch_issues();

    my $fio = IO::File->new($self->template_file(), "r");
    my $output = '';
    $self->tt()->process( $fio , $stash , \$output ) || die $self->tt()->error();
    return $output;
}

=head2 fetch_fields

Returns the list of available fiels at this (url, username, password, project)

Usage:

 my $fields = $this->fetch_fields();

=cut

sub fetch_fields{
    my ($self) = @_;
    return $self->jira->GET('/field');
}

=head2 fetch_issues

Fetches issues from JIRA Using this object properties (url, username, password, project, maxissues, fields)

Usage:

 my $issues = $this->fetch_issues();

=cut

sub fetch_issues{
    my ($self) = @_;
    my $issues = $self->jira()->POST('/search', undef , {
        jql => $self->jql(),
        startAt => 0,
        maxResults => $self->maxissues(),
        fields => $self->fields()
    });

    $log->debug(&{
        (sub{
             return "Issues ".( Data::Dumper->new([ $issues ])->Indent(1)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump );
         })
    }() ) if $log->is_debug();
    foreach my $issue ( @{$issues->{issues}} ){
        $issue->{url} = short_link($self->url().'/browse/'.$issue->{key});
    }
    return $issues;
}

1;
