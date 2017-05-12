package Arepa::Web::Public;

use strict;
use warnings;

use base 'Arepa::Web::Base';

use English qw(-no_match_vars);
use POSIX qw(strftime);
use File::stat;
use XML::RSS;
use Parse::Debian::PackageDesc;

use Arepa::PackageDb;

sub _retarded_escape {
    my ($self, $value) = @_;

    $value =~ s/&/&amp;/g;
    $value =~ s/</&lt;/g;
    $value =~ s/>/&gt;/g;
    return $value;
}

sub rss_queue {
    my ($self) = @_;

    my $rss = XML::RSS->new(version => '2.0');
    $rss->channel(
        title        => "Arepa upload queue",
        link         => "http://search.cpan.org/~opera/",
        description  => "Packages waiting to be approved for your Debian repository",
        dc => {
            date       => '2010-06-02T09:15+00:00',
            subject    => "Software distribution",
            creator    => 'estebanm@opera.com',
            language   => 'en-us',
        },
        syn => {
            updatePeriod     => "hourly",
            updateBase       => "1901-01-01T00:00+00:00",
        },
        taxo => [
            'http://dmoz.org/Computers/Software/Operating_Systems/Linux/Distributions/Debian/',
        ]
    );


    my @changes_files = ();
    if (opendir D, $self->config->get_key('upload_queue:path')) {
        @changes_files = grep /\.changes$/, readdir D;
        closedir D;
    }
    my @packages;
    my $gpg_dir = $self->config->get_key('web_ui:gpg_homedir');
    foreach my $changes_file (@changes_files) {
        my $changes_file_path = $self->config->get_key('upload_queue:path') .
                                    "/" . $changes_file;
        eval {
            push @packages,
                 Parse::Debian::PackageDesc->new($changes_file_path,
                                                 gpg_homedir => $gpg_dir);
        };
        if ($EVAL_ERROR) {
            print STDERR "Error reading changes file '$changes_file_path'\n";
            print STDERR $EVAL_ERROR, "\n";
        }
    }

    my $public_url;
    if ($self->config->key_exists('web_ui:cgi_base_url')) {
        $public_url = $self->config->get_key('web_ui:cgi_base_url');
    }
    if ($self->config->key_exists('web_ui:public_url')) {
        $public_url = $self->config->get_key('web_ui:public_url');
    }
    if (!defined $public_url) {
        die "Couldn't find configuration keys web_ui:public_url or web_ui:cgi_base_url";
    }

    foreach my $pkg (@packages) {
        my $signature_info = "";
        if ($pkg->signature_id) {
            $signature_info = "It is signed with id " .
                                $pkg->signature_id . ".";
            if (! $pkg->correct_signature) {
                $signature_info .= " The signature is <strong>NOT " .
                                    "VALID</strong>";
            }
        }
        else {
            $signature_info = "It is <strong>NOT SIGNED</strong>.";
        }

        $rss->add_item(
            title       => $pkg->name . " " . $pkg->version . " for " .
                            $pkg->distribution,
            link        => $public_url,
            description => $pkg->name . " " . $pkg->version .
                            " was uploaded by " .
                            $self->_retarded_escape($pkg->maintainer) .
                            ".<br/>" . $signature_info,
            pubDate     => strftime("%a, %d %b %Y %H:%M:%S %z",
                                    localtime(stat($pkg->path)->mtime)),
        );
    }

    $self->render_text($rss->as_string);
}

sub rss_repository {
    my ($self) = @_;

    my $rss = XML::RSS->new(version => '2.0');
    $rss->channel(
        title        => "Arepa latest packages",
        link         => "http://search.cpan.org/~opera/",
        description  => "Latest packages added to the repository",
        dc => {
            date       => '2012-01-27T16:20+00:00',
            subject    => "Software distribution",
            creator    => 'estebanm@opera.com',
            language   => 'en-us',
        },
        syn => {
            updatePeriod     => "hourly",
            updateBase       => "1901-01-01T00:00+00:00",
        },
        taxo => [
            'http://dmoz.org/Computers/Software/Operating_Systems/Linux/Distributions/Debian/',
        ]
    );


    my $packagedb =
            Arepa::PackageDb->new($self->config->get_key('package_db'));
    my @packages = ();
    my @compilation_queue = $packagedb->
                        get_compilation_queue(status => 'compiled',
                                              order  => "compilation_completed_at DESC",
                                              limit  => 30);
    foreach my $comp (@compilation_queue) {
        my %source_pkg_attrs =
            $packagedb->get_source_package_by_id($comp->{source_package_id});
        push @packages, {
            %$comp,
            package => { %source_pkg_attrs },
        };
    }

    my $public_url;
    if ($self->config->key_exists('web_ui:cgi_base_url')) {
        $public_url = $self->config->get_key('web_ui:cgi_base_url');
    }
    if ($self->config->key_exists('web_ui:public_url')) {
        $public_url = $self->config->get_key('web_ui:public_url');
    }
    if (!defined $public_url) {
        die "Couldn't find configuration keys web_ui:public_url or web_ui:cgi_base_url";
    }

    foreach my $pkg (@packages) {
        $rss->add_item(
            title       => $pkg->{package}->{name} . " " . $pkg->{package}->{full_version} . " (" .
                            $pkg->{distribution} . "/" . $pkg->{architecture} . ")",
            link        => $public_url,
            description => $pkg->{package}->{name} . " " . $pkg->{package}->{full_version} .
                            "<br/>" .
                            $pkg->{package}->{comments},
            pubDate     => $pkg->{completed_at},
        );
    }

    $self->render_text($rss->as_string);
}

1;
